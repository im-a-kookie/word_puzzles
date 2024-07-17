import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/types.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/utils/uielement.dart';

UIElement makeScoreUi(UIPage game) {
  return UIElement(
    "score", //
    game,
    init: (sender, state) {
      sender.tags["grids"] = "";
      sender.tags["letter_count"] = -1;
      sender.tags["have_count"] = -1;
      sender.tags["have_words"] = -1;
      sender.tags["genius_words"] = -1;
    },
    fPaintStart: (sender, bounds, c, s) {
      UIPage g = sender.stateTag;
      WordSearcher ws = g as WordSearcher;
      int genCount = 0;

      String s = utf8.decode(ws.getLetters());
      if (sender.tags["grids"] != s ||
          !sender.tags.containsKey("letter_count") ||
          sender.tags["letter_count"] <= 0) {
        if (ws.getSolutions().isNotEmpty) {
          sender.tags["grids"] = s;
          int n = 0;
          for (String w in ws.getSolutions().keys) {
            n += w.length;
          }
          sender.tags["letter_count"] = n;
          for (String w in ws.getBonusWords().keys) {
            n += w.length;
          }
          sender.tags["genius_words"] = n;
        }
      }

      //Calculate how many words we have vs how many we don't have
      int haveCount = 0;
      if (sender.tags["have_words"] != ws.getFoundWords().length) {
        var fb =
            ws.getFoundWords().where((x) => ws.getSolutions().containsKey(x));
        for (String w in fb) {
          haveCount += w.length;
        }
        sender.tags["have_words"] = fb.length;
        sender.tags["have_count"] = haveCount;
      }

      haveCount = sender.tags["have_count"];
      genCount = sender.tags["genius_words"];

      int goal = sender.tags["letter_count"] as int;
      double ratio = max(0, haveCount / (goal <= 0 ? -1 : goal));

      double by0, by1;
      by0 = bounds.t + 0.25 * bounds.h;
      by1 = bounds.t + 0.4 * bounds.h;

      //1. draw a grey line
      c.drawRRect(
          RRect.fromLTRBR(
              bounds.l, by0, bounds.r, by1, Radius.circular(6 * g.scale)),
          Style.t!.getStroke("dStrokeWide", "colStroke"));

      //and stamp the box part on top

      c.drawRRect(
          RRect.fromLTRBR(
              bounds.l, by0, bounds.r, by1, Radius.circular(6 * g.scale)),
          Style.t!.getFill("colGrey", defaultColor: Colors.grey[700]!));

      double barEnd = bounds.l + bounds.w * ratio;

      c.drawRRect(
          RRect.fromLTRBR(
              bounds.l, by0, barEnd, by1, Radius.circular(6 * g.scale)),
          Style.t!.getFill("colHighlight"));
      //dSubheadingSize
      var ts = Style.t!.getText("$haveCount", "dSubheadingSize", "colFontMain",
          style: "bold");
      var tm = Style.t!.getText("Max: $goal", "dSubheadingSize", "colFontMain",
          style: "bold");

      TextPainter tpScore = TextPainter(
        text: ts,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      //measure, center and render
      tpScore.layout(maxWidth: bounds.w);

      RectF b = RectF(barEnd - tpScore.width * 0.6, by1 + tpScore.height * 0.45,
          barEnd + tpScore.width * 0.6, by1 + tpScore.height * 1.55);

//make a speech bubble shaped thingy
      double r = 2;
      double width = 0.1;
      double prot = 5 * g.scale;
      Radius rr = Radius.circular(r * g.scale);
      Path p = Path();
      p.moveTo(b.l + r, b.b);
      p.lineTo(b.r - r, b.b);
      p.arcToPoint(
        Offset(b.r, b.b - r),
        radius: rr,
      );
      p.lineTo(b.r, b.t + r);
      p.arcToPoint(Offset(b.r - r, b.t), radius: rr);
      double cx = (b.l + b.w / 2);
      double cw = (b.w - 2 * r) * width;

      p.lineTo(cx + cw, b.t);
      p.lineTo(cx, b.t - prot);
      p.lineTo(cx - cw, b.t);
      p.lineTo(b.l + r, b.t);
      p.arcToPoint(Offset(b.l, b.t + r), radius: rr);
      p.lineTo(b.l, b.b - r);
      p.arcToPoint(Offset(b.l + r, b.b), radius: rr);
      p.close();

      double gRat = genCount / goal;
      double gEnd = bounds.l + bounds.w * gRat;

      c.drawLine(Offset(gEnd, by0), Offset(gEnd, by1),
          Style.t!.getStroke("dStrokeThin", "colFontMain"));

      c.drawPath(
          p,
          Style.t!.getStroke("dStrokeMed", "colStroke",
              defaultWidth: 2, defaultColor: Colors.black));
      c.drawPath(
          p, Style.t!.getFill("colGrey", defaultColor: Colors.grey[400]!));

      tpScore.paint(
          c, Offset(barEnd - tpScore.width / 2, by1 + tpScore.height * 0.5));
      tpScore.dispose();

      TextPainter tpMax = TextPainter(
        text: tm,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      //measure, center and render
      tpMax.layout(maxWidth: bounds.w);
      tpMax.paint(c, Offset(bounds.r - tpMax.width, by0 - tpMax.height * 1.25));
      tpMax.dispose();
    },
  );
}
