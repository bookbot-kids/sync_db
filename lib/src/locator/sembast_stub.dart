import 'package:sync_db/src/locator/sembast_base.dart';

/// It should not going to here unless there is a platform that doesn't support both io & web framework
SembastLocator getLocator() =>
    throw UnsupportedError('Cannot create an abstract Locator!');
