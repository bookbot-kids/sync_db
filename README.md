# Sync_db
- A library to sync data between cloud (azure cosmos, aws appsync) and local database
- Support for offline cache
- Can retry when error

## Usage

A simple usage example:
- Import dependency in `pubspec.yaml`
```
dependencies:
  sync_db:
    git:
        url: git://github.com/bookbot-kids/sync_db.git
```

```dart
import 'package:sync_db/sync_db.dart';

main() {
  var sync = Sync.shared.config();
}
```

## Sync model code generator usage
- Import following dev_dependencies in `pubspec.yaml`
```
dev_dependencies:
  build_runner:
```

- Add `build.yaml` file into root project folder
```
# Read about `build.yaml` at https://pub.dev/packages/build_config
targets:
    $default:
      builders:
        # Configure the builder `pkg_name|builder_name`
        sync_db|model_builer:
          # Only run this builder on models folder
          generate_for:
            - lib/models/*.dart
        source_gen|combining_builder:
          options:
            ignore_for_file:
            - lint_a

```

- Add model classes in `lib/models` folder. E.g
```
// test_model.dart

import 'package:sync_db/sync_db.dart';
part 'test_model.g.dart'; // mark sure this generated file name is correct

class TextModel extends Model {
  String id;
  bool isChecked;
  int count;
}
```

- Run command `flutter packages pub run build_runner build` in root project folder
- Check the generates files `.g.dart` in `models`. The result is something like this:
```
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: lint_a

part of 'test_model.dart';

// **************************************************************************
// ModelGenerator
// **************************************************************************

// TextModel model generation
class $TextModel extends TextModel {
  @override
  Map<String, dynamic> get map => <String, dynamic>{
        'id': id,
        'isChecked': isChecked,
        'count': count,
      };

  @override
  set map(Map<String, dynamic> map) {
    id = map['id'];
    isChecked = map['isChecked'];
    count = map['count'];
  }

  @override
  String toString() => 'TextModel';
}

```
- Read [here](https://pub.dev/packages/source_gen) for more information