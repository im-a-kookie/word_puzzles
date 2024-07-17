import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:word_puzzles/hexel/components/cell.dart';
import 'package:word_puzzles/hexel/components/header.dart';
import 'package:word_puzzles/hexel/components/buttons.dart';
import 'package:word_puzzles/main.dart';
import 'package:word_puzzles/utils/uielements/menu.dart';
import 'package:word_puzzles/utils/rng.dart';
import 'package:word_puzzles/utils/uielements/score.dart';
import 'package:word_puzzles/utils/uielements/solve.dart';
import 'package:word_puzzles/utils/uielements/toolbar.dart';
import 'package:word_puzzles/utils/types.dart';
import 'package:word_puzzles/utils/uielement.dart';
import 'package:word_puzzles/utils/utils.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/utils/uielements/wordview.dart';
import 'package:word_puzzles/dictionary.dart';

import '../utils/logging.dart';

class HexelGameState extends UIPage implements WordSearcher {
  Uint8List letters = Uint8List(7);

  ///Represents the current word that the player has typed out,
  String currentWord = "";

  ///Represents the message text to show (e.g "Not Found!")
  String messageText = "";

  ///A collection of every word that has been found so far
  HashSet<String> foundWords = HashSet();

  ///A collection of all available words as solutions for the current puzzle
  HashMap<String, List<int>> availableWords = HashMap();

  ///A collection of bonus words that can be found in the current puzzle
  HashMap<String, List<int>> bonusWords = HashMap();

  ///Otherwise just generate a random challenge
  bool isEasier = true;

  int cachedId = -1;

  HexelGameState() {
    //create the UI elemenets
    elements.add(makeHexHead(this));
    elements.add(makeToolUi(this));
    elements.add(makeMenuUi(this));
    elements.add(makeWordUi(this));
    elements.add(makeScoreUi(this));

    elements.add(makeHexBackspace(this));
    elements.add(makeHexOkay(this));

    elements.add(makeHexDailyButton(this));
    elements.add(makeHexNewgame(this));
    elements.add(makeSolveButton(this));

    elements.add(UIElement("grid", this));

    for (int i = 0; i < 7; ++i) {
      elements.add(makeHexcell(this, i));
    }
  }

  List<int>? getUniqueLettersFromWord(String word) {
    List<int> codes = List.empty(growable: true);
    int pos = 0;
    int flag = 0;
    for (int i = 0; i < word.length; i++) {
      if (pos >= 7) return null;
      int val = word.codeUnitAt(i);
      int mask = 1 << (val - 97);
      if (flag & mask == 0) {
        codes.add(val);
      }
      flag |= mask;
    }
    if (codes.length > 7) return null;
    return codes;
  }

  @override
  HashMap<String, RectF> getUILayout(Size canvas, stateObject) {
    return computeHexelLayout(stateObject, canvas);
  }

  ///Resets the letters in the game using the value given in [seed].
  ///Providing the result of [getDailySeed] will generate a supposedly
  ///unique daily grid
  void reset(int seed) {
    int offset = 0;
    cachedId = seed;
    generator:
    while (true) {
      Rng r = Rng(cachedId + offset);
      var word = Dictionary
          .gen!.panagramWords[r.nextInt(Dictionary.gen!.panagramWords.length)];
      var n = getUniqueLettersFromWord(word);
      logger
          .d("Hexel Word: $word. Expect: ${(n ?? []).length} unique letters.");

      if (n == null) continue;
      r.shuffle(n);
      for (int i = 0; i < 7; i++) {
        letters[i] = n[i];
      }
      //get the solutions from the letters provided
      var soln = Dictionary.ext!.getAllWordsFrom(letters);
      if (Dictionary.checkForProfanity(soln)) {
        logger.wtf("Skipped game due to profanity ($cachedId, $word)!");
        offset += 1 << 16;
        continue generator;
      }
      //we found a good thing!
      foundWords.clear();
      pushLetters(letters);
      break;
    }
  }

  @override
  void loadPage() {
    //check if we need to create the back navigation item
    if (tryGetByID("back") == null) {
      elements.add(makeNavigatorButton(this, "back", "←", menuPage));
    }
    cleanUi();

    //Now use this chance to load the saved state
    loadData("${getId()}_c").then((x) {
      if (!x) {
        reset(getDaySeed());
      }
    });
  }

  @override
  String toSaveString(String key) {
    Map<String, dynamic> data = {};
    data["date"] = cachedId;
    data["daily"] = isDaily;
    data["grid"] = letters;
    data["found"] = foundWords.toList();
    return jsonEncode(data);
  }

  @override
  void fromSaveString(String s, String key) {
    //read the stuff out
    Map<String, dynamic> data = jsonDecode(s);
    isDaily = data["daily"];
    cachedId = data["date"];
    //read the grid thing
    var l = data["grid"];
    for (int i = 0; i < 7; i++) {
      letters[i] = l[i];
    }
    //
    bool clear = false;
    if (isDaily) {
      if (cachedId != getDaySeed()) {
        reset(getDaySeed());
        clear = true;
      }
    }

    if (!clear) {
      setFoundWords((data["found"] as List<dynamic>).map((x) => x));
    }

    pushLetters(letters, found: foundWords);
  }

  @override
  String getId() {
    return "hexel";
  }

  @override
  String getTitle() {
    return "Hexel";
  }

  @override
  void refreshLayouts() {
    //get the main UI panels that we're interested in
    var menu = tryGetByID("menu");
    var word = tryGetByID("word");
    var grid = tryGetByID("grid");
    var back = tryGetByID("backspace");
    var okay = tryGetByID("okay");

    if (orientationMode == Layouts.landscape) {
      grid?.hidden = false;
      word?.hidden = menu?.hidden == false;
    } else {
      grid?.hidden = (menu?.hidden == false || word?.hidden == false);
    }

    for (var e in elements) {
      if (e.id.startsWith("cell_")) e.hidden = grid?.hidden == true;
    }

    back?.hidden = grid?.hidden == true;
    okay?.hidden = grid?.hidden == true;
  }

  @override
  void computeSolutions() {
    var list = Dictionary.ext!.getAllWordsFrom(letters, requireIndex: 0);

    if (isEasier || isDaily) {
      availableWords.clear();
      bonusWords.clear();
      //now check if it's valid as a general word
      for (var k in list) {
        if (Dictionary.gen!.isValid(k)) {
          availableWords[k] = [];
        } else {
          bonusWords[k] = [];
        }
      }
    } else {
      HashMap<String, List<int>> m = HashMap();
      for (String s in list) {
        m[s] = [0];
      }
      bonusWords.clear();
      availableWords = m;
    }
  }

  @override
  Iterable<String> getFoundWords() {
    return foundWords;
  }

  @override
  Uint8List getLetters() {
    return letters;
  }

  @override
  HashMap<String, List<int>> getSolutions() {
    return availableWords;
  }

  @override
  HashMap<String, List<int>> getBonusWords() {
    return bonusWords;
  }

  @override
  void pushLetters(Uint8List newGrid, {Iterable<String>? found}) {
    //set the words that we've found already
    if (found != null) {
      setFoundWords(found);
    } else {
      foundWords.clear();
    }

    if (letters != newGrid) {
      for (int i = 0; i < 7; i++) {
        letters[i] = newGrid[i];
      }
    }

    //compute the solutions
    computeSolutions();
  }

  @override
  void setFoundWords(Iterable<String> words) {
    if (words == foundWords) return;
    foundWords.clear();
    foundWords.addAll(words);
  }
}

HashMap<String, RectF> computeHexelLayout(UIPage u, Size canvas) {
  var rects = computeGenericLayout(u, canvas);
  RectF grid = rects["grid"]!;

  double cx = grid.l + grid.w / 2;
  double cy = grid.t + grid.h / 2.5;
  double radius = grid.w * 0.25;

  List<Offset> points = List.empty(growable: true);
  points.add(Offset(cx, cy));

  for (int i = 0; i < 6; i++) {
    double angle = 2 * pi * i / 6;
    double x = radius * cos(angle) + cx;
    double y = radius * sin(angle) + cy;
    points.add(Offset(x, y));
  }

  double cpad = grid.w / 24;
  //4x + 3p = width -> x = (width - 3p) / 4
  double cellWidth = (grid.w - 3 * cpad) * 0.108;
  for (int i = 0; i < 7; i++) {
    rects["cell_$i"] = RectF.withTag(
        points[i].dx - cellWidth, //
        points[i].dy - cellWidth, //
        points[i].dx + cellWidth, //
        points[i].dy + cellWidth,
        i); //
  }

  RectF head = rects["head"]!;
  RectF cell3 = rects["cell_3"]!;
  rects["backspace"] = RectF(head.r - head.h, head.t, head.r, head.b);
  rects["okay"] = RectF(grid.r - 3 * head.h, cell3.b + 2 * cpad,
      grid.r - head.h, cell3.b + 2 * cpad + head.h);
  rects["head"] = RectF(head.l, head.t, head.r - head.h, head.b);
  return rects;
}
