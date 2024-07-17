import 'package:word_puzzles/hexel/hexelstate.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/uielement.dart';

import 'dart:convert';

import 'package:word_puzzles/utils/renderhelpers.dart';

UIElement makeHexcell(HexelGameState game, int cell) {
  int x = cell;
  return UIElement(
    "cell_$x",
    game,
    init: (sender, state) {
      sender.tags["press_vis"] = false;
      sender.tags["press_fun"] = false;
    },
    fOnClickDown: (sender, bounds, value) {
      sender.tags["press_vis"] = true;
      sender.tags["press_fun"] = true;
      HexelGameState g = sender.stateTag;
      g.widgetController?.playSound("audio/click1.mp3",
          volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);
      g.widgetController?.invalidate();
    },
    fOnStartDrag: (sender, bounds, value) {
      sender.tags["press_vis"] = true;
      sender.tags["press_fun"] = true;
      HexelGameState g = sender.stateTag;
      g.widgetController?.playSound("audio/click1.mp3",
          volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);
      g.widgetController?.invalidate();
    },
    fOnClickUp: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      if (sender.tags["press_fun"]) {
        sender.tags["press_fun"] = false;
        g.currentWord += utf8.decode([g.letters[sender.bounds.tag]]);
      }
      g.widgetController?.startAnimation(
          0.1, (x) {}, (x) => sender.tags["press_vis"] = false);
      g.widgetController?.invalidate();
    },
    fOnEndDrag: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      if (sender.tags["press_fun"]) {
        sender.tags["press_fun"] = false;
        g.currentWord += utf8.decode([g.letters[sender.bounds.tag]]);
      }
      g.widgetController?.startAnimation(
          0.1, (x) {}, (x) => sender.tags["press_vis"] = false);
      g.dirty = true;
      g.widgetController?.invalidate();
    },
    fPaintStart: (sender, bounds, c, s) {
      //draw the box based on the game state
      HexelGameState g = sender.stateTag;

      //draw the outline, it's very slightly longer
      // bool press = g.draggedCells.contains(bounds.tag);
      // bool lit = g.greenCells.contains(bounds.tag);
      // bool unlit = g.dimCells.contains(bounds.tag);

      String colorKey = "colPrimaryFill";
      if (sender.tags["press_vis"] == true) colorKey = "colPrimaryDark";
      // if (lit) colorKey = "colGreen";
      // if (unlit) colorKey = "colGrey";
      if (sender.id == "cell_0") colorKey = "colFontMain";

      drawRRectButton(c, bounds, g,
          colorKey: colorKey,
          pressable: true,
          pressed: sender.tags["press_vis"] == true);
    },
    fPaintEnd: (sender, bounds, c, s) {
      HexelGameState g = sender.stateTag;

      drawText(c, utf8.decode([g.letters[bounds.tag]]).toUpperCase(),
          "dHeadingSize", bounds.tag == 0 ? "colStroke" : "colFontMain", bounds,
          style: "bold");
    },
  );
}
