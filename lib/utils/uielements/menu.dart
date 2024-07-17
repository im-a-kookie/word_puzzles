import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/utils/uielement.dart';

UIElement makeMenuUi(UIPage game) {
  return UIElement(
    "menu", //
    game,
    fPaintStart: (sender, bounds, c, s) {
      UIPage g = sender.stateTag;
      drawRRectButton(c, bounds, g, colorKey: "colPrimaryDark");
    },
  );
}
