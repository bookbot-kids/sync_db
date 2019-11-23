import 'package:dio/dio.dart';

/// await HTTP.get('/path').then((Response response) {
/// 
/// }, onError: (error) {
/// 
/// });

abstract class Config {
  static String baseUrl;
  static int connectTimeout;
  static int receiveTimeout;
}

class HTTP {
  // Get http default options from the Config class
  static BaseOptions options = new BaseOptions(
    baseUrl: Config.baseUrl,
    connectTimeout: Config.connectTimeout,
    receiveTimeout: Config.receiveTimeout,
  );
  static Dio dio = new Dio(options);

  /// Will do a http GET (with optional Dio BaseOptions overrides).
  /// You can pass the full url, or the path after the baseUrl.
  /// Will timeout, check connecctivity and retry until there is a response
  static Future<Response> get(String url, [BaseOptions options]) {
    /// return if success
    /// if timeout check connectivity
    /// if connected try again
    /// if not connected return error with connectivity problem
    
    // Normalise the url
    if (!(url.startsWith('http://') || url.startsWith('https://'))) {
      String baseUrl = options.baseUrl ?? HTTP.options.baseUrl;
      url = baseUrl + url;
    }

    // Use the Dio with properties from Config or BaseOptions that are passed in
    Dio localDio = (options != null) ? new Dio(options) : HTTP.dio;

    localDio.get(url);
  }
}