import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';

/// await HTTP.get('/path').then((Response response) {
/// 
/// }, onError: (error) {
/// 
/// });

abstract class Config {
  static String baseUrl;
  static int connectTimeout;
  static int receiveTimeout;
  static int httpRetries;
}

class UnknownException implements Exception {
  String devDescription;
  UnknownException(this.devDescription);
  String toString() => Intl.message("We're unsure what happened, but we're looking into it.", name: 'unknownException');
}

class ConnectivityException implements Exception {
  String toString() => Intl.message('You are not connected to the internet at this time.', name: 'notConnected');
}

class RetryFailureException implements Exception {
  String toString() => Intl.message('There is a problem with the internet connection, pleasse retry later.', name: 'retryFailure');
}

class UnexpectedResponseException implements Exception {
  String toString() => Intl.message('There is an unexpected issue. Please try again later.', name: 'unexpectedResponseFailure');
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
  static Future<Response> get(String url, [BaseOptions options]) async {
    // Normalise the url
    if (!(url.startsWith('http://') || url.startsWith('https://'))) {
      String baseUrl = options.baseUrl ?? HTTP.options.baseUrl;
      url = baseUrl + url;
    }

    // Use the Dio with properties from Config or BaseOptions that are passed in
    Dio localDio = (options != null) ? new Dio(options) : HTTP.dio;

    // Make call, and manage the many network problems that can happen.
    // Will only throw an exception when it's sure that there is no internet connection, exhausts its retries or gets an unexpected server response
    for (var i = 1; i <= Config.httpRetries ?? 3; i++) {
      try {
        return await localDio.get(url);
      } on DioError catch(error) {
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
    // Exhausted retries, so send back exception
    throw RetryFailureException();

    // if error in response code - return with error - UNEXPECTED RESPONSE error type
    // Other error - return with error, pass error
  }
}
