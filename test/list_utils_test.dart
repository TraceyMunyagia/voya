import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/utils/list_utils.dart';

void main() {
  test('dragging down moves the item to the slot before newIndex', () {
    final list = ['a', 'b', 'c'];
    ReorderUtils.move(list, 0, 3); // Flutter reports "end" as 3
    expect(list, ['b', 'c', 'a']);
  });

  test('dragging up inserts at newIndex', () {
    final list = ['a', 'b', 'c'];
    ReorderUtils.move(list, 2, 0);
    expect(list, ['c', 'a', 'b']);
  });

  test('moving next to itself changes nothing', () {
    final list = ['a', 'b', 'c'];
    ReorderUtils.move(list, 1, 2);
    expect(list, ['a', 'b', 'c']);
  });
}
