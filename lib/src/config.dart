import 'dart:convert';

import 'package:flutter/services.dart';

class Configuration {
  Configuration._privateConstructor();
  static final Configuration instance = Configuration._privateConstructor();

  factory Configuration() {
    return instance;
  }

  Map<String, dynamic> conf = new Map();

  void appendConfigs(Map<String, dynamic> otherConf, {String environment}) {
    conf.addAll(otherConf);
  }

  Future<void> appendAsset(String asset, {String environment}) async {
    String data = await rootBundle.loadString(asset);
    var jsonResult = json.decode(data);
    conf.addAll(jsonResult);
  }
}
