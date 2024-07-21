import 'package:robust_http/connection_helper.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/src/utils/file_utils.dart';
import 'package:sync_db/sync_db.dart';
import 'package:pool/pool.dart';
import 'package:universal_io/io.dart';

class Storage {
  Storage(Map config) {
    _config = config;
    // Timeout is tuned for small files, set another timeout if larger files are transferred
    _transferTimeout = config['transferTimeout'] ?? 30;
    // Transfer pool size also assumes small files. Make smaller (8) if files are large
    _pool = Pool(config['storagePoolSize'] ?? 64);
    _http = HTTP(null, config as Map<String, dynamic>);
    // start retry time in minute
    _initRetryTime = config['initRetryTime'] ?? 1;
    _retryPool = Pool(config['retryPoolSize'] ?? 8);
    _delayedPool = Pool(config['delayPoolSize'] ?? 8);
    _retryWhenNotFound = config['retryWhenNotFound'] ?? true;
    proxyUrl = config['proxyUrl'] ?? '';
    enableFileProxy = config['enableFileProxy'] ?? false;
  }

  late var _pool;
  var _retryPool = Pool(8);
  late var _transferTimeout;
  late HTTP _http;
  var _delayedPool = Pool(8);
  var _initRetryTime = 1;
  late Map _config;
  var proxyUrl = '';
  var enableFileProxy = false;
  Map<String, Paths> Function(Model model, String tableName)? pathDelegate;

  /// Whether to retry when the path is 404
  var _retryWhenNotFound = true;

  ///
  /// Manage all file in memory to prevent re-download.
  ///
  final _transferrings = <String?, TransferMap>{};

  // Each error transfer has its own delay time, and increase everytime retry
  final Map<String?, int> _retryDelayedMap = {};

  Map get config => _config;

  Future<void> upload(List<Paths> paths, {bool retry = false}) async {
    await transfer(paths, TransferStatus.uploading, retry: retry);
  }

  Future<void> download(List<Paths> paths, {bool retry = false}) async {
    await transfer(paths, TransferStatus.downloading, retry: retry);
  }

  Future<void> transfer(List<Paths> paths, TransferStatus status,
      {retry = false}) async {
    var futures = <Future>[];
    final transferMaps = await TransferMap().all();
    transferMaps.forEach((element) {
      _transferrings[element.localPath] = element;
    });

    for (final path in paths) {
      // Check if already in transfer
      var existing = _transferrings[path.localPath];
      existing ??= _transferrings[path.localPath + '~'];
      if (existing != null) {
        final now = await NetworkTime.shared.now;
        final past = now.subtract(Duration(seconds: _transferTimeout));
        // Has not timed out so skip
        if (existing.createdAt!.isAfter(past)) {
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
              transfer.localPath!.substring(0, transfer.localPath!.length - 1);
          final localFile = File(transfer.localPath!);
          if (await localFile.exists()) {
            await FileUtils.moveFile(transfer.localPath!, finalPath);
          }
        }
        await transfer.deleteLocal();
        _transferrings.remove(transfer.localPath);
        _retryDelayedMap.remove(transfer.id);
      } catch (e, stackTrace) {
        // don't log error again on retry
        if (!isRetrying) {
          if (await ConnectionHelper.shared.hasInternetConnection()) {
            if (e is UnexpectedResponseException) {
              Sync.shared.logger?.e(
                  ' Storage ${transfer.transferStatus == TransferStatus.uploading ? 'upload' : 'dowload'} error at ${e.url} [${e.statusCode}] ${e.errorMessage}',
                  error: e,
                  stackTrace: stackTrace);
            } else if (e is UnknownException) {
              Sync.shared.logger?.e(
                  ' Storage ${transfer.transferStatus == TransferStatus.uploading ? 'upload' : 'dowload'} error ${e.devDescription}',
                  error: e,
                  stackTrace: stackTrace);
            } else {
              Sync.shared.logger?.e(
                  'Storage ${transfer.transferStatus == TransferStatus.uploading ? 'upload' : 'dowload'} error $e',
                  error: e,
                  stackTrace: stackTrace);
            }
          }
        }

        final isNotFoundError = e is FileNotFoundException ||
            (e is UnexpectedResponseException && e.statusCode == 404);

        if ((isNotFoundError && !_retryWhenNotFound) || !retry) {
          return Future.error(e, stackTrace);
        }

        // retry if there is error
        if (await ConnectionHelper.shared.hasInternetConnection()) {
          _retryDelayedMap.putIfAbsent(transfer.id, () => _initRetryTime);
          // ignore: unawaited_futures
          _delayedPool.withResource(() async => await Future.delayed(
                      Duration(minutes: _retryDelayedMap[transfer.id]!))
                  .then((value) {
                Sync.shared.logger?.i('Retry transfer $transfer');
                _transfer(transfer, isRetrying: true, retry: true);
                if (_retryDelayedMap[transfer.id] == null) {
                  _retryDelayedMap[transfer.id] = _initRetryTime;
                }
                // increase time on the next retry
                if (isNotFoundError) {
                  _retryDelayedMap[transfer.id] =
                      (_retryDelayedMap[transfer.id] ?? 1) * 5;
                } else {
                  _retryDelayedMap[transfer.id] =
                      (_retryDelayedMap[transfer.id] ?? 1) * 2;
                }
              }));
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
    TransferMap().all().then((transfers) async {
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
      await _http.download(transferMap.remoteUrl!,
          localPath: transferMap.localPath);
    } catch (e) {
      rethrow;
    }
  }

  /// Write file to cloud storage from file
  Future<void> writeToRemote(TransferMap transferMap) async {}

  Uri buildProxyUri(Uri uri) {
    if (enableFileProxy && proxyUrl.isNotEmpty) {
      final proxyUri = Uri.parse('$proxyUrl/${uri.toString()}');
      Sync.shared.logger?.i('Request with proxy url ${proxyUri.toString()}');
      return proxyUri;
    }

    return uri;
  }
}

class FileNotFoundException implements Exception {
  final String msg;
  const FileNotFoundException(this.msg);
  @override
  String toString() => '$msg';
}
