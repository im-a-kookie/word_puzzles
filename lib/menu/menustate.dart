import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:word_puzzles/fourdle/fourdlestate.dart';
import 'package:word_puzzles/hexel/hexelstate.dart';
import 'package:word_puzzles/main.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/utils.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/uicontroller.dart';

class MenuState extends UIPage {
  MenuState() {
    elements.add(makeNavigatorButton(
      this,
      "fourButton",
      "Fourdle",
      this,
      iconPainter: (sender, bounds, c, s) {
        ///Draw a simple grid of squares in a 4x4 arrangement
        UIPage u = sender.stateTag;
        double x = bounds.l + bounds.h * 0.3;
        double y = bounds.t + bounds.h * 0.1;
        double dotPad = bounds.h * 0.05;
        double dotWidth = (bounds.h * 0.8 - 3 * dotPad) / 4;
        //Highlight an F shape
        List<int> parts = [1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0];
        for (int i = 0; i < 4; i++) {
          for (int j = 0; j < 4; j++) {
            double nx = i * (dotWidth + dotPad);
            double ny = j * (dotWidth + dotPad);
            c.drawRRect(
                RRect.fromLTRBR(x + nx, y + ny, x + nx + dotWidth,
                    y + ny + dotWidth, Radius.circular(2 * u.scale)),
                Style.t!.getFill(
                    parts[j * 4 + i] == 0 ? "colFontMain" : "colGreen"));
          }
        }
      },
    ));

    elements.add(makeNavigatorButton(
      this,
      "hexButton",
      "Hexel",
      this,
      iconPainter: (sender, bounds, c, s) {
        //draw several little boxes in a hexagonal pattern
        //ala the honeycome Spelling Bee etc format
        UIPage u = sender.stateTag;
        double x = bounds.l + bounds.h * 0.3;
        double y = bounds.t + bounds.h * 0.1;
        double xx = x + bounds.h * 0.4;
        double yy = y + bounds.h * 0.4;
        double dotPad = bounds.h * 0.05;
        double dotWidth = 1.15 * (bounds.h * 0.8 - 3 * dotPad) / 8;

        //randomly color some of the dots yellow
        List<int> parts = [1, 1, 0, 1, 0, 0, 1];
        c.drawRRect(
            RRect.fromLTRBR(xx - dotWidth, yy - dotWidth, xx + dotWidth,
                yy + dotWidth, Radius.circular(2 * u.scale)),
            Style.t!.getFill(parts[0] == 0 ? "colFontMain" : "colHighlight"));
        for (int i = 0; i < 6; i++) {
          double angle = i * 2 * pi / 6;
          double sx = bounds.h * 0.3 * cos(angle);
          double sy = bounds.h * 0.3 * sin(angle);
          c.drawRRect(
              RRect.fromLTRBR(
                  xx + sx - dotWidth,
                  yy + sy - dotWidth,
                  xx + sx + dotWidth,
                  yy + sy + dotWidth,
                  Radius.circular(2 * u.scale)),
              Style.t!
                  .getFill(parts[i + 1] == 0 ? "colFontMain" : "colHighlight"));
        }
      },
    ));
  }

  @override
  String getId() {
    return "main_menu";
  }

  @override
  String getTitle() {
    return "Menu";
  }

  @override
  void fromSaveString(String s, String key) {}

  @override
  HashMap<String, RectF> getUILayout(Size canvas, stateObject) {
    return getRects(canvas, stateObject);
  }

  @override
  void loadPage() {
    if (tryGetByID("fourButton")?.tags["target"] is! FourdleGameState) {
      fourPage = FourdleGameState();
      tryGetByID("fourButton")?.tags["target"] = fourPage;
    }

    if (tryGetByID("hexButton")?.tags["target"] is! HexelGameState) {
      hexPage = HexelGameState();
      tryGetByID("hexButton")?.tags["target"] = hexPage;
    }
  }

  @override
  String toSaveString(String key) {
    return "";
  }

  ///Generates the rectangles for the menu
  static HashMap<String, RectF> getRects(Size s, MenuState m) {
    var rects = HashMap<String, RectF>();
    double heightFrac = 0.6;
    double aw = min(s.width, s.height * heightFrac);
    double pad = aw / 16.0;
    double gridWidth = aw - 2 * pad;

    double x = (s.width - gridWidth) / 2;
    double y = (s.width - gridWidth) / 8;
    double h = s.height - 2 * y;
    double tileHeight = gridWidth / 6;
    double tilePad = gridWidth / 24;
    RectF main, title, fourdle, hexel;

    main = RectF(x, y, x + gridWidth, y + h);
    //store the scale things
    rects["#portrait"] = RectF.withTag(0, 0, 0, 0, 1);
    rects["#scale"] = main;
    //do the thing
    title = RectF(x, y, x + gridWidth, y + tileHeight);
    fourdle = title.stackUnder(tilePad, title);
    hexel = fourdle.stackUnder(tilePad, fourdle);

    //store into the rect thing
    rects["title"] = title;
    rects["fourButton"] = fourdle;
    rects["hexButton"] = hexel;

    //and done
    return rects;
  }

  @override
  void refreshLayouts() {}
}
