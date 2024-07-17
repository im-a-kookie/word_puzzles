import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/utils/uielement.dart';

import '../types.dart';

///Creates a generic toolbar UI element, which is designed to play with the [WordSearcher] UIController.
UIElement makeToolUi(UIPage game) {
  return UIElement(
    "tool", //
    game,
    init: (sender, state) {
      sender.stateTag = state;
      UIPage u = sender.stateTag;
      var menu = u.tryGetByID("menu");
      var word = u.tryGetByID("word");
      var grid = u.tryGetByID("grid");

      var menuh = menu?.hidden == true;
      var landscape = u.orientationMode == Layouts.landscape;

      menu?.hidden = true;
      word?.hidden = !landscape || !menuh;
      grid?.hidden = false;

      for (var c in u.elements) {
        if (c.id.startsWith("cell_")) c.hidden = false;
      }
    },
    fOnClickDown: (sender, bounds, value) {
      UIPage u = sender.stateTag;
      //determine properties of the gear
      double gearRadius = 0.7 * bounds.h / 2;
      u.widgetController?.playSound("audio/click1.mp3",
          volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);

      var menu = u.tryGetByID("menu");
      var word = u.tryGetByID("word");
      var grid = u.tryGetByID("grid");

      //see if we clicked on the gear
      if (value.localPosition.dx > bounds.r - 3.5 * gearRadius) {
        //handle the menu hide/show logic
        bool h = menu?.hidden == true;
        menu?.hidden = !h;
      } else {
        if (menu?.hidden == false) {
          menu?.hidden = true;
        } else {
          bool h = word?.hidden == true;
          word?.hidden = !h;
        }
      }

      //now handle the landscape/portrait difference
      if (u.orientationMode == Layouts.landscape) {
        grid?.hidden = false;
        word?.hidden = menu?.hidden == false;
      } else {
        grid?.hidden = (word?.hidden == false) || (menu?.hidden == false); //
      }
      bool gh = grid?.hidden == true;
      for (var c in u.elements) {
        if (c.id.startsWith("cell_")) c.hidden = gh;
      }

      u.refreshLayouts();
      u.dirty = true;
      u.widgetController?.invalidate();
    },
    fPaintStart: (sender, bounds, c, s) {
      if (sender.stateTag is! WordSearcher) return;
      if (sender.stateTag is! UIPage) return;

      UIPage u = sender.stateTag;
      WordSearcher w = sender.stateTag;

      //1. Build a string of the first N words

      //first, draw me
      drawRRectButton(c, bounds, u, colorKey: "colPrimaryDark");

      //determine properties of the gear
      double gearRadius = 0.7 * bounds.h / 2;

      double x = bounds.r - 1.7 * gearRadius;
      double y = bounds.t + bounds.h / 2.1;

      double numberOfTeeth = 7;
      double toothFrac = 0.6;
      double toothHeight = gearRadius / 5;

      //now generate a path
      double angleStep = (2 * pi) / numberOfTeeth;

      List<Offset> points = List.empty(growable: true);
      for (int i = 0; i < numberOfTeeth; i++) {
        //draw the inner line
        double a0 = i * angleStep;
        double a1 = a0 + angleStep * toothFrac;

        double xx0 = x + (gearRadius - toothHeight) * cos(a0);
        double xx1 = x + (gearRadius) * cos(a0);
        double xx2 = x + (gearRadius) * cos(a1);
        double xx3 = x + (gearRadius - toothHeight) * cos(a1);

        double yy0 = y + (gearRadius - toothHeight) * sin(a0);
        double yy1 = y + (gearRadius) * sin(a0);
        double yy2 = y + (gearRadius) * sin(a1);
        double yy3 = y + (gearRadius - toothHeight) * sin(a1);

        points.add(Offset(xx0, yy0));
        points.add(Offset(xx1, yy1));
        points.add(Offset(xx2, yy2));
        points.add(Offset(xx3, yy3));
      }
      Path path = Path();
      path.addPolygon(points, true);
      path.close();
      var stroke = Style.t!.getStroke("dLineMed", "colStroke",
          defaultWidth: 2, defaultColor: Colors.black);

      String text = "";
      bool titular = false;
      if (u.tryGetByID("menu")?.hidden == false) {
        c.drawPath(path,
            Style.t!.getFill("colHighlight", defaultColor: Colors.yellow));
        c.drawCircle(
            Offset(x, y), gearRadius / 3, Style.t!.getFill("colPrimaryDark"));
        text = "Options";
        titular = true;
      }

      c.drawPath(path, stroke);
      c.drawCircle(Offset(x, y), gearRadius / 3, stroke);

      //it shows this stuff by default
      if (u.tryGetByID("menu")?.hidden == true &&
          u.tryGetByID("word")?.hidden == true) {
        text = "";
        for (String word in w.getFoundWords().toList().reversed) {
          text += "$word, ";
        }
        //prune it
        int length = 36;
        bool needdots = text.length >= length;
        if (text.isNotEmpty) {
          text = text.substring(0, min(length - 2, text.length - 2));
        }
        if (needdots) text += "...";
      }

      if (u.tryGetByID("word")?.hidden == false) {
        text = "Words";
        titular = true;
      }

      if (text.isNotEmpty) {
        //get a text thing ready
        var painter = getPainter(text,
            titular ? "dHeadingSize" : "dRegularSize", "colFontMain", bounds.w,
            style: "bold");
        //double dx = bounds.l + (bounds.w - textPainter.width) / 2;
        double dy = bounds.t + (bounds.h - painter.height) / 2;
        painter.paint(c, Offset(bounds.l + bounds.h * 0.9, dy));
        painter.dispose();

        var stroke = Style.t!.getStroke("dStrokeMed", "colFontMain");
        var ax = bounds.h * 0.2;
        var bx = bounds.h * 0.6;
        var ay = bounds.h * 0.3;
        var by = bounds.h * 0.7;

        //draw the triangular thingy
        if (titular) {
          List<Offset> points = [
            Offset(bounds.l + ax, bounds.t + ay + by * 0.43),
            Offset(bounds.l + 0.5 * (bx + ax), bounds.t + ay + by * 0.13),
            Offset(bounds.l + bx, bounds.t + ay + by * 0.43)
          ];
          c.drawPoints(PointMode.polygon, points, stroke);
        } else {
          List<Offset> points = [
            Offset(bounds.l + ax, bounds.t + ay + by * 0.1),
            Offset(bounds.l + 0.5 * (bx + ax), bounds.t + ay + by * 0.43),
            Offset(bounds.l + bx, bounds.t + ay + by * 0.1)
          ];
          c.drawPoints(PointMode.polygon, points, stroke);
        }
      }
    },
  );
}
