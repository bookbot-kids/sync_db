class ModelProperty {
  final String name;
  final String type;
  final bool isEnumParam;

  const ModelProperty(
    this.type, {
    this.name,
    this.isEnumParam = false,
  });
}
