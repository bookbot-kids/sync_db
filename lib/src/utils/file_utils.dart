import 'package:universal_io/io.dart';

class FileUtils {
  /// rename or move file https://stackoverflow.com/a/55614133/719212
  static Future<File> moveFile(String sourcePath, String newPath) async {
    final sourceFile = File(sourcePath);
    try {
      // prefer using rename as it is probably faster
      return await sourceFile.rename(newPath);
    } on FileSystemException catch (e) {
      // if rename fails, copy the source file and then delete it
      final newFile = await sourceFile.copy(newPath);
      await sourceFile.delete();
      return newFile;
    }
  }
}
