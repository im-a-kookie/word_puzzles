import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/types.dart';
import 'package:word_puzzles/utils/uicontroller.dart';

import 'package:word_puzzles/utils/uielement.dart';

UIElement makeSolveButton(UIPage game) {
  return UIElement(
    "solve",
    game,
    init: (sender, state) {
      sender.tags["clicked"] = false;
    },
    fOnClickDown: (sender, bounds, value) {
      UIPage g = sender.stateTag;
      WordSearcher w = sender.stateTag;
      if (g.isDaily) return;

      List<String> l = [];

      for (String s in w.getSolutions().keys) {
        l.add(s);
      }
      for (String s in w.getBonusWords().keys) {
        l.add(s);
      }

      w.setFoundWords(l);
      g.saveData("${g.getId()}_c");
      g.tryGetByID("menu")?.hidden = true;
      g.tryGetByID("word")?.hidden = false;
      g.widgetController?.invalidate();

      g.widgetController?.playSound("audio/click1.mp3",
          volume:
              1.1 * (Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3));
    },
    fPaintEnd: (sender, bounds, c, s) {
      UIPage g = sender.stateTag;
      drawRRectButton(c, bounds, g,
          colorKey: g.isDaily ? "colGrey" : "colPrimaryFill");
      drawText(c, "Solve!", "dHeadingSize", "colFontMain", bounds,
          style: "bold");
    },
  );
}
