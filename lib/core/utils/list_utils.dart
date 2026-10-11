class ReorderUtils {
  /// Moves an item the way Flutter's ReorderableListView reports it:
  /// when dragging downwards, `newIndex` is one past the final position.
  static void move<T>(List<T> list, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
  }
}
