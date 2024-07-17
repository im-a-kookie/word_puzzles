import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:word_puzzles/fourdle/fourdlestate.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/utils/uielement.dart';

UIElement makeCellUi(FourdleGameState game, int cell) {
  //calculate the grid coordinates
  //4x+y scheme
  int x = cell ~/ 4;
  int y = cell % 4;
  return UIElement(
    "cell_$x$y",
    game,
    //Paint the cell
    fPaintStart: (sender, bounds, c, s) {
      //draw the box based on the game state
      FourdleGameState g = sender.stateTag;

      //Determine the state of the cell
      bool press = g.draggedCells.contains(bounds.tag);
      bool lit = g.greenCells.contains(bounds.tag);
      bool unlit = g.dimCells.contains(bounds.tag);

      //Determine the color of the cell based on its state
      String colorKey = "colPrimaryFill";
      if (press) colorKey = "colPrimaryDark";
      if (lit) colorKey = "colGreen";
      if (unlit) colorKey = "colGrey";

      //Draw the button
      drawRRectButton(c, bounds, g,
          colorKey: colorKey, pressable: true, pressed: press);

      //fade the cells that aren't used anymore
      if (g.usageCounters[bounds.tag] <= 0 &&
          g.startCounters[bounds.tag] <= 0) {
        drawRRectButton(c, bounds, g,
            colorKey: "colPrimaryFadeover", pressable: true, pressed: press);
      }
    },
    //Last step, we have to draw the letters.
    //Drawing at the end ensures that the letters appear on the top
    //without the need for complicateed layering
    fPaintEnd: (sender, bounds, c, s) {
      FourdleGameState g = sender.stateTag;

      drawText(c, utf8.decode([g.letters[bounds.tag]]).toUpperCase(),
          "dHeadingSize", "colFontMain", bounds,
          style: "bold",
          horizontalAlign: TextAlign.center,
          verticalAlign: TextAlignVertical.center);

      drawText(
          c,
          "${g.startCounters[bounds.tag]}",
          "dRegularSize",
          "colFontMainFaded",
          RectF(bounds.l + bounds.w / 15, bounds.t, bounds.r,
              bounds.b - bounds.w / 15),
          horizontalAlign: TextAlign.left,
          verticalAlign: TextAlignVertical.bottom);
    },
  );
}
