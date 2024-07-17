import 'package:flutter/material.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/uicontroller.dart';

void drawRRectButton(Canvas c, RectF r, UIPage g,
    {String colorKey = "colButtonPress",
    bool pressable = false,
    bool pressed = false}) {
  var pressOffset = g.scale *
      ((pressable && pressed)
          ? Style.t!.getVal("dButtonPressDistance", defaultVal: 2)
          : 0);

  double offset = Style.t!.getVal("dStrokeWide", defaultVal: 4) / 2;
  double radShrink = g.scale * 12 + offset;
  double tiltSide = 0.7;
  double raise = (Style.t!.getVal("dVerticalRaise", defaultVal: 2) +
          Style.t!.getVal("dButtonPressDistance", defaultVal: 2)) *
      g.scale;

  c.drawRRect(
      RRect.fromLTRBR(r.l - offset, r.t + pressOffset - offset, r.r + offset,
          r.b + offset + raise * tiltSide, Radius.circular(radShrink)),
      Style.t!.getFill("colStroke"));

  c.drawRRect(
      RRect.fromLTRBR(r.l, r.t + pressOffset, r.r, r.b + raise * tiltSide,
          Radius.circular(12 * g.scale)),
      Style.t!.getFill("colPrimaryDarkDark"));

  //and stamp the box part on top
  c.drawRRect(
      RRect.fromLTRBR(
          r.l,
          r.t + pressOffset,
          r.r,
          r.b + pressOffset - raise * (1 - tiltSide),
          Radius.circular(12 * g.scale)),
      Style.t!.getFill(colorKey, defaultColor: Colors.grey[350]!));
}

// hpainters.add(htp);
// height += htp.height;
// height += bounds.w / 50;

TextPainter getPainter(String text, String size, String color, double width,
    {String style = "regular"}) {
  TextSpan span = Style.t!.getText(text, size, color, style: style);
  TextPainter painter = TextPainter(
    text: span,
    textAlign: TextAlign.left,
    textDirection: TextDirection.ltr,
  );
  //measure, center and render
  painter.layout(maxWidth: width);
  return painter;
}

void drawText(Canvas c, String text, String size, String color, RectF bounds,
    {String style = "regular",
    TextAlign horizontalAlign = TextAlign.center,
    TextAlignVertical verticalAlign = TextAlignVertical.center}) {
  TextSpan span = Style.t!.getText(text, size, color, style: style);
  TextPainter painter = TextPainter(
    text: span,
    textAlign: horizontalAlign,
    textDirection: TextDirection.ltr,
  );
  //measure, center and render
  painter.layout(maxWidth: bounds.w);

  double dx = bounds.l;
  switch (horizontalAlign) {
    case TextAlign.left:
      break;
    case TextAlign.center:
      dx += (bounds.w - painter.width) / 2;
    case TextAlign.right:
      dx = bounds.r - painter.width;
    default:
      break;
  }

  double dy = bounds.t;
  switch (verticalAlign) {
    case TextAlignVertical.top:
      break;
    case TextAlignVertical.center:
      dy += (bounds.h - painter.height) / 2;
    case TextAlignVertical.bottom:
      dy = bounds.b - painter.height;
    default:
      break;
  }
  painter.paint(c, Offset(dx, dy));
  painter.dispose();
}
