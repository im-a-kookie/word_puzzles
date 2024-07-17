import 'package:word_puzzles/fourdle/fourdlestate.dart';
import 'package:word_puzzles/fourdle/grids.dart';
import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/uielement.dart';
import 'package:word_puzzles/dictionary.dart';

UIElement makeDailyButton(FourdleGameState game) {
  return UIElement(
    "daily",
    game,
    init: (sender, state) {
      sender.tags["clicked"] = false;
    },
    fOnClickDown: (sender, bounds, value) {
      FourdleGameState g = sender.stateTag;

      g.saveData("${g.getId()}_c");
      if (g.isDaily) g.saveData("${g.getId()}_d");

      g.cleanUi();

      g.cachedId = g.getDaySeed();
      var grid = GridBuilder.create(g.cachedId, Dictionary.gen!)[0];
      g.pushLetters(grid);
      g.loadData("${g.getId()}_d");
      g.isDaily = true;

      g.widgetController?.playSound("audio/click1.mp3",
          volume:
              1.25 * (Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3));
    },
    fPaintEnd: (sender, bounds, c, s) {
      FourdleGameState g = sender.stateTag;
      drawRRectButton(c, bounds, g, colorKey: "colPrimaryFill");
      drawText(c, "Daily Challenge", "dHeadingSize", "colFontMain", bounds,
          style: "bold");
    },
  );
}
