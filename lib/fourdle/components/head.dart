import 'dart:convert';
import 'dart:math';

import 'package:word_puzzles/fourdle/fourdlestate.dart';
import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/utils/uielement.dart';
import 'package:word_puzzles/dictionary.dart';

UIElement makeHeadUi(FourdleGameState game) {
  return UIElement(
    "head", //
    game,
    fPaintStart: (sender, bounds, c, s) {
      FourdleGameState g = sender.stateTag;

      drawRRectButton(c, bounds, g, colorKey: "colPrimaryDark");

      //read the string from the game grid, or the attempt thingy
      String str = "";
      if (g.draggedCells.isNotEmpty) {
        for (int i = 0; i < g.draggedCells.length; i++) {
          str += utf8.decode([g.letters[g.draggedCells[i]]]);
        }
      } else if (g.messageText.isNotEmpty) {
        str = g.messageText;
      }

      double jiggle = 0;
      if (sender.tags.containsKey("jiggle")) {
        jiggle = sender.tags["jiggle"];
        jiggle = sin(jiggle * 25) * 1.3 * g.scale;
      }

      if (str.isNotEmpty) {
        drawText(
            c, Dictionary.capsFirst(str), "dHeadingSize", "colFontMain", bounds,
            style: "bold");
      }
    },
  );
}
