import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzles/utils/rect.dart';

void main() {
  test("RectF - Construction LTRB", () {
    double l = 10;
    double t = 10;
    double r = 40;
    double b = 22;
    RectF rect = RectF(l, t, r, b);
    expect(rect.w == (r - l), equals(true));
    expect(rect.h == (b - t), equals(true));
  });

  test("RectF - Tag Inheritance", () {
    double l = 10;
    double t = 10;
    double r = 40;
    double b = 22;
    int tag = 10;
    RectF rect = RectF.withTag(l, t, r, b, tag);
    //check that all of the stackings inherit tags correctly
    RectF rectNext = rect.stackUnder(1, rect);
    expect(rectNext.tag == tag, equals(true));
    rectNext = rect.stackLeft(1, rect);
    expect(rectNext.tag == tag, equals(true));
    rectNext = rect.stackRight(1, rect);
    expect(rectNext.tag == tag, equals(true));
  });
}
