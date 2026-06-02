import 'package:flutter_test/flutter_test.dart';

void reorderList(List<String> items, int oldIndex, int newIndex) {
  if (oldIndex == newIndex) return;
  final item = items.removeAt(oldIndex);
  items.insert(newIndex, item);
}

int updateSelection(int selected, int oldIndex, int newIndex) {
  if (oldIndex == newIndex) return selected;
  if (selected == oldIndex) return newIndex;
  if (oldIndex < selected && newIndex >= selected) return selected - 1;
  if (oldIndex > selected && newIndex <= selected) return selected + 1;
  return selected;
}

void main() {
  test('reorder forward lands on expected index', () {
    final items = ['1', '2', '3', '4', '5'];
    reorderList(items, 0, 4);
    expect(items, ['2', '3', '4', '5', '1']);
  });

  test('reorder backward lands on expected index', () {
    final items = ['1', '2', '3', '4', '5'];
    reorderList(items, 4, 0);
    expect(items, ['5', '1', '2', '3', '4']);
  });

  test('reorder to middle position is exact', () {
    final items = ['1', '2', '3', '4', '5'];
    reorderList(items, 0, 2);
    expect(items, ['2', '3', '1', '4', '5']);
    expect(items[2], '1');
  });

  test('selection follows moved item', () {
    expect(updateSelection(0, 0, 4), 4);
    expect(updateSelection(2, 0, 4), 1);
    expect(updateSelection(4, 4, 0), 0);
  });
}
