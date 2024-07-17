import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/main.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/types.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/utils/uielement.dart';

Map<String, UIPage> pages = {};

class GamePainter extends CustomPainter {
  UIPage currentController;
  GamePainter(this.currentController);

  @override
  void paint(Canvas canvas, Size size) {
    currentController.dirty = false;
    currentController.paintStart(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return curPage.dirty;
  }
}

///Computes a generic game-style layount, with prefilled regions for the
///game area, heading area, toolbar, menu, score-bar, and word display.
HashMap<String, RectF> computeGenericLayout(UIPage g, Size s) {
  HashMap<String, RectF> rects = HashMap<String, RectF>();
  double heightFrac = 0.58;
  double aw = min(s.width, s.height * heightFrac);
  double pad = aw / 16.0;
  double vpad = pad * 0.75;

  //the width of the grid area
  double gridWidth = aw - 2 * pad;
  double gridHeight = gridWidth;
  double headWidth = gridWidth;

  double cpad = gridWidth / 24;
  //4x + 3p = width -> x = (width - 3p) / 4
  double headHeight = gridWidth / 6;
  double toolHeight = headHeight;
  double menuHeight = pad + gridHeight + pad + headHeight;
  //the size of the tool area
  double toolWidth = gridWidth;

  //the necessary width is such that pad - grid - pad - tool - pad fits into the width
  bool isWide = (s.width - (3 * pad) - gridWidth - toolWidth) > 0;
  if (isWide) {
    rects.putIfAbsent("#landscape", () => RectF.withTag(0.0, 0.0, 0.0, 0.0, 1));
  } else {
    rects.putIfAbsent("#portrait", () => RectF.withTag(0.0, 0.0, 0.0, 0.0, 1));
  }
  //adaptively place the menu etc stuff
  RectF word, head, grid, tool, score, menu, back;

  if (isWide) {
    double fw = gridWidth + pad + toolWidth;
    double sh = headHeight + pad + gridHeight + pad + toolHeight * 0.8;
    double fx = (s.width - fw) / 2.0;
    double fy = (s.height - sh) / 2.0;
    menuHeight = pad + gridHeight;
    head = RectF(fx, fy, fx + headWidth, fy + headHeight);
    tool = head.stackRight(pad, head);
  } else {
    double fw = gridWidth;
    double sh = toolHeight +
        2 * vpad +
        headHeight +
        vpad +
        gridHeight +
        vpad +
        toolHeight * 0.8;
    double fx = (s.width - fw) / 2.0;
    double fy = max(3 * pad, (s.height - sh) / 2.25);
    tool = RectF(fx, fy, fx + gridWidth, fy + toolHeight);
    head = tool.stackUnder(vpad, RectF(0, 0, headWidth, headHeight));
  }
  //Squarble
  //Gribble

  //these parts are straight forward
  grid = head.stackUnder(vpad, RectF(0, 0, gridWidth, gridHeight));
  back = RectF(min(grid.l, tool.l), tool.t - vpad - tool.h * 0.8,
      min(grid.l, tool.l) + tool.h * 1, tool.t - vpad);
  word =
      tool.stackUnder(vpad / 4, RectF(0, 0, toolWidth, menuHeight - pad / 4));
  menu = RectF(word.l, word.t, word.r, word.b);
  score = RectF(
      grid.l, grid.b + vpad * 1.7, tool.r, grid.b + vpad * 1.7 + headHeight);

  //if the menu is showing
  if (g.tryGetByID("menu")?.hidden == false) {
    RectF solve, create, daily;
    daily = RectF(menu.l + cpad, menu.t + cpad, menu.r - cpad,
        menu.t + cpad + toolHeight);
    create = daily.stackUnder(cpad, daily);
    solve = create.stackUnder(cpad, create);
    rects["daily"] = daily;
    rects["solve"] = solve;
    rects["create"] = create;
  }

  //and load the various area rectangles in as well
  rects["head"] = head;
  rects["word"] = word;
  rects["menu"] = menu;
  rects["tool"] = tool;
  rects["grid"] = grid;
  rects["score"] = score;
  rects["back"] = back;
  rects["#scale"] = grid;

  return rects;
}

UIElement makeNavigatorButton(
    UIPage page, String id, String text, UIPage target,
    {CallbackPaint? iconPainter}) {
  var u = UIElement(
    id,
    page,
    fOnClickDown: (sender, bounds, value) {
      UIPage? t = sender.tags["target"];
      curPage.widgetController?.playSound("audio/click1.mp3",
          volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);
      if (t != null) {
        //prepare the new page
        t.widgetController = curPage.widgetController;
        curPage = t;
        curPage.loadPage();
      }
      curPage.widgetController?.invalidate();
    },
    fPaintStart: (sender, b, c, s) {
      UIPage m = sender.stateTag;
      //draw the button
      drawRRectButton(c, b, m, colorKey: "colPrimaryFill");
      //get the text span
      var ts = Style.t!
          .getText(sender.tags["text"] ?? "", "dHeadingSize", "colFontMain");
      var tp = TextPainter()
        ..text = ts
        ..textDirection = TextDirection.ltr
        ..textAlign = TextAlign.center;
      tp.layout(maxWidth: b.w);
      //calculate the placement
      double l = b.l;
      if (sender.fPaintEnd != null) l += b.h * 0.8;
      double w = b.r - l;

      //paint it like this
      tp.paint(
          c, Offset(l + (w - tp.width) / 2, b.t + (b.h - tp.height * 1.1) / 2));
      tp.dispose();
    },
    fPaintEnd: iconPainter,
  );
  u.tags["text"] = text;
  u.tags["target"] = target;
  return u;
}
