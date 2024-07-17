import 'dart:math';

import 'package:flutter/material.dart';
import 'package:word_puzzles/hexel/hexelstate.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/utils/uielement.dart';
import 'package:word_puzzles/dictionary.dart';

UIElement makeHexHead(HexelGameState game) {
  return UIElement(
    "head", //
    game,
    fPaintStart: (sender, bounds, c, s) {
      HexelGameState g = sender.stateTag;

      drawRRectButton(c, bounds, g, colorKey: "colPrimaryDark");

      //read the string from the game grid, or the attempt thingy
      String str = "";
      str = g.currentWord;
      if (g.currentWord.isEmpty && g.messageText.isNotEmpty) {
        str = g.messageText;
      }
      //handle the jiggledy-piggle
      double jiggle = 0;
      if (sender.tags.containsKey("jiggle")) {
        jiggle = sender.tags["jiggle"];
        jiggle = sin(jiggle * 25) * 1.3 * g.scale;
      }
      //get the thingy thing
      if (str.isNotEmpty) {
        TextSpan ts = Style.t!.getText(
            Dictionary.capsFirst(str), "dHeadingSize", "colFontMain",
            style: "bold");
        var textPainter = TextPainter(
          text: ts,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: bounds.w * 2);
        double dx = bounds.l + jiggle + (bounds.w - textPainter.width) / 2;
        double dy = bounds.t + (bounds.h - textPainter.height) / 2;
        textPainter.paint(c, Offset(dx, dy));
        textPainter.dispose();
      }
    },
  );
}
