// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_shooter/models/level_data.dart';
import 'package:bubble_shooter/models/bubble_color.dart';

void main() {
  test('LevelData loads predefined levels properly', () {
    final level1 = LevelData.getLevel(1);
    expect(level1.levelNumber, 1);
    expect(level1.maxShots, greaterThan(20));
    expect(level1.availableColors.contains(BubbleType.red), true);
    expect(level1.bubbleCount, greaterThan(0));

    final level2 = LevelData.getLevel(2);
    expect(level2.levelNumber, 2);
    expect(level2.availableColors.contains(BubbleType.blue), true);
  });
}
