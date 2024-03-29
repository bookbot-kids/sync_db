class ModelProperty {
  final String? name;
  final String? type;
  final bool isEnumParam;
  final String? type2;
  final String? type3;

  const ModelProperty(
    this.type, {
    this.name,
    this.isEnumParam = false,
    this.type2,
    this.type3,
  });
}

class ModelSet {
  const ModelSet();
}

class ModelIgnore {
  const ModelIgnore({this.ignoreEqual = false, this.ignoreKey = true});
  final bool ignoreEqual;
  final bool ignoreKey;
}

class ModelNullable {
  const ModelNullable();
}

class ModelLinter {
  final bool ignoreDeprepcated;

  const ModelLinter({this.ignoreDeprepcated = false});
}
