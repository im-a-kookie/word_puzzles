import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:word_puzzles/fourdle/grids.dart';
import 'package:word_puzzles/fourdle/components/cell.dart';
import 'package:word_puzzles/fourdle/components/create.dart';
import 'package:word_puzzles/fourdle/components/daily.dart';
import 'package:word_puzzles/fourdle/components/grid.dart';
import 'package:word_puzzles/fourdle/components/head.dart';
import 'package:word_puzzles/utils/uielements/menu.dart';
import 'package:word_puzzles/utils/uielements/solve.dart';
import 'package:word_puzzles/utils/uielements/wordview.dart';
import 'package:word_puzzles/utils/uielements/score.dart';
import 'package:word_puzzles/utils/uielements/toolbar.dart';
import 'package:word_puzzles/main.dart';
import 'package:word_puzzles/utils/utils.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/dictionary.dart';

import '../utils/types.dart';

///This class describes a game state
class FourdleGameState extends UIPage implements WordSearcher {
  static const String initialLetters = "Plz Wait-Loading";

  ///The letter grid for the game
  Uint8List letters = Uint8List(16);

  ///Counts the number of words starting from any given letter
  Uint16List startCounters = Uint16List(16);

  ///Counts the number of times any given letter is used
  Uint16List usageCounters = Uint16List(16);

  ///The cells the user has dragged over
  List<int> draggedCells = List<int>.empty(growable: true);

  //A hash set of the words the player has found
  HashSet<String> foundWords = HashSet<String>();

  ///Dimmed cells, which will be momentarily grayed out
  HashSet<int> dimCells = HashSet<int>();

  ///Cells to be momentarily greened, e.g for when the player swipes over
  ///a valid word
  HashSet<int> greenCells = HashSet<int>();

  ///Lists the available words
  HashMap<String, List<int>> availableWords = HashMap();

  ///Lists the bonus words
  HashMap<String, List<int>> bonusWords = HashMap();

  ///Holds a message to show in the header box
  String messageText = "";

  ///A cached seed/thing for the RNG
  int cachedId = -1;

  ///A flag indicating whether the current puzzle is a Daily challenge

  ///A flag indicating whether or not to use the easier dictionary (hard dictionary then becomes bonus words)
  bool isEasier = true;

  ///A flag indicating whether the puzzle was solved using the cheat button?
  bool wasSolved = false;

  @override
  String getId() {
    return "fourdle";
  }

  @override
  String getTitle() {
    return isDaily ? "Fourdle - Daily" : "Fourdle";
  }

  @override
  Iterable<String> getFoundWords() {
    return foundWords;
  }

  @override
  void setFoundWords(Iterable<String> words) {
    if (words == foundWords) return;
    foundWords.clear();
    foundWords.addAll(words);
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
  void computeSolutions() {
    var n = GridBuilder.getGridSolutions(getLetters(), Dictionary.ext!);

    //In certain modes, we only use the common dictionary for the solutions
    //Which makes the challenge actually possible to complete.
    if (isEasier || isDaily) {
      availableWords.clear();
      bonusWords.clear();
      //now check if it's valid as a general word
      for (var k in n.entries) {
        if (Dictionary.gen!.isValid(k.key)) {
          availableWords[k.key] = k.value;
        } else {
          bonusWords[k.key] = k.value;
        }
      }
    } else {
      availableWords = n;
      bonusWords.clear();
    }
  }

  @override
  HashMap<String, RectF> getUILayout(Size canvas, stateObject) {
    return computeFourdleLayout(this, canvas);
  }

  ///Constructs a new Fourdle Gamestate using the default settings.
  ///This constructor handles all of the basic UI construction.
  FourdleGameState() {
    elements.add(makeGridUI(this));
    elements.add(makeHeadUi(this));
    elements.add(makeToolUi(this));
    elements.add(makeWordUi(this));
    elements.add(makeScoreUi(this));
    elements.add(makeMenuUi(this));
    elements.add(makeDailyButton(this));
    elements.add(makeSolveButton(this));
    elements.add(makeCreateButton(this));

    for (int i = 0; i < 16; i++) {
      elements.add(makeCellUi(this, i));
      letters[i] = initialLetters[i].codeUnitAt(0);
    }

    cleanUi();
    //do not load the controller
  }

  @override
  void loadPage() {
    //to ensure integrity and ordering, we should only build the tangle
    //of navigation references after everything has had a chance to init.
    if (tryGetByID("back") == null) {
      elements.add(makeNavigatorButton(this, "back", "←", menuPage));
    }

    //again clean the UI to be safe
    cleanUi();

    //Now load the saved data
    loadData("${getId()}_c").then((x) {
      if (!x) {
        isDaily = true;
        cachedId = getDaySeed();
        pushLetters(GridBuilder.create(cachedId, Dictionary.gen!)[0]);
      }
    });
  }

  @override
  void refreshLayouts() {
    //get the main UI panels that we're interested in
    var menu = tryGetByID("menu");
    var word = tryGetByID("word");
    var grid = tryGetByID("grid");
    if (orientationMode == Layouts.landscape) {
      grid?.hidden = false;
      word?.hidden = menu?.hidden == false;
    } else {
      grid?.hidden = (menu?.hidden == false || word?.hidden == false);
    }

    for (var e in elements) {
      if (e.id.startsWith("cell_")) e.hidden = grid?.hidden == true;
    }
  }

  ///Pushes a grid to the game state. Generally, the new grid should always
  ///be set using this function, rather than by setting the array indices
  ///explicitly
  @override
  void pushLetters(Uint8List newLetters, {Iterable<String>? found}) {
    letters = newLetters;

    //Compute all of the words we can make with the new grid
    computeSolutions();

    //Clear the found things
    if (found != null) {
      setFoundWords(found);
    } else {
      foundWords.clear();
    }

    //now we're going to count how many times each word can be used
    startCounters.fillRange(0, 16, 0);
    usageCounters.fillRange(0, 16, 0);

    //track the letter usages
    for (var wf in getSolutions().entries) {
      //skip words we've already found
      if (foundWords.contains(wf.key)) continue;

      //now read the start index
      int k = (wf.value[0] >> 16) & 0xFFFF;
      //increment the first letter that can start this word
      startCounters[k] += 1;
      //now increment every other letter can build it
      //each word has a list of every way to make it
      //so this covers every possibility
      for (int i = 0; i < wf.value.length; ++i) {
        int n = wf.value[i];
        int f = (n & 0xFFFF);
        for (int j = 0; j < 16; ++j) {
          //16 LSB provides grid visitation
          bool m = (f & (0x1 << j)) != 0;
          if (m) {
            ++usageCounters[j];
          }
        }
      }
    }
    widgetController?.invalidate();
  }

  @override
  void fromSaveString(String s, String key) {
    var m = jsonDecode(s);
    int seed = m["date"];

    //If this is a daily puzzle then it must be reset at day's end
    if (m["daily"] == true) {
      isDaily = true;
      //Check if it's expired
      int n = getDaySeed();
      if (seed != n) {
        cachedId = n;
        var grid = GridBuilder.create(n, Dictionary.gen!);
        letters = grid[0];
        saveData("${getId()}_c");
      } else {
        //Now load the letters etc
        cachedId = n;
        var l = m["grid"];
        for (int i = 0; i < 16; i++) {
          letters[i] = l[i]; //in a perfect world, we wouldn't modify Letters
          //but we can do it here, it should be fine
        }
        //Now set the found words and push the letters
        setFoundWords((m["found"] as List<dynamic>).map((x) => x));
        pushLetters(letters, found: foundWords);
      }
    } else {
      isDaily = false;
      //load the eltters
      var l = m["grid"];
      for (int i = 0; i < 16; i++) {
        letters[i] = l[i];
      }
      //set the found words appropriately
      setFoundWords((m["found"] as List<dynamic>).map((x) => x));
      pushLetters(letters, found: foundWords);
    }
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

  ///Computes the UI layout for the Fourdle game
  static HashMap<String, RectF> computeFourdleLayout(UIPage g, Size s) {
    HashMap<String, RectF> rects = computeGenericLayout(g, s);
    RectF grid = rects["grid"]!;

    double cpad = grid.w / 24;
    //4x + 3p = width -> x = (width - 3p) / 4
    double cellWidth = (grid.w - 3 * cpad) / 4;
    //load the individual grid cells
    for (int i = 0; i < 4; ++i) {
      for (int j = 0; j < 4; ++j) {
        double l = grid.l + j * (cellWidth + cpad);
        double t = grid.t + i * (cellWidth + cpad);
        //print("cell_$i$j: $l, $t");
        rects["cell_$i$j"] =
            RectF.withTag(l, t, l + cellWidth, t + cellWidth, i * 4 + j);
      }
    }
    return rects;
  }
}
