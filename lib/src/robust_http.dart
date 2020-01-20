import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';
import 'exceptions.dart';

class HTTP {
  String baseUrl = 'https://www.google.com';
  int connectTimeout = 10000;
  int receiveTimeout = 10000;
  int httpRetries = 3;
  Dio dio;

  /// Configure HTTP with defaults from a Map
  HTTP(String baseUrl, [Map<String, dynamic> map = const {}]) {
    this.baseUrl = baseUrl ?? map["baseUrl"] ?? this.baseUrl;
    connectTimeout = map["connectTimeout"] ?? connectTimeout;
    receiveTimeout = map["receiveTimeout"] ?? receiveTimeout;
    httpRetries = map["httpRetries"] ?? httpRetries;

    dio = new Dio(_baseOptions());
  }

  /// Does a http GET (with optional overrides).
  /// You can pass the full url, or the path after the baseUrl.
  /// Will timeout, check connectivity and retry until there is a response.
  /// Will handle most success or failure cases and will respond with either data or exception.
  Future<dynamic> get(String url, {Map<String, dynamic> parameters}) async {
    return request("GET", url, parameters: parameters);
  }

  /// Does a http POST (with optional overrides).
  /// You can pass the full url, or the path after the baseUrl.
  /// Will timeout, check connectivity and retry until there is a response.
  /// Will handle most success or failure cases and will respond with either data or exception.
  Future<dynamic> post(String url, {Map<String, dynamic> parameters}) async {
    return request("POST", url, parameters: parameters);
  }

  Future<dynamic> request(String method, String url, {Map<String, dynamic> parameters}) async {
    dio.options.method = method;

    // Make call, and manage the many network problems that can happen.
    // Will only throw an exception when it's sure that there is no internet connection,
    // exhausts its retries or gets an unexpected server response
    for (var i = 1; i <= (httpRetries ?? this.httpRetries); i++) {
      try {
        return (await dio.request(url, queryParameters: parameters)).data;
      } catch(error) {
        await _handleException(error);
      }
    }
    // Exhausted retries, so send back exception
    throw RetryFailureException();
  }

  /// Create Dio BaseOptions from an options Map
  BaseOptions _baseOptions() {
    return new BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  /// Handle exceptions that come from various failures
  void _handleException(dynamic error) async {
    if (error.type == DioErrorType.CONNECT_TIMEOUT || error.type == DioErrorType.RECEIVE_TIMEOUT) {
      if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
        throw ConnectivityException();
      }
    } else if (error.type == DioErrorType.RESPONSE) {
      throw UnexpectedResponseException();
    } else {
      print(error.toString());
      throw UnknownException(error.message);
    } 
  }
}
