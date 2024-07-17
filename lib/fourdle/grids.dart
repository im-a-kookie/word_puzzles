import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:word_puzzles/utils/logging.dart';
import 'package:word_puzzles/utils/rng.dart';
import 'package:word_puzzles/dictionary.dart';

class GridBuilder {
  ///The letter grid is here
  List<String> chars = List.filled(16, "");

  ///map the x/y offsets of directional steps (cardinal) for easy use
  static var directions = [
    [-1, -1],
    [0, -1],
    [1, -1],
    [-1, 0],
    [1, 0],
    [-1, 1],
    [0, 1],
    [1, 1],
  ];

  ///A value to use when incrementing the seed within the creation algorithm
  static const int seedIncrement = 1 << 16;

  ///Packs a direction, aka a cyclical grid neighbor reefereence,
  /// into an int value using the following format;
  ///```dart
  ///bits = CCC SS DDD
  ///```
  ///As above, `CCC` = 0-7 grid neighbor reference, `DDD` = initial direction,
  ///and `SS` = scramble bits.
  ///
  ///As the direction is encoded into 5 LSBs, random.nextInt(32) is appropriate.
  static int packDir(int seed, int scramble) {
    return (seed & 0x7) | ((scramble & 0x1) << 3);
  }

  ///Peeks the direction at the current direction flag, modified by the internal rotation.
  ///
  ///Note that the internal rotation is not modified by this function
  static int peekDir(int n) {
    //Progressive rotation can be annoying
    //And I don't want to change stuff much, so...
    //So using the last 2 bits to encode 1/3/5/7,
    //We can scramble it 4 different ways, which seems adequate.
    int dir = 3 + (((n >> 3) & 0x1) << 1);
    int pos = dirCounter(n);
    return ((n & 0x7) + (dir * pos)) & 0x7;
  }

  ///increments the dir at the current direction flag given in [n]
  ///and returns the newly incremented direction flag. Aka:
  ///
  ///```dart
  /// flag = incDir(flag);
  ///```
  static int incDir(int n) {
    return (n & 0xF) | ((((n >> 4) + 1) & 0xF) << 4);
  }

  ///Gets the direction increment from the direction flag given in [n]
  static int dirCounter(int n) {
    return (n >> 4) & 0xF;
  }

  ///A simple helper function that converts the 4x4 grid in [grid] into a
  ///string that can be printed.
  static String stringifyGrid(Uint8List grid) {
    String s = "";
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        s += utf8.decode([grid[i * 4 + j]]);
      }
      s += '\n';
    }
    return s.trim();
  }

  ///Converts a grid into a blob string. This expects 4x4 dimensionality,
  ///and the blob string will not indicate the original dimensionality of
  ///the grid. To retain dimensionality, refer to [stringifyGrid].
  ///
  ///Compatible and consistent with [gridFromBlob].
  static String gridToBlob(Uint8List grid) {
    return utf8.decode(grid);
  }

  ///Converts a 16 character blob into a grid, in standard english LRT reading
  ///direction across the grid. Compatible with [stringifyGrid], but formatting will
  ///be inconsistent. For consistency, see [gridToBlob].
  static Uint8List? gridFromBlob(String s) {
    //we could, theoretically, just use utf8.encode
    //But we should clean the string first
    //In that case, it's easier to clean the string as we go.
    List<int> chars = [];
    s = s.toLowerCase();
    for (int i = 0; i < s.length; i++) {
      int n = s.codeUnitAt(i);
      //make sure that it's in the a-z range
      if (n >= 'a'.codeUnitAt(0) && n <= 'z'.codeUnitAt(0)) {
        chars.add(n);
      }
    }
    if (chars.length != 16) return null;
    return Uint8List.fromList(chars);
  }

  /// Inserts a word randomly into the 4x4 grid given in [grid]. If a string is provided
  ///  in [word], then the algorithm will try to insert it, otherwise if an empty string
  ///  ("") is given, the algorithm will generate a random word in the grid.
  ///
  /// The first letter is placed in the cell given at [cellIndex], and valid words are
  /// selected from [wordList], and the given Randomizer. [r] is used to seed the
  /// algorithm.
  ///
  ///__**Returns**__
  ///
  /// Returns the length of the word inserted. May return 0, indicationg that no word
  /// was placed.
  ///
  /// __**Algorithm Details:**__
  ///
  /// The goal is to generate a an NxN grid of letters (designed for 4x4, untested
  ///  otherwise). We want this grid to contain lots of words for the player to look for.
  ///
  /// An attempt to model the spillage of alphabet cereal provides a simple solve, but the
  /// alphabet-soup distribution, at 26^n, grows so inordinately beyond the dictionary,
  /// even when enlarging it to the max with made-up words like Bowow, Pharisaicalnesses,
  /// and Brunch, that such grids contain extremely few words.
  ///
  /// Noting the appeal of having every letter in the grid being used least once, instead
  /// we can fill the grid by inserting real words systematically until every square is
  /// full. Furthermore, due to patterns in the construction of English words, such grids
  /// are likely to contain many additional words indeed
  static int insertWord(Uint8List grid, String word, int cellIndex,
      Dictionary wordList, RngProvider r,
      {final int gridSize = 4}) {
    final int cellCount = gridSize * gridSize;
    //This LIST will hold the visited cells, in order
    final Uint8List steps = Uint8List(cellCount);
    //This LIST will store the walk directions
    final Uint8List dirs = Uint8List(cellCount);

    //GRID of counters. Used to cycle the letters.
    final Uint8List letters = Uint8List(cellCount);
    //GRID of visitation flags, used to ensure no backtracking
    final Uint8List visited = Uint8List(cellCount);

    //And the step counter
    int pos = 0;

    //First let's randomize the letter arrangement
    final Uint8List randLetterOffset = Uint8List(cellCount);
    for (int i = 0; i < cellCount; ++i) {
      randLetterOffset[i] = r.nextInt(26);
    }
    //and point the thing in a random direction
    dirs[pos] = r.nextInt(16);
    int p = cellIndex;
    //step here, and note the step
    steps[pos] = p;
    visited[p] = 1;
    //and get the root dictionary slice
    Slice current = wordList.root;

    //Now we need to insert the first character
    //Which is either known or random
    if (word.isEmpty) {
      //Cell has stuff already?
      if (grid[p] == 0) {
        //selectify a letter
        for (int j = letters[p]; j < 26; j++) {
          int index = 'a'.codeUnitAt(0) + (j + randLetterOffset[p]) % 26;
          if (current.hasIndex(index)) {
            //we found a usable letter, so let's just stick it here and do our best
            grid[p] = index;
            current = current.children[index]!;
            letters[p] += 1; //prepare the cyclification
            break;
          }
        }
      } else {
        //it's a letter, so absorb it as the head of our word
        if (current.hasIndex(grid[p])) {
          current = current.children[grid[p]]!;
        }
      }
    } else {
      //we are trying to place a given word, which is only possible
      //if and when the grid spot is compatible wirth the letter
      if (grid[p] == 0 || grid[p] == word.codeUnitAt(p)) {
        grid[p] = word.codeUnitAt(0);
      } else {
        return 0;
      }
    }

    //and now iterate until every letter is placed or generated
    while (pos >= 0 && pos < (word.isEmpty ? 16 : word.length)) {
      p = steps[pos];
      //and get the position of x/y
      int x = p ~/ 4;
      int y = p % 4;

      int oldpos = pos;
      for (int i = dirCounter(dirs[pos]); i < 8; i++) {
        //get the current direction for this cell, and then rotate it
        int d = peekDir(dirs[pos]);
        dirs[pos] = incDir(dirs[pos]);
        int inc = dirCounter(dirs[pos]);
        if (inc > 8) break;
        //calculate the ceoo coordinates
        int xx = x + directions[d][0];
        int yy = y + directions[d][1];

        //it has to be within the grid and previously unvisited
        if (xx < 0 || xx >= 4 || yy < 0 || yy >= 4) continue;
        var newCell = 4 * xx + yy; //get the index
        if (visited[newCell] != 0) continue;

        //If it's a new word, we need to behave differently
        if (word.isEmpty) {
          //check if done
          if (pos >= 15) break;
          //check if we have a letter or not
          if (grid[newCell] == 0) {
            //insert a letter randomly
            //iterate through each possible letter?
            for (int j = letters[pos]; j < 26; j++) {
              int index = 'a'.codeUnitAt(0) + (j + randLetterOffset[p]) % 26;
              if (current.hasIndex(index)) {
                //walk forwards
                ++pos;
                steps[pos] = newCell;
                oldpos = pos;
                dirs[pos] = r.nextInt(16);
                i = -1; //reset the counter
                //move the pos as well
                x = xx;
                y = yy;

                //update the grid
                grid[newCell] = index;
                letters[newCell] += 1;
                visited[newCell] = 1;

                //move the slice
                current = current.children[index]!;
                break;
              }
            }
          } //cell empty
          else {
            //There was a letter here, but we need to check if it makes a word
            if (current.hasIndex(grid[newCell])) {
              //it does, so move the slice
              current = current.children[grid[newCell]]!;

              //now increment the position
              ++pos;
              //setting this now will carry it over to the next loop
              oldpos = pos;

              //Add the new step to the stack
              //and set a new direction counter
              steps[pos] = newCell;
              dirs[pos] = r.nextInt(16);
              //reset this stuff too
              i = -1;
              x = xx;
              y = yy;
              //and mark this cell as having been visited
              visited[newCell] = 1;
            } else {
              continue; //unwalk and try the next direction
            }
          }
        } //word empty

        //the word is not empty, so we're using a real word already
        else {
          if (++pos >= word.length) break; //completified

          //we need to check the next letter, but we incremented above,
          //there isn't a super clean solution
          //Strictly speaking, known words probably only get inserted into blank grids
          //So this may be unnecessary, but it's good to allow for this case
          if (grid[newCell] != 0 && grid[newCell] != word.codeUnitAt(pos)) {
            --pos; //unstep
            continue;
          }

          //This means the cell is empty and unvisited, so set it
          grid[newCell] = word.codeUnitAt(pos);
          visited[newCell] = 1;

          //Now we can just step forwards
          steps[pos] = newCell;
          dirs[pos] = r.nextInt(16);

          i = -1; //important, restart the counter
          oldpos = pos;
          x = xx;
          y = yy;
        }
      }

      //If we have not moved, then the above step had nowhere to go
      //So we need to unstep one place and try another direction
      if (pos == oldpos) {
        //before stepping backwards in random word insertion mode
        //We may have found a valid word, in which case let's just use it
        if ((word.isEmpty) && (pos >= 3) && (current.isWord)) return pos + 1;
        //If we inserted a letter in the grid though, then we need to undo it
        int oldCell = steps[pos];
        if (word.isNotEmpty || letters[oldCell] != 0) {
          grid[oldCell] = 0;
          //letters[oldCell] = 0; //we also reset the letter cycler
        }
        visited[oldCell] = 0; //unvisit the cell
        steps[pos] = 0; //empty this step
        //walk back the parent
        if (current.parent != null) current = current.parent!;
        //if we set the grid letter then unset
        pos -= 1;
        //make sure that we don't need a new first letter
        if (pos <= 0) {
          if (word.isNotEmpty) return 0;
          p = cellIndex;
          //now check I guess
          if (grid[p] == 0) {
            //selectify a letter
            for (int j = letters[p]; j < 26; j++) {
              int index = 'a'.codeUnitAt(0) + (j + randLetterOffset[p]) % 26;
              if (current.hasIndex(index)) {
                //we found a usable letter, so let's just stick it here and see?
                grid[p] = index;
                current = current.children[index]!;
                letters[p] += 1;
                break;
              }
            }
          } else {
            return 0;
          }
        }
      }
    }

    //We should unset any grid changes if a valid word wasn't inserted
    while (word.isEmpty && pos < 3) {
      if (pos < 0) return 0; //ran out of letters
      //only erase letters that we put there this time
      if (letters[steps[pos]] != 0) {
        grid[steps[pos]] = 0;
      }
      --pos;
    }
    //and return the length of the insertion
    return pos < 0 ? 0 : pos + 1;
  }

  ///Creates a new game grid from the given [seed]. Identical seeds will produce identical
  ///grids, while a seed value of -1 will produce a random grid.
  ///
  ///Words are inserted from the dictionary in [game]. This should contain a selection of
  ///realistic or common words, whereas [all] may contain rare and unusual words.
  ///
  ///By default, the grid is 4x4 and it can be expected that every letter is used to create
  ///at least one word in the grid. Additionally, the grid is initially filled with a longer word
  ///of 9+ letters, in the vein of "target" word puzzles.
  static List<dynamic> create(int seed, Dictionary game) {
    //Seed a randomizer
    //The inbuilt Random class isn't strictly consistent between builds and platforms,
    //So we use a simple LCG randomizer instead
    RngProvider r;
    if (seed <= 0) {
      seed = Random().nextInt(0x7FFFFFFF);
      r = Rng(seed);
    } else {
      r = Rng(seed ^ 85768528);
    }

    //This is the grid.
    Uint8List grid = Uint8List(16);

    //get a random long word from the desired dictionary
    String w = game.longWords[r.nextInt(game.longWords.length)];
    insertWord(grid, w, r.nextInt(16), game, r);

    //now insert a couple of words randomly?
    for (int i = 0; i < 3; i++) {
      insertWord(grid, "", r.nextInt(16), game, r);
    }

    //now do a last ditch to try and patch any closed holes
    //first let's make a random list of the grid indices
    Uint8List cells = Uint8List(16);
    cells.fillRange(0, 16, 0);
    for (int i = 0; i < 16; i++) {
      cells[i] = i;
    }
    r.shuffle(cells); //random list of indices
    for (int i = 0; i < 16; i++) {
      //if the cell is empty, jam a word in
      if (grid[cells[i]] == 0) {
        insertWord(grid, "", cells[i], game, r);
      }
    }

    //as a last double check, make sure we do actually fill the entire grid
    for (int i = 0; i < 16; i++) {
      if (grid[i] == 0) {
        //this is a bad grid
        logger.wtf(
            "Skipped unfillable grid (seed: $seed)!\n${stringifyGrid(grid)}");
        return create(seed + seedIncrement, game);
      }
    }

    //Now solve the grid using the extended dictionary.
    //This gives us maximum completeness for the solution set
    var soln = getGridSolutions(grid, Dictionary.ext!);
    //eliminate bad words from the solution set by eliminating any words with them
    if (Dictionary.checkForProfanity(soln.keys)) {
      logger.wtf(
          "Skipped puzzle due to profanity (seed: $seed)!\n${stringifyGrid(grid)}");
      //create a new grid with an incremented seed
      return create(seed + seedIncrement, game);
    }

    //prune the solutions to the desired dictionary
    int count = soln.length;
    if (game != Dictionary.ext!) {
      soln.removeWhere((x, y) => !game.isValid(x));
    }

    //and ensure that every letter in the grid is actually used
    if (!checkGridEveryLetterValid(grid, soln)) {
      logger.wtf(
          "Skipped Low Quality Grid (seed: $seed)!\n${stringifyGrid(grid)}");
      return create(seed + seedIncrement, game);
    }

    //We found a good grid yayyyy
    logger.d(
        "Generated grid (seed: $seed)!\n${stringifyGrid(grid)}\n\nSolutions: ${soln.length} (reduced from $count)");

    return [grid, soln];
  }

  ///Checks a given grid of letters (4x4 required) to ensure that every single letter in the grid
  ///is used at least once by the solutions in [solutionSet]. Solutions should be obtained from
  ///[getGridSolutions], as this accounts for the potential for there to be different ways of
  ///creating different words.
  ///
  ///Returns `false` if a letter (or more than one letter) cannot be used to form a valid word.
  static bool checkGridEveryLetterValid(
      Uint8List grid, Map<String, List<int>> solutionSet) {
    //now we're going to count how many times each word can be used
    Uint8List startCounters = Uint8List(16);
    Uint8List usageCounters = Uint8List(16);

    startCounters.fillRange(0, 16, 0);
    usageCounters.fillRange(0, 16, 0);

    //track the letter usages
    for (var wf in solutionSet.entries) {
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
    //now ensure that every letter is used at least once
    for (int i = 0; i < 16; i++) {
      if (usageCounters[i] == 0) {
        return false;
      }
    }
    return true;
  }

  ///Gets a collection of every valid word in [grid] according to the dictionary
  ///specified in [s].
  ///
  ///Returns a dictionary, containing every possible word as the key, and as values:
  ///A list describing every position from which the word can start, and every square
  ///that the word uses. This allows us to tell when a tile is no longer used for any
  ///words in the remaining collection.
  ///
  ///The values in the list are formatted `cells = value & 0xFFFF` and `start = value >> 16`
  ///where start is the 0-16 index of the initial cell.
  ///
  ///The method for this algorithm is pretty much the same as that in [insertWord], but
  ///exhaustively applying it to search every valid run of letters in the grid.
  static HashMap<String, List<int>> getGridSolutions(
      Uint8List grid, Dictionary s) {
    HashMap<String, List<int>> results = HashMap();
    //Each time we visit a square, we need to flag the direction
    Uint8List dirs = Uint8List(16);
    //and we need to remember the current path
    //We could use recursion, but it's a bit cleaner to use our own
    //stack rather than relying on the callstack
    Uint8List path = Uint8List(16);
    int flag = 0;

    //consider every starting square
    for (int i = 0; i < 16; i++) {
      //reset the walk
      dirs.fillRange(0, 16, 0);
      flag = 1 << i;
      int x = i ~/ 4;
      int y = i % 4;
      int pos = 0;
      //set this as the first step
      path[pos] = i;
      Slice current = s.root.children[grid[i]]!;

      //now walk as far as we can and keep spamming until the end (depth first)
      while (pos >= 0) {
        //we ran out of directions at this step, so reverse
        if (dirs[path[pos]] > 7) {
          //unflag that we visited this cell
          flag &= ~(0x1 << path[pos]);
          dirs[path[pos]] = 0;
          pos -= 1;
          //get the old position
          if (pos >= 0) {
            x = path[pos] ~/ 4;
            y = path[pos] % 4;
          }
          //and walk back the dictionary
          if (current.parent != null) {
            current = current.parent!;
          }

          continue;
        }
        //compute the next target place
        var d = directions[dirs[path[pos]]++];
        var xx = x + d[0];
        var yy = y + d[1];
        //make sure that it's within bounds, unvisited, etc
        if (xx >= 0 && xx < 4 && yy >= 0 && yy < 4) {
          var k = xx * 4 + yy;
          if ((flag & (0x1 << k)) != 0) continue;
          if (!current.hasIndex(grid[k])) continue;

          //we've arrived at a viable letter, so walk to it
          //This is where the graphing of the dictionary shows its strength
          //Since we don't need any lookups, just an O(1) traversal.
          current = current.children[grid[k]]!;
          //now step into the square and update the flags and so on
          x = xx;
          y = yy;
          //The flag stores a bitset of every cell that was visited
          //in order to get to this point.
          flag |= (0x1 << k);
          dirs[k] = 0;

          ++pos;
          path[pos] = k;

          //Now check if we can add it to the collection
          if (current.isWord && pos >= 3) {
            String s = current.toString();
            if (!results.containsKey(s)) {
              results[s] = (List.empty(growable: true));
            }
            //now add it to the list of words
            results[s]!.add(flag | (i << 16));
          }
        }
      }
    }
    //done. We now have a list of every word that can be made
    return results;
  }
}
