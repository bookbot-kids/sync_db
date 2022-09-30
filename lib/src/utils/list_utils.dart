extension $List<E> on List<E> {
  List<E> addItem(E item) {
    final newList = toList();
    newList.add(item);
    return newList;
  }

  List<E> addItems(Iterable<E> items, {bool isSet = false}) {
    final newList = toList();
    newList.addAll(items);
    return isSet ? newList.toSet().toList() : newList;
  }
}
