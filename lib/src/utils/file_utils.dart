import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class FileUtils {
  /// rename or move file https://stackoverflow.com/a/55614133/719212
  static Future<File?> moveFile(String sourcePath, String newPath) async {
    final sourceFile = File(sourcePath);
    final targetFile = File(newPath);
    try {
      // prefer using rename as it is probably faster
      return sourceFile.renameSync(newPath);
    } on FileSystemException {
      // if rename fails, copy the source file and then delete it
      File? newFile;
      try {
        if (targetFile.existsSync()) {
          targetFile.deleteSync(recursive: true);
        }
        newFile = sourceFile.copySync(newPath);
        sourceFile.deleteSync();
      } catch (e, stacktrace) {
        Sync.shared.logger?.e('Error moving file $sourcePath to $newPath',
            error: e, stackTrace: stacktrace);
      }

      return newFile;
    }
  }
}
