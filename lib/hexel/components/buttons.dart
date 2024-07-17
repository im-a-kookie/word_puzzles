import 'dart:convert';

import 'package:word_puzzles/hexel/hexelstate.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/utils/uielement.dart';

void _donk(HexelGameState g, UIElement? header, String message, String sound,
    bool jiggle) {
  g.messageText = message;
  g.widgetController?.playSound(sound);

  //clear the message
  g.widgetController?.startAnimation(0.5, (x) {}, (x) {
    //blank the random text thing
    g.messageText = "";
  });

  if (jiggle) {
    g.widgetController?.startAnimation(0.5, (x) {
      header?.tags["jiggle"] = x;
    }, (x) {
      //clear the jiggle and blank the attempted word
      header?.tags.remove("jiggle");
    });
  }
}

void _f(HexelGameState g, UIElement u) {
  String word = g.currentWord; //get the word
  //and clear it in the game state now, to prevent any mishaps
  g.currentWord = "";

  var h = g.tryGetByID("head");
  if (word.isEmpty) return;

  //the word is too short
  if (word.length <= 3) {
    _donk(g, h, "Too Short!", "audio/bonk.mp3", true);
    return;
  }
  //the word lacks the required central letter
  if (!word.contains(utf8.decode([g.letters[0]]))) {
    _donk(g, h, "Missing Letter!", "audio/bonk.mp3", true);
    return;
  }

  bool easy = g.getSolutions().containsKey(word);
  bool hard = g.getBonusWords().containsKey(word);

  //we already found it
  if (g.foundWords.contains(word)) {
    _donk(g, h, "Already Found!", "audio/pop.mp3", true);
  }
  //it's a bonus word
  if (hard) {
    g.foundWords.add(word);
    _donk(g, h, "Bonus Word!", "audio/ding.mp3", false);
    //it's a normal word
  } else if (easy) {
    g.foundWords.add(word);
    _donk(g, h, "Nice! ${word.length}", "audio/ding.mp3", false);
  } else {
    //it's not a word at all
    _donk(g, h, "Not Found!", "audio/bonk.mp3", true);
  }
}

UIElement makeHexOkay(UIPage game) {
  return UIElement(
    "okay",
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
          volume:
              1.15 * (Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3));
      g.widgetController?.invalidate();
    },
    fOnStartDrag: (sender, bounds, value) {
      sender.tags["press_vis"] = true;
      sender.tags["press_fun"] = true;
      HexelGameState g = sender.stateTag;
      g.widgetController?.invalidate();
    },
    fOnClickUp: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      if (sender.tags["press_fun"]) {
        sender.tags["press_fun"] = false;
        _f(g, sender);
        g.widgetController?.invalidate();
      }
      g.widgetController?.startAnimation(
          0.1, (x) {}, (x) => sender.tags["press_vis"] = false);
    },
    fOnEndDrag: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      if (sender.tags["press_fun"]) {
        sender.tags["press_fun"] = false;
        _f(g, sender);
        g.widgetController?.invalidate();
      }
      g.widgetController?.startAnimation(
          0.1, (x) {}, (x) => sender.tags["press_vis"] = false);
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
      drawText(c, "Ok", "dHeadingSize",
          (sender.id == "cell_0") ? "colStroke" : "colFontMain", bounds,
          style: "bold");
    },
  );
}

UIElement makeHexBackspace(UIPage game) {
  return UIElement(
    "backspace",
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
      g.widgetController?.invalidate();
    },
    fOnClickUp: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      if (sender.tags["press_fun"]) {
        sender.tags["press_fun"] = false;
        if (g.currentWord.isNotEmpty) {
          g.currentWord = g.currentWord.substring(0, g.currentWord.length - 1);
        }
      }
      g.widgetController?.startAnimation(
          0.1, (x) {}, (x) => sender.tags["press_vis"] = false);
      g.dirty = true;
      g.widgetController?.invalidate();
    },
    fOnEndDrag: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      if (sender.tags["press_fun"]) {
        sender.tags["press_fun"] = false;
        if (g.currentWord.isNotEmpty) {
          g.currentWord = g.currentWord.substring(0, g.currentWord.length - 1);
        }
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
      drawText(c, "←", "dHeadingSize",
          (sender.id == "cell_0") ? "colStroke" : "colFontMain", bounds,
          style: "bold");
    },
  );
}

UIElement makeHexNewgame(UIPage game) {
  return UIElement(
    "create",
    game,
    init: (sender, state) {
      sender.tags["clicked"] = false;
    },
    fOnClickDown: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      g.widgetController?.playSound("audio/click1.mp3",
          volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);

      if (g.isDaily) {
        g.saveData("${g.getId()}_d");
      }

      g.isDaily = false;
      g.reset(DateTime.now().microsecondsSinceEpoch);
      g.saveData("${g.getId()}_c");
      g.cleanUi();
      g.dirty = true;
      g.widgetController?.invalidate();
    },
    fPaintEnd: (sender, bounds, c, s) {
      HexelGameState g = sender.stateTag;

      drawRRectButton(c, bounds, g, colorKey: "colPrimaryFill");
      drawText(c, "New Game!", "dHeadingSize", "colFontMain", bounds,
          style: "bold");
    },
  );
}

UIElement makeHexDailyButton(HexelGameState game) {
  return UIElement(
    "daily",
    game,
    init: (sender, state) {
      sender.tags["clicked"] = false;
    },
    fOnClickDown: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      g.widgetController?.playSound("audio/click1.mp3",
          volume:
              1.2 * (Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3));
      g.saveData("${g.getId()}_c");
      if (g.isDaily) g.saveData("${g.getId()}_d");
      g.cleanUi();

      g.isDaily = true;
      g.loadData("${g.getId()}_d");
      g.cleanUi();
      g.isDaily = true;
    },
    fPaintEnd: (sender, bounds, c, s) {
      HexelGameState g = sender.stateTag;
      drawRRectButton(c, bounds, g, colorKey: "colPrimaryFill");
      drawText(c, "Daily Challenge!", "dHeadingSize", "colFontMain", bounds,
          style: "bold");
    },
  );
}

UIElement makeHexSolveButton(HexelGameState game) {
  return UIElement(
    "solve",
    game,
    init: (sender, state) {
      sender.tags["clicked"] = false;
    },
    fOnClickDown: (sender, bounds, value) {
      HexelGameState g = sender.stateTag;
      if (g.isDaily) return;
      for (String s in g.availableWords.keys) {
        g.foundWords.add(s);
      }
      g.saveData("${g.getId()}_c");
      g.tryGetByID("menu")?.hidden = true;
      g.tryGetByID("word")?.hidden = false;
      g.widgetController?.playSound("audio/click1.mp3",
          volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);
      g.cleanUi();
    },
    fPaintEnd: (sender, bounds, c, s) {
      HexelGameState g = sender.stateTag;
      drawRRectButton(c, bounds, g,
          colorKey: g.isDaily ? "colGrey" : "colPrimaryFill");

      drawText(c, "Solve!", "dHeadingSize", "colFontMain", bounds,
          style: "bold");
    },
  );
}
