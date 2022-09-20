library sync_db.builder;

import 'package:source_gen/source_gen.dart';
import 'package:sync_db/src/generator/model_2_generator.dart';
import 'package:sync_db/src/generator/model_generator.dart';
import 'package:build/build.dart';

Builder modelLibraryBuilder(BuilderOptions options) =>
    SharedPartBuilder([ModelGenerator()], 'model');

Builder model2LibraryBuilder(BuilderOptions options) =>
    SharedPartBuilder([Model2Generator()], 'model2');
