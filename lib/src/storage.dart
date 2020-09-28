import 'dart:io';

import 'package:sync_db/sync_db.dart';
import 'package:pool/pool.dart';

abstract class Storage {
  // Make sure there are no more than 8 uploads/downloads at the same time
  final _pool = Pool(8);

  Future<void> upload(List<Paths> paths) async {
    // Persist record
    // call write to storage
    // Upload
    // Delete record
  }

  Future<void> download(List<Paths> paths) async {
    // Persist record
    // call read from storage
    // Download
    // Delete record
  }

  /// Read file from cloud storage and save to file that is passed
  Future<void> readFromStorage(String storagePath, File file);

  /// Write file to cloud storage from file
  Future<void> writeToStorage(File file, String storagePath);
}

class Paths {
  Paths({this.localPath, this.storagePath, this.url});
  String localPath;
  String storagePath;
  String url;
}
