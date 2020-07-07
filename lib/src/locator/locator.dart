import 'sembast_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'sembast_web.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'sembast_mobile.dart';

/// The abtract interface to get Locator instance.
/// It will return `SembastWebLocator` if it's web platform by checking `if (dart.library.html) 'sembast_web.dart'`
/// Otherwise return `SembastMobileLocator`
/// Read more about Conditionally importing https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files
abstract class Locator {
  factory Locator() => getLocator();
}
