import 'package:logger/logger.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AzureLogOutput extends LogOutput {
  final ConsoleOutput consoleOutput = ConsoleOutput();
  static const String _apiVersion = "2016-04-01";
  HTTP http;
  String sharedKey;
  String customerId;
  String logName;
  String url;
  AzureLogOutput(this.sharedKey, this.customerId, this.logName) {
    url = "https://" +
        customerId +
        ".ods.opinsights.azure.com/api/logs?api-version=2016-04-01";
  }

  @override
  void output(OutputEvent event) {
    consoleOutput.output(event);
    _sendLogToMonitor(null).then((value) => null);
  }

  String _buildSignature(String message, String secret) {
    var keyByte = ascii.encode(secret);
    var base64Str = base64.encode(keyByte);
    keyByte = ascii.encode(base64Str);
    var messageBytes = ascii.encode(message);
    var hmacSha256 = new Hmac(sha256, keyByte);
    var hash = hmacSha256.convert(messageBytes);
    return base64.encode(hash.bytes);
  }

  Future<void> _sendLogToMonitor(Map data) async {
    var now = HttpDate.format(await NetworkTime.shared.now);
    String jsonData = json.encode(data);
    var jsonBytes = utf8.encode(jsonData);
    String stringToHash = "POST\n" +
        jsonBytes.length.toString() +
        "\napplication/json\n" +
        "x-ms-date:" +
        now +
        "\n/api/logs";
    String hashedString = _buildSignature(stringToHash, sharedKey);
    String signature = "SharedKey " + customerId + ":" + hashedString;

    http.headers = {
      "x-ms-date": now,
      "authorization": signature,
      "content-type": "application/json",
      "accept": "application/json",
      "x-ms-version": _apiVersion,
      "time-generated-field": "",
      "log-type": logName
    };

    await http.post(url);
  }
}
