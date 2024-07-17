import 'dart:ui';

///A simple bounds helper object for UI organization
class RectF {
  int tag = 0;
  double l;
  double t;
  double r;
  double b;
  double h = 0;
  double w = 0;
  RectF(this.l, this.t, this.r, this.b) {
    h = b - t;
    w = r - l;
  }

  RectF.withTag(this.l, this.t, this.r, this.b, this.tag) {
    h = b - t;
    w = r - l;
  }

  ///Returns a new Rect of the size of [rN] stacked beneath this one by [pad] units.
  RectF stackUnder(double pad, RectF rN, {bool center = true}) {
    if (center) {
      return RectF.withTag(
          l + (w - rN.w) / 2, //
          b + pad, //
          l + rN.w + (w - rN.w) / 2, //
          b + pad + rN.h, //
          rN.tag);
    } else {
      return RectF.withTag(l, b + pad, r + rN.w, b + pad + rN.h, rN.tag);
    }
  }

  ///Returns a new Rect of the size of [rN] stacked to the left of this one by [pad] units.
  RectF stackLeft(double pad, RectF rN, {bool center = true}) {
    if (center) {
      return RectF.withTag(
          l - pad - rN.w, //
          t + (h - rN.h) / 2, //
          l - pad, //
          t + rN.h + (h - rN.h) / 2, //
          rN.tag);
    } else {
      return RectF.withTag(l - pad - rN.w, t, l - pad, t + rN.h, rN.tag);
    }
  }

  ///Returns a new Rect of the size of [rN] stacked to the right this one by [pad] units.
  RectF stackRight(double pad, RectF rN, {bool center = true}) {
    if (center) {
      return RectF.withTag(
          r + pad, //
          t + (h - rN.h) / 2, //
          r + pad + rN.w, //
          t + rN.h + (h - rN.h) / 2, //
          rN.tag);
    } else {
      return RectF.withTag(r + pad, t, r + pad + rN.w, t + rN.h, rN.tag);
    }
  }

  bool containsPoint(Offset o) {
    return o.dx >= l && o.dx < r && o.dy >= t && o.dy <= b;
  }
}
