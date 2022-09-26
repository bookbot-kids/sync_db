extension $List<E> on List<E> {
  List<E> addItem(E item) {
    final newList = toList();
    newList.add(item);
    return newList;
  }
}
