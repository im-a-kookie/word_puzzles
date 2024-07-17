import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzles/dictionary.dart';
import 'package:word_puzzles/fourdle/grids.dart';

///Tests the word grid generation algorithms
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Dictionary.initializeDictionary();

  String profaneGrid = "auckefghijklmnop";
  String genericGrid = "eotileraimgophxb";
  String yuckyGrid = "eoti\nlera\nimgo\nphxb";

  //Test that grids can be serialized to and from strings
  //Which is important for saving, and also for easily comparing some results in the tests
  test("Grid - Serialization", () {
    var grid1 = GridBuilder.gridFromBlob(genericGrid);
    var grid2 = GridBuilder.gridFromBlob(yuckyGrid);

    expect(grid1 == null, equals(false));
    expect(grid2 == null, equals(false));

    var grid3 = GridBuilder.gridFromBlob(GridBuilder.stringifyGrid(grid1!));

    int a = 0;
    int b = 0;
    int c = 0;
    for (int i = 0; i < 16; i++) {
      if (genericGrid.codeUnitAt(i) == grid1![i]) ++a;
      if (genericGrid.codeUnitAt(i) == grid2![i]) ++b;
      if (genericGrid.codeUnitAt(i) == grid3![i]) ++c;
    }
    expect(a, equals(16));
    expect(b, equals(16));
    expect(c, equals(16));

    //expect it to translate back
    String s1 = GridBuilder.gridToBlob(grid1!);
    String s2 = GridBuilder.gridToBlob(grid2!);
    String s3 = GridBuilder.gridToBlob(grid3!);
    //and expect all three to be consistent
    expect(s1, equals(genericGrid));
    expect(s1, equals(s2));
    expect(s1, equals(s3));
  });

  //Test that the same seed produces the same grid
  //and that different seeds produce different grids
  test("Grid - Seeds Consistently Produce Grids", () {
    //make three grids, two with the same seed, and one with a different seed
    var a = GridBuilder.create(1234, Dictionary.gen!);
    var b = GridBuilder.create(1234, Dictionary.gen!);
    var c = GridBuilder.create(1235, Dictionary.gen!);
    //convert them for easy comparing
    //Grid serialization test asserts that this is okay
    var strA = GridBuilder.gridToBlob(a[0]);
    var strB = GridBuilder.gridToBlob(b[0]);
    var strC = GridBuilder.gridToBlob(c[0]);
    //different seeds should be different
    expect(strA == strB, equals(true));
    expect(strA == strC, equals(false));
  });

  ///Tests the direction incrementer to ensure that every single
  ///seed direction will correctly visit the 8 cells that neighbor
  ///the given cell (diagonal adjacency)
  test("Grid - Random Walk Directions", () {
    int dir = 0;
    List<List<bool>> map = [
      [false, false, false],
      [false, false, false],
      [false, false, false]
    ];

    //A simple helper that resets the grid after each run
    f() {
      for (int a = 0; a < 9; a++) {
        map[a ~/ 3][a % 3] = false;
      }
      map[1][1] = true;
    }

    //a simple helper which checks that the grid has been set
    bool g() {
      for (int a = 0; a < 9; a++) {
        if (!map[a ~/ 3][a % 3]) return false;
      }
      return true;
    }

    //check every direction and jumbler
    for (int i = 0; i < 16; i++) {
      f(); //clean the grid
      int valA = GridBuilder.packDir(i & 0x7, i >> 3);
      expect(valA, equals(i)); //make sure the packer matches the randomizer
      while (GridBuilder.dirCounter(valA) < 8) {
        ///peek and increment
        int dir = GridBuilder.peekDir(valA);
        valA = GridBuilder.incDir(valA);
        //determine which cell to move to
        int x = GridBuilder.directions[dir][0] + 1;
        int y = GridBuilder.directions[dir][1] + 1;
        map[x][y] = true; //flag
      }
      //check that we visited all 8 cardinal neighbors
      expect(g(), equals(true));
    }
  });

  //Tests the grid solver. This test is very light, it simply expects
  //That the solver finds some easy words that we know to be in the solution set
  test("Grid - Solving", () {
    var a = GridBuilder.gridFromBlob(genericGrid);
    var s = GridBuilder.getGridSolutions(a!, Dictionary.ext!);
    expect(s.containsKey("bore"), equals(true));
  });

  //Tests that grids containing profanities are discarded correctly
  test("Grid - Profanity Discarding", () {
    var a = GridBuilder.gridFromBlob(profaneGrid);
    var soln = GridBuilder.getGridSolutions(a!, Dictionary.ext!);
    expect(Dictionary.checkForProfanity(soln.keys), equals(true));
  });

  test("Grid - Contains Long Words", () {
    var a = GridBuilder.create(1726148, Dictionary.gen!);
    int maxLen = 0;
    for (String s in (a[1] as Map).keys) {
      maxLen = max(maxLen, s.length);
    }
    expect(maxLen > 7, equals(true));
  });
}
