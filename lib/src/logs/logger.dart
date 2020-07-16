import 'package:logger/logger.dart';
import 'package:sync_db/src/logs/azure_log.dart';

class AppLogger {
  AppLogger._privateConstructor();
  static AppLogger shared = AppLogger._privateConstructor();
  Logger logger;
  static void init(Map config) {
    AppLogger.shared.logger = Logger(
      filter: null,
      printer: PrettyPrinter(),
      output: AzureLogOutput(config['azureSharedKey'], config[''], config['']),
    );
  }
}
