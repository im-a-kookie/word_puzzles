import 'dart:async';
import 'dart:collection';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:word_puzzles/utils/logging.dart';

///This class acts as a dictionary. It takes a little moment to construct,
///however once constructed, it lets us analyze words on a per letter basis
class Dictionary {
  ///a dictionary of extended (rarer and weirder) words
  static Dictionary? ext;

  ///A dictionary of generic common words
  static Dictionary? gen;

  //The root slice
  Slice root = Slice(null, -1);
  //Every long word in this helper thing
  List<String> longWords = List.empty(growable: true);

  List<String> panagramWords = List.empty(growable: true);

  static HashSet badWords = HashSet();

  ///Returns a new string where the first letter is capitalized,
  ///and the remainder of the string is lower-cased.
  ///
  ///e.g `capsFirst("word") == "Word";` will return true.
  static String capsFirst(String s) {
    if (s.isEmpty) return s;
    if (s.length == 1) return s.toUpperCase();
    return s.substring(0, 1).toUpperCase() +
        s.substring(1, s.length).toLowerCase();
  }

  ///Determines if the provided word collection contains any
  ///words that are undesirable. Returns `true` if the provided list contains
  ///a word in the banned word list.
  ///
  ///For example, while we don't "ban" slurs and insults and so on, it's
  ///fairly trivial to discard any puzzles that contain them as solutions.
  static bool checkForProfanity(Iterable<String> words) {
    //iterate the provided words and check each one against the nasty word set
    for (var w in words) {
      if (badWords.contains(w)) {
        return true;
      }
    }
    //no bad words
    return false;
  }

  ///Gets a list of the unique letters from the given [word], returning the results as
  ///ASCII character codes from a-z.
  static Uint8List? getUniqueLettersFrom(String word) {
    word = word.toLowerCase().trim();
    int flag = 0; //use a bitflag to do the thing
    List<int> l = List.empty(growable: true);
    for (int i = 0; i < word.length; i++) {
      //get the ascii value reduced to a bit offset
      int val = word.codeUnitAt(i) - 'a'.codeUnitAt(0);
      if (val < 0 || val > 26) return null;
      int mask = 1 << val;
      //only add it if the word is unique
      if ((flag & mask) == 0) l.add(word.codeUnitAt(i));
      flag |= mask;
    }
    return Uint8List.fromList(l);
  }

  ///Initializes the dictionary objects. Initializes both the generic and extended
  ///dictionaries. Generally, the extended dictionary should exlude all words in
  ///the common word dictionary, as the common dictionary builds into it.
  static Future<void> initializeDictionary() async {
    if (ext == null || gen == null) {
      int counterB = 0;

      //prepare
      var t = DateTime.now().millisecondsSinceEpoch;
      ext = Dictionary();
      gen = Dictionary();

      //start loading the data
      Future loadGood =
          rootBundle.loadString("assets/dictionaries/commonWords.txt");
      Future loadExt =
          rootBundle.loadString("assets/dictionaries/extraWords.txt");
      Future loadBad =
          rootBundle.loadString("assets/dictionaries/badWords.txt");

      List<String> goodCache = List.empty(growable: true);
      String w = await loadGood;

      //churn the words into the dictionary
      //and cache them to load into the extended dictionary
      int pos = 0;

      String best = "sdefhsdfh";
      Slice bestSlice = gen!.root;
      int bestCount = 0;
      int bestFlag = 0;

      //move towards the end of the string
      while (pos < w.length) {
        //get the next line
        int n = w.indexOf("\n", pos);
        if (n < 0) n = w.length; //no more lines, so the next break is the end
        String s = w.substring(pos, n).trim(); //trim it out
        if (s.isNotEmpty) {
          //get the list of outputs
          List list;
          //use the cached slice if suitable.
          //This significantly reduces dictionary build time
          //Which is a big deal in prod (smooth = better, quick = better)
          if (s.startsWith(best)) {
            //n=....
            //stores [slice, count] where count gives the number of unique letters
            list = bestSlice.buildSliceStrait(s, best.length,
                prevFlag: bestFlag, prevCount: bestCount);
          } else {
            //we have a new starting word thing, so;
            best = s;
            list = gen!.root.buildSliceStrait(s, 0);
            bestSlice = list[0];
            bestFlag = list[1];
            bestCount = list[2];
          }

          //Create a cache of the words, this lets us merge the generic with extended dictionary quickly
          goodCache.add(s);
          if (s.length >= 9 && s.length <= 13) {
            gen!.longWords.add(s);
          }

          //now check the number of unique letters
          if (list[2] == 7) {
            gen!.panagramWords.add(s);
          }
        }
        pos = n + 1;
      }

      //add gthe cache from above
      //We do this separately since it's a bit easier
      for (String s in goodCache) {
        if (s.startsWith(best)) {
          bestSlice.buildSliceStrait(s, best.length);
        } else {
          best = s;
          bestSlice = ext!.root.buildSliceStrait(s, 0)[0];
        }
      }

      //we can just smoosh the caches into these lists since they're the same
      ext!.longWords.addAll(gen!.longWords);
      ext!.panagramWords.addAll(gen!.panagramWords);

      bestSlice = ext!.root;
      best = "asdgads";
      bestFlag = 0;
      bestCount = 0;

      //and load it into the cache here
      w = await loadExt;
      pos = 0;

      while (pos < w.length) {
        int n = w.indexOf("\n", pos);
        if (n < 0) n = w.length;
        String s = w.substring(pos, n).trim();
        if (s.isNotEmpty) {
          List list;
          //as above, use the cached slice if it's suitable
          if (s.startsWith(best)) {
            list = bestSlice.buildSliceStrait(s, best.length,
                prevFlag: bestFlag, prevCount: bestCount);
          } else {
            //otherwise start over
            best = s;
            list = ext!.root.buildSliceStrait(s, 0);
            bestSlice = list[0];
            bestFlag = list[1];
            bestCount = list[2];
          }
          // ext!.root.buildSliceStrait(s, 0);
          ++counterB;
          if (s.length >= 9 && s.length <= 14) {
            ext!.longWords.add(s);
          }
          //and add the panagram
          if (list[2] == 7) {
            ext!.panagramWords.add(s);
          }
        }
        pos = n + 1;
      }

      w = await loadBad;
      badWords = HashSet.from(
          w.split("\n").map((x) => x.trim()).where((x) => x.length >= 3));

      if (kDebugMode) {
        var time = DateTime.now().millisecondsSinceEpoch - t;
        logger.i("Dictionary Time: ${time}ms, Words: $counterB");
      }
    }
    logger.i("Dictionary loaded!");
  }

  ///Returns true if the dictionary contains any words that start with the word
  ///specified in [word].
  bool isPrependingComponent(String word) {
    Slice r = root;
    //clean it
    word = word.toLowerCase().trim();
    //now traverse the tree
    for (int i = 0; i < word.length; ++i) {
      int c = word[i].codeUnitAt(0);
      if (r.hasIndex(c)) {
        r = r.children[c] ?? r;
      } else {
        return false;
      }
    }
    return true;
  }

  ///Returns true if the given word in [word] is a valid word (and a complete word)
  ///in this dictionary.
  bool isValid(String word) {
    Slice r = root;
    //clean it
    word = word.toLowerCase().trim();
    //now traverse the tree
    for (int i = 0; i < word.length; ++i) {
      int c = word[i].codeUnitAt(0);
      if (r.hasIndex(c)) {
        r = r.children[c] ?? r;
      } else {
        return false;
      }
    }
    return r.isWord;
  }

  ///Gets a list of every word that can be made from the letters in the original [word].
  ///
  ///Generally, this function expects a whole word, but setting [requireIndex] will cause
  ///the return to provide only words that contain the letter at the index specified.
  ///Setting this to -1 (default) will remove letter requirements.
  List<String> getAllWordsFromText(String word, {int requireIndex = -1}) {
    Uint8List l = Uint8List(word.length);
    for (int i = 0; i < word.length; i++) {
      l[i] = word[i].codeUnitAt(0);
    }
    return getAllWordsFrom(l, requireIndex: requireIndex);
  }

  ///Gets a list of all words that can be generated using the input list of letters.
  ///
  ///[letters] should contain a list of letter characters in lower case. Repeat letters
  ///will be ignored, and any letter is permitted to be used as many times as desired.
  ///
  ///If [requireIndex] is set to a positive value, then this function will only return words
  ///which contain the character indexed at the given position in [letters]. Setting this to
  ///-1 will remove letter requirements.
  List<String> getAllWordsFrom(Uint8List letters, {int requireIndex = 0}) {
    //consolidate letters into a simple lookup array
    Uint8List flags = Uint8List(26);
    for (int i = 0; i < letters.length; ++i) {
      flags[letters[i] - 97] = 1;
    }

    List<String> found = List.empty(growable: true);
    Slice current = root;
    Uint8List steps = Uint8List(64);
    int pos = 0;
    int requireCounter = 0;
    int requiredChar = letters[requireIndex % letters.length];

    while (pos >= 0) {
      //if we've finished all the letters here then BLEH
      if (steps[pos] >= 26) {
        pos -= 1;
        if (current.parent != null) {
          if (current.index == requiredChar) --requireCounter;
          current = current.parent!;
        }
        continue;
      }

      //now see if we can move to the next letter
      if (flags[steps[pos]] != 0 &&
          current.hasIndex(steps[pos] + 'a'.codeUnitAt(0))) {
        current = current.children[steps[pos] + 'a'.codeUnitAt(0)]!;
        if (current.index == requiredChar) ++requireCounter;

        ++steps[pos];
        //are we finding a word?
        //if so, then ad the word
        if (current.isWord && (requireIndex < 0 || requireCounter > 0)) {
          found.add(current.toString());
        }
        //now step forwards
        pos += 1;
        steps[pos] = 0;
      } else {
        ++steps[pos];
      }
    }
    return found;
  }
}

///Slices break words down into collections of their child letters. Essentially, the
///dictionary is graphed as a tree.
///
///It takes a moment to build this tree, and it isn't super efficient with memory. But
///the extra 1s of startup time isn't a big deal, but tree traversals are O(1) with respect
///to the dictionary, where even the best binary search is O(log2).
///
///e.g Can "t" be appended to "aga"? Using the tree, we simply walk a->g->a and check if "t"
///is a valid child, inherently validating "aga" in the process. With binary search, on average,
///we have to binary search half of the dictionary with every step. At face value this isn't
///a huge expense, but a 4x4 grid alone has some 1e22 possible states and I don't trust myself
///to stop at simple 4x4 word insertions.
class Slice {
  final Slice? parent;
  final int index;
  String wordHere = "";
  bool isWord = false;
  Map<int, Slice> children = {};

  Slice(this.parent, this.index);

  bool hasIndex(int i) {
    return children.containsKey(i);
  }

  bool hasChar(String s) {
    return hasIndex(s.codeUnitAt(0));
  }

  List buildSliceStrait(String word, var start,
      {int prevFlag = 0, int prevCount = 0}) {
    Slice n = this;
    int flag = prevFlag;
    int count = prevCount;
    while (start < word.length) {
      int val = word.codeUnitAt(start);

      //calculate the letter intersections using the flag as a bitset
      int mask = 1 << (val - 97);
      if ((flag & mask) == 0) ++count;
      flag |= mask;

      var x = n.children[val];
      if (x == null) {
        n.children[val] = x = Slice(n, val);
      }
      n = x;
      ++start;
    }
    n.isWord = true;
    n.wordHere = word;
    return [n, flag, count];
  }

  void buildSlice(String word, var pos) {
    if (pos >= word.length) {
      isWord = true;
      return;
    }

    int n = word.codeUnitAt(pos);
    if (n < 'a'.codeUnitAt(0) || n > 'z'.codeUnitAt(0)) return;
    if (hasIndex(n)) {
      children[n]!.buildSlice(word, pos + 1);
    } else {
      var s = Slice(this, n);
      s.buildSlice(word, pos + 1);
      children[n] = s;
    }
  }

  @override
  String toString() {
    //cache the value on the first call, saves building time early on
    if (wordHere == "" && parent != null) {
      Slice? n = this;
      while (n != null && n.parent != null) {
        wordHere = utf8.decode([n.index]) + wordHere;
        n = n.parent;
      }
    }
    return wordHere;
  }
}
