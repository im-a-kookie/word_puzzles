import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzles/utils/hexcolor.dart';

void main() {
  test("HexColor - Test Hex Translations", () {
    Color c = HexColor.fromHex("#FFF44336");
    expect(c, equals(const Color(0xFFF44336)));
    c = HexColor.fromHex("#3B1CA1");
    expect(c, equals(const Color(0xFF3B1CA1)));
  });
}
