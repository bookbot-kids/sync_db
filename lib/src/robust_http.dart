import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';
import 'exceptions.dart';

class HTTP {
  static String baseUrl = 'https://www.google.com';
  static int connectTimeout = 10000;
  static int receiveTimeout = 10000;
  static int httpRetries = 3;

  /// Does a http GET (with optional overrides).
  /// You can pass the full url, or the path after the baseUrl.
  /// Will timeout, check connectivity and retry until there is a response.
  /// Will handle most success or failure cases and will respond with either data or exception.
  static Future<dynamic> get(String url, {Map<String, dynamic> parameters, Map<String, dynamic> options = const {}}) async {
    return HTTP.request("GET", url, parameters: parameters, options: options);
  }

  /// Does a http POST (with optional overrides).
  /// You can pass the full url, or the path after the baseUrl.
  /// Will timeout, check connectivity and retry until there is a response.
  /// Will handle most success or failure cases and will respond with either data or exception.
  static Future<dynamic> post(String url, {Map<String, dynamic> parameters, Map<String, dynamic> options = const {}}) async {
    return HTTP.request("POST", url, parameters: parameters, options: options);
  }

  static Future<dynamic> request(String method, String url, {Map<String, dynamic> parameters, Map<String, dynamic> options = const {}}) async {
    BaseOptions baseOptions = HTTP._baseOptions(options);
    baseOptions.method = method;
    Dio dio = new Dio(baseOptions);

    // Make call, and manage the many network problems that can happen.
    // Will only throw an exception when it's sure that there is no internet connection,
    // exhausts its retries or gets an unexpected server response
    for (var i = 1; i <= (httpRetries ?? HTTP.httpRetries); i++) {
      try {
        return (await dio.request(url, queryParameters: parameters)).data;
      } catch(error) {
        await HTTP._handleException(error);
      }
    }
    // Exhausted retries, so send back exception
    throw RetryFailureException();
  }

  /// Create Dio BaseOptions from an options Map
  static BaseOptions _baseOptions(Map<String, dynamic> options) {
    return new BaseOptions(
      baseUrl: options["baseUrl"] ?? HTTP.baseUrl,
      connectTimeout: options["connectTimeout"] ?? HTTP.connectTimeout,
      receiveTimeout: options["receiveTimeout"] ?? HTTP.receiveTimeout,
    );
  }

  /// Handle exceptions that come from various failures
  static _handleException(dynamic error) async {
    if (error.type == DioErrorType.CONNECT_TIMEOUT || error.type == DioErrorType.RECEIVE_TIMEOUT) {
      if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
        throw ConnectivityException();
      }
    } else if (error.type == DioErrorType.RESPONSE) {
      throw UnexpectedResponseException();
    } else {
      throw UnknownException(error.message);
    } 
  }
}
