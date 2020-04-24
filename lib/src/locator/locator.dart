import 'sembast_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'sembast_web.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'sembast_mobile.dart';

abstract class Locator {
  factory Locator() => getLocator();
}
