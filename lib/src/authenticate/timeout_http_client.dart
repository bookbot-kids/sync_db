import 'dart:async';

import 'package:http/http.dart' as http;

/// An HTTP client that gives up on a request after [timeout].
///
/// The timeout covers the whole request, reading the body included: a server
/// (or captive portal) that answers the headers and then stalls is as stuck
/// as one that never answers. The body is read here and handed on as a
/// finished stream.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient(this.timeout, {http.Client? inner})
      : _inner = inner ?? http.Client();

  final Duration timeout;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _sendAndRead(request).timeout(timeout);

  Future<http.StreamedResponse> _sendAndRead(http.BaseRequest request) async {
    final response = await _inner.send(request);
    final bytes = await response.stream.toBytes();
    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
