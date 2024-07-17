import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzles/dictionary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Dictionary.initializeDictionary();

  //Test that the capsFirst works as per the spec
  test("String Utils - Capitalize First", () {
    String word = "word";
    expect(Dictionary.capsFirst(word), equals("Word"));
  });

  ///Ensure that the unique letter counting functions work as they should
  test("String Utils - Extracting Unique Lettering", () {
    //test various forms of words that may make it into the thing....
    var words = ["test", "Test", " test"];
    for (String w in words) {
      //check that the counter works and that nulls are returned as expected
      var validTest = Dictionary.getUniqueLettersFrom(w);
      expect(validTest == null, equals(false));
      expect(validTest!.length, equals(3));
      //it should also contain every letter of the tested word
      for (int i = 0; i < 3; i++) {
        expect(validTest.contains("tes".codeUnitAt(i)), equals(true));
      }
    }
  });

  //Test that the dictionary correctly identifies whole words
  test("Dictionary - Whole Word Validation", () {
    String word = "testing";
    expect(Dictionary.ext!.isValid(word), equals(true));
    expect(Dictionary.gen!.isValid(word), equals(true));
  });

  //Test that the partial word validation works
  test("Dictionary - Partial Word Validation", () {
    String word = "testing";
    for (int i = 1; i < word.length; i++) {
      //check the word piece by piece
      var subWord = word.substring(0, i);
      expect(Dictionary.ext!.isPrependingComponent(subWord), equals(true));
      expect(Dictionary.gen!.isPrependingComponent(subWord), equals(true));
    }
  });

  ///Test that the profanity method returns the expected values
  test("Dictionary - Profanity Detection", () {
    //writing this test hurts almost as much as curating the original list :(
    //But these are the worst of the profanities so yeah
    List<String> profanities = [
      "fuck",
      "cunt",
      "shit",
      "nigger",
      "niggers",
      "bitch",
      "bitches",
      "faggot",
      "tranny",
      "whore",
      "whores",
      "retard",
      "asshole"
    ];
    List<String> someWords = ["test", "this", "list", "of", "words"];

    expect(Dictionary.checkForProfanity(someWords), equals(false));
    expect(Dictionary.checkForProfanity(profanities), equals(true));

    //now insert bad words haphazardly into the somewords list
    //different words each time
    //and make sure that it works consistently
    for (int i = 0; i < profanities.length; ++i) {
      int index = i % someWords.length;
      List<String> testList = List.from(someWords, growable: true);
      testList.insert(index, profanities[i]);
      expect(Dictionary.checkForProfanity(testList), equals(true));
    }
  });

  ///Test that the dictionary can correctly convert a bunch of letters into words
  test("Dictionary - Find Words From Scrambled Letters", () {
    String word = "test";
    var soln = ["test", "sets", "teet", "tees"];
    var nonsoln = "see"; //we specify to requre the T from Test
    var results = Dictionary.ext!.getAllWordsFromText(word, requireIndex: 0);
    //check the normal words
    for (var w in soln) {
      expect(Dictionary.ext!.isValid(w), equals(true));
      expect(results.contains(w), equals(true));
    }
    expect(results.contains(nonsoln), equals(false));

    //this should also return null (bad value)
    expect(Dictionary.getUniqueLettersFrom("t-est"), equals(null));
    //this should also return null (bad value)
    expect(Dictionary.getUniqueLettersFrom("t est"), equals(null));
  });

  test("Dictionary - Identifying 7 Letter Panagrams", () {
    int count = 0;
    for (var w in Dictionary.ext!.panagramWords) {
      var r = Dictionary.getUniqueLettersFrom(w);
      if (r != null && r.length == 7) ++count;
    }
    expect(count, equals(Dictionary.ext!.panagramWords.length));
  });

  //It's vitally important that the dictionaries are correctly unioned
  //Which is to say, the common word dictionary is expected to be a fully
  //contained subset of the bonus word dictionary.
  group("Dictionary Unions", () {
    test("Dictionary - Word Unions", () {
      //select oodles of random words from the gen dictionary
      //as we are also validating WordsFromLetters we can do some neat tricks for this
      List<String> wordGetters = ["apricot", "peanut", "ziplines", "framework"];
      HashSet<String> genWords = HashSet();
      //fill er up boys
      for (String w in wordGetters) {
        genWords.addAll(Dictionary.gen!.getAllWordsFromText(w));
      }
      //now check all of them
      int valid = 0;
      for (String w in genWords) {
        if (Dictionary.ext!.isValid(w)) {
          ++valid;
        }
      }
      //yay
      expect(valid, equals(genWords.length));
    });

    //Test that the long word list is a correct superset
    test("Dictionary - Long Word Union", () {
      HashSet wordset = HashSet.from(Dictionary.ext!.longWords);
      bool has = true;
      //test every word in the long word collection
      for (var w in Dictionary.gen!.longWords) {
        if (!wordset.contains(w)) {
          has = false;
          break;
        }
      }
      expect(has, equals(true));
    });

    //Test that the panagram words are correctly unioned
    test("Dictionary - Panagram Union", () {
      HashSet wordset = HashSet.from(Dictionary.ext!.panagramWords);
      bool has = true;
      for (var w in Dictionary.gen!.panagramWords) {
        if (!wordset.contains(w)) {
          has = false;
          break;
        }
      }
      expect(has, equals(true));
    });
  });
}
