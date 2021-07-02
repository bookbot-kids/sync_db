import 'package:connectivity/connectivity.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/src/utils/file_utils.dart';
import 'package:sync_db/sync_db.dart';
import 'package:pool/pool.dart';
import 'package:universal_io/io.dart';
import 'package:universal_platform/universal_platform.dart';

class Storage {
  Storage(Map config) {
    _config = config;
    // Timeout is tuned for small files, set another timeout if larger files are transferred
    _transferTimeout = config['transferTimeout'] ?? 30;
    // Transfer pool size also assumes small files. Make smaller (8) if files are large
    _pool = Pool(config['storagePoolSize'] ?? 64);
    _http = HTTP(null, config);
    // start retry time in minute
    _initRetryTime = config['initRetryTime'] ?? 1;
    _retryPool = Pool(config['retryPoolSize'] ?? 8);
    _delayedPool = Pool(config['delayPoolSize'] ?? 8);
  }

  var _pool;
  var _retryPool = Pool(8);
  var _transferTimeout;
  HTTP _http;
  var _delayedPool = Pool(8);
  var _initRetryTime = 1;
  Map _config;

  ///
  /// Manage all file in memory to prevent re-download.
  ///
  final _transferrings = <String, TransferMap>{};

  // Each error transfer has its own delay time, and increase everytime retry
  final Map<String, int> _retryDelayedMap = {};

  Future<void> upload(List<Paths> paths, {bool retry = false}) async {
    await transfer(paths, TransferStatus.uploading, retry: retry);
  }

  Future<void> download(List<Paths> paths, {bool retry = false}) async {
    await transfer(paths, TransferStatus.downloading, retry: retry);
  }

  Future<void> transfer(List<Paths> paths, TransferStatus status,
      {retry = false}) async {
    var futures = <Future>[];
    final transferMaps = await TransferMap.all();
    transferMaps.forEach((element) {
      _transferrings[element.localPath] = element;
    });

    for (final path in paths) {
      // Check if already in transfer
      var existing = _transferrings[path.localPath] ??=
          _transferrings[path.localPath + '~'];
      if (existing != null) {
        final now = await NetworkTime.shared.now;
        final past = now.subtract(Duration(seconds: _transferTimeout));
        // Has not timed out so skip
        if (existing.createdAt.isAfter(past)) {
          continue;
        }
      }

      // Put in temporary file path if downloading
      if (status == TransferStatus.downloading) {
        path.localPath = path.localPath + '~';
      }

      final transfer = TransferMap(paths: path, transferStatus: status);
      await transfer.save(syncToService: false);
      _transferrings[path.localPath] = transfer;

      futures.add(_transfer(transfer, retry: retry));
    }

    await Future.wait(futures);
  }

  Future _transfer(TransferMap transfer,
      {bool retry = false, bool isRetrying = false}) {
    if (isRetrying && _retryPool.isClosed) {
      return Future.delayed(Duration(milliseconds: 500));
    }

    return (isRetrying ? _retryPool : _pool).withResource(() async {
      try {
        _retryDelayedMap.putIfAbsent(transfer.id, () => _initRetryTime);
        if (transfer.transferStatus == TransferStatus.uploading) {
          await writeToRemote(transfer);
        } else {
          await readFromRemote(transfer);

          // Move file from temporary path
          final finalPath =
              transfer.localPath.substring(0, transfer.localPath.length - 1);
          final localFile = File(transfer.localPath);
          if (await localFile.exists()) {
            await FileUtils.moveFile(transfer.localPath, finalPath);
          }
        }
        await transfer.database.deleteLocal(transfer.tableName, transfer.id);
        _transferrings.remove(transfer.localPath);
        _retryDelayedMap.remove(transfer.id);
      } catch (e, stackTrace) {
        // don't log error again on retry
        if (!isRetrying) {
          if (e is UnexpectedResponseException) {
            Sync.shared.logger?.e(
                ' Storage ${transfer.transferStatus == TransferStatus.uploading ? 'upload' : 'dowload'} error at ${e.url} [${e.statusCode}] ${e.errorMessage}',
                e,
                stackTrace);
          } else if (e is UnknownException) {
            Sync.shared.logger?.e(
                ' Storage ${transfer.transferStatus == TransferStatus.uploading ? 'upload' : 'dowload'} error ${e.devDescription}',
                e,
                stackTrace);
          } else {
            Sync.shared.logger?.e(
                'Storage ${transfer.transferStatus == TransferStatus.uploading ? 'upload' : 'dowload'} error $e',
                e,
                stackTrace);
          }
        }

        if (retry) {
          // retry if there is error
          if (UniversalPlatform.isWindows ||
              await Connectivity().checkConnectivity() !=
                  ConnectivityResult.none) {
            // ignore: unawaited_futures
            _delayedPool.withResource(() async => await Future.delayed(
                        Duration(minutes: _retryDelayedMap[transfer.id]))
                    .then((value) {
                  Sync.shared.logger?.i('Retry transfer $transfer');
                  _transfer(transfer, isRetrying: true, retry: true);
                  // increase time on the next retry
                  if (e is FileNotFoundException) {
                    _retryDelayedMap[transfer.id] *= 5;
                  } else {
                    _retryDelayedMap[transfer.id] *= 2;
                  }
                }));
          }
        } else {
          rethrow;
        }
      }
    });
  }

  void resetRetryPool() {
    try {
      if (!_delayedPool.isClosed) {
        _delayedPool.close();
      }
    } catch (e) {
      //ignore
      Sync.shared.logger?.i('Can not close delayedPool $e');
    }

    try {
      if (!_retryPool.isClosed) {
        _retryPool.close();
      }
    } catch (e) {
      //ignore
      Sync.shared.logger?.i('Can not close retryPool $e');
    }

    _retryPool = Pool(_config['retryPoolSize'] ?? 8);
    _delayedPool = Pool(_config['delayPoolSize'] ?? 8);
  }

  void finishUnfinishedTransfers() {
    TransferMap.all().then((transfers) async {
      // final now = await NetworkTime.shared.now;
      // final past = now.subtract(Duration(seconds: _transferTimeout));

      for (final transfer in transfers) {
        // if (transfer.createdAt.isBefore(past)) {
        // ignore: unawaited_futures
        _transfer(transfer);
        // }
      }
    });
  }

  /// Read file from cloud storage and save to file that is passed
  Future<void> readFromRemote(TransferMap transferMap) async {
    // Implementation of dio download and stream write
    try {
      await _http.download(transferMap.remoteUrl,
          localPath: transferMap.localPath);
    } catch (e) {
      rethrow;
    }
  }

  /// Write file to cloud storage from file
  Future<void> writeToRemote(TransferMap transferMap) async {}
}

class Paths {
  Paths({
    this.localPath,
    this.assetPath,
    this.remotePath,
    this.remoteUrl,
    this.ondemandPath,
  });
  String localPath;
  String assetPath;
  String remotePath;
  String remoteUrl;
  String ondemandPath;

  @override
  String toString() {
    return 'localPath = $localPath\nassetPath = $assetPath remotePath = $remotePath\nremoteUrl = $remoteUrl\nondemandPath = $ondemandPath';
  }
}

class TransferMap extends Model {
  TransferMap({Paths paths, this.transferStatus}) {
    localPath = paths?.localPath;
    remotePath = paths?.remotePath;
    remoteUrl = paths?.remoteUrl;
  }

  String localPath;
  String remotePath;
  String remoteUrl;
  TransferStatus transferStatus;

  @override
  String get tableName => 'TransferMap';

  @override
  SyncPermission get syncPermission => SyncPermission.read;

  @override
  Map<String, dynamic> get map {
    var map = super.map;
    map['localPath'] = localPath;
    map['remotePath'] = remotePath;
    map['remoteUrl'] = remoteUrl;
    map['transferStatus'] = transferStatus.name;

    return map;
  }

  @override
  Future<void> setMap(Map<String, dynamic> map) async {
    await super.setMap(map);
    localPath = map['localPath'];
    remotePath = map['remotePath'];
    remoteUrl = map['remoteUrl'];
    transferStatus = $TransferStatus.fromString(map['transferStatus']);
  }

  static Future<List<TransferMap>> all() async {
    var all = await TransferMap().database.all('TransferMap', () {
      return TransferMap();
    });

    return List<TransferMap>.from(all);
  }

  static Future<TransferMap> find(String id) async =>
      await TransferMap().database.find('TransferMap', id, TransferMap());

  static Query where(dynamic condition) {
    return Query('TransferMap').where(condition, TransferMap().database, () {
      return TransferMap();
    });
  }
}

enum TransferStatus { uploading, downloading }

extension $TransferStatus on TransferStatus {
  static final string = {
    TransferStatus.uploading: 'uploading',
    TransferStatus.downloading: 'downloading'
  };

  static final toEnum = {
    'uploading': TransferStatus.uploading,
    'downloading': TransferStatus.downloading
  };

  String get name => $TransferStatus.string[this];
  static TransferStatus fromString(String value) =>
      $TransferStatus.toEnum[value];
}

class FileNotFoundException implements Exception {
  final String msg;
  const FileNotFoundException(this.msg);
  @override
  String toString() => '$msg';
}
