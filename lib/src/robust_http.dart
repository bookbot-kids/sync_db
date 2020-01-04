import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';

/// Here are the excptions that are ready to go in public facing modal if needs me
class UnknownException implements Exception {
  String devDescription;
  UnknownException(this.devDescription);
  String toString() => Intl.message("We're unsure what happened, but we're looking into it.", name: 'unknownException');
}

class ConnectivityException implements Exception {
  String toString() => Intl.message('You are not connected to the internet at this time.', name: 'notConnected');
}

class RetryFailureException implements Exception {
  String toString() => Intl.message('There is a problem with the internet connection, please retry later.', name: 'retryFailure');
}

class UnexpectedResponseException implements Exception {
  String toString() => Intl.message('There is an unexpected issue. Please try again later.', name: 'unexpectedResponseFailure');
}

class HTTP {
  static String baseUrl = 'https://www.google.com';
  static int connectTimeout = 10000;
  static int receiveTimeout = 10000;
  static int httpRetries = 3;

  /// Does a http GET (with optional overrides).
  /// You can pass the full url, or the path after the baseUrl.
  /// Will timeout, check connectivity and retry until there is a response
  static Future<Response> get(String url, [String baseUrl, int connectTimeout, int receiveTimeout, int httpRetries]) async {
    // Use Dio with properties from function or class
    BaseOptions options = new BaseOptions(
      baseUrl: baseUrl ?? HTTP.baseUrl,
      connectTimeout: connectTimeout ?? HTTP.connectTimeout,
      receiveTimeout: receiveTimeout ?? HTTP.receiveTimeout,
    );

    Dio dio = new Dio(options);


    // Make call, and manage the many network problems that can happen.
    // Will only throw an exception when it's sure that there is no internet connection, exhausts its retries or gets an unexpected server response
    for (var i = 1; i <= httpRetries ?? HTTP.httpRetries; i++) {
      // dio.get(url).then((){
      //   return
      // }).catchError(onError)

      try {
        return await dio.get(url);
      } catch(error) {
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
  }
}
