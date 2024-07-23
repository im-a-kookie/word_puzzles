import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/renderhelpers.dart';
import 'package:word_puzzles/utils/scroller.dart';
import 'package:word_puzzles/utils/types.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/utils/uielement.dart';
import 'package:word_puzzles/dictionary.dart';

UIElement makeWordUi(UIPage game) {
  return UIElement(
    "word", //
    game,
    init: (sender, game) {
      //make the control scrollable
      ScrollInsert.makeScrollable(sender);

      //clear the tags and reset simple values

      sender.tags["game_letters"] = "";
      sender.tags["max_len"] = 16;
      sender.tags["found_easy"] = 0;
      sender.tags["found_hard"] = 0;
      sender.tags["cached_bonus_found"] = "";
      for (int i = 0; i < 30; i++) {
        sender.tags.remove("cached_body_$i");
        sender.tags.remove("found_easy_$i");
      }
    },
    fPaintStart: (sender, bounds, c, s) {
      if (sender.stateTag is! WordSearcher) return;
      if (sender.stateTag is! UIPage) return;

      WordSearcher wS = sender.stateTag;
      UIPage g = sender.stateTag;

      drawRRectButton(c, bounds, g, colorKey: "colPrimaryDark");

      c.save();
      c.clipRRect(RRect.fromLTRBR(bounds.l, bounds.t, bounds.r, bounds.b,
          Radius.circular(12 * g.scale)));

      //find the top position
      double y = 0;
      double height = y + bounds.w / 50;
      double hpad = bounds.w / 20;
      double vpad = bounds.h / 50;

      //we need to measure the area first, so
      //we should cache the painters etc
      List<TextPainter> headPaints = List.empty(growable: true);
      List<TextPainter> bodyPaints = List.empty(growable: true);
      List<String> exts = List.empty(growable: true);

      var solveEasy = wS.getSolutions();
      var solveHard = wS.getBonusWords();

      var foundEasy = wS.getFoundWords().where((x) => solveEasy.containsKey(x));
      var foundHard = wS.getFoundWords().where((x) => solveHard.containsKey(x));

      //Becaus ugh, I didn't really get Flutter when I started this project
      //The UI area doesn't render in a regional way, the entire thing redraws
      //Every. Single. Time.
      //That's still okay since our UI is really very simple
      //But sorting large lists and recalculating text layouts is ehhhhh
      //So instead of rewriting everything, let's just cache it and ignore the problem
      int maxLen = 0;
      bool rebuild = false;

      //If the letters change, then we can imagine that the solution set may also change
      String letters = utf8.decode((g as WordSearcher).getLetters());
      if (letters != sender.tags["game_letters"]) {
        //set the new letters and update the things
        sender.tags["game_letters"] = letters;
        sender.tags["found_hard"] = -1;
        sender.tags["found_easy"] = -1;
        //now figure out the longest words that we have
        Uint16List temp = Uint16List(50);
        for (var w in solveEasy.keys) {
          maxLen = max(maxLen, w.length);
          temp[w.length]++;
        }
        sender.tags["max_len"] = maxLen;
        for (int i = 4; i <= maxLen; i++) {
          sender.tags["soln_cache_$i"] = temp[i];
        }
      }

      //and cache some data about the total stuffs
      if (foundEasy.length != sender.tags["found_easy"] ||
          foundHard.length != sender.tags["found_hard"]) {
        sender.tags["found_easy"] = foundEasy.length;
        sender.tags["found_hard"] = foundHard.length;
        sender.tags["cached_bonus_found"] = "";
        rebuild = true;
      }

      int sections = 0;
      maxLen = sender.tags["max_len"];
      for (int i = 4; i <= maxLen; i++) {
        //get the total number of words
        var solutionCount = sender.tags["soln_cache_$i"];

        //get the number of words found
        int wordsFound = 0;
        if (sender.tags["found_easy_$i"] != null) {
          wordsFound = sender.tags["found_easy_$i"];
        }
        //and make sure we have a cache ready for the body thing
        if (sender.tags["cached_body_$i"] == null) {
          sender.tags["cached_body_$i"] = "";
        }

        //load the string that we cached
        String foundStr = sender.tags["cached_body_$i"];
        //check if we need to rebuild the cache
        if (rebuild) {
          //get all of the found words matching the current length
          var found = foundEasy.where((x) => x.length == i).toList();
          if (found.length != wordsFound) {
            wordsFound = found.length;
            //uuuugh
            found.sort();
            //Now build the body string from the words that we found
            foundStr = "";
            for (String w in found) {
              foundStr += "${Dictionary.capsFirst(w)}, ";
            }
            //trim the comma
            if (foundStr.isNotEmpty) {
              foundStr = foundStr.substring(0, foundStr.length - 2);
            }
            //and store the body string and the counter into the cache
            sender.tags["cached_body_$i"] = foundStr;
            sender.tags["found_easy_$i"] = wordsFound;
          }
        }

        //Now if solutions exist for this number of letters
        if (solutionCount > 0) {
          //make the header thingy
          String header = "$i Letter Words";
          var painter = getPainter(
              header, "dSubheadingSize", "colFontMain", bounds.w,
              style: "bold");
          headPaints.add(painter);
          //and step up the height
          height += painter.height;
          height += vpad;

          int rem = solutionCount - wordsFound;
          exts.add(rem <= 0 ? "Solved!" : "+$rem Left");

          //build the drawing stuff and store it for later
          painter = getPainter(
              foundStr, "dRegularSize", "colFontMain", bounds.w * 0.9);
          bodyPaints.add(painter);
          //and increement
          height += painter.height;
          height += vpad;
          ++sections;
        }
      }

      //now we need to see if
      if (rebuild || sender.tags["cached_bonus_found"] == null) {
        sender.tags["found_hard"] = foundHard.length;
        if (solveHard.isNotEmpty) {
          String bStr = "";
          for (String w in foundHard) {
            bStr += "${Dictionary.capsFirst(w)}, ";
          }
          if (bStr.isNotEmpty) bStr = bStr.substring(0, bStr.length - 2);
          sender.tags["cached_bonus_found"] = bStr;
        }
      }

      if (solveHard.isNotEmpty) {
        String bStr = sender.tags["cached_bonus_found"];

        String header = "Bonus Words";
        var painter = getPainter(
            header, "dSubheadingSize", "colFontMain", bounds.w,
            style: "bold");
        headPaints.add(painter);
        //and step up the height
        height += painter.height;
        height += vpad;

        int rem = solveHard.length - foundHard.length;
        exts.add(rem <= 0 ? "Solved!" : "+$rem Left");

        //build the drawing stuff and store it for later
        painter =
            getPainter(bStr, "dRegularSize", "colFontMain", bounds.w * 0.9);
        bodyPaints.add(painter);
        //and increement
        height += painter.height;
        height += vpad;
      }

      y = -ScrollInsert.getScrollDistance(sender, height);

      //finally, go back and draw all of the text
      for (int i = 0; i < sections; ++i) {
        //we should check the bounds before drawing,
        //but we aren't going to be drawing enough for this to ever matter
        double xx = bounds.l + hpad;
        double yy = bounds.t + y + vpad;

        headPaints[i].paint(c, Offset(xx, yy));
        //get and draw the hint for number of words left

        drawText(
            c,
            exts[i],
            "dSubheadingSize",
            "colFontMainFaded",
            style: "italic",
            RectF(xx + hpad + headPaints[i].width, yy, bounds.r, bounds.b),
            horizontalAlign: TextAlign.left,
            verticalAlign: TextAlignVertical.top);

        //now step down to draw the words
        y += headPaints[i].height;
        y += vpad;
        bodyPaints[i].paint(c, Offset(xx, bounds.t + y + vpad));
        y += bodyPaints[i].height + vpad;
      }

      //now paint the bonus word section

      if (solveHard.isNotEmpty) {
        double xx = bounds.l + hpad;
        double yy = bounds.t + y + vpad;

        headPaints.last.paint(c, Offset(xx, yy));
        //get and draw the hint for number of words left

        drawText(
            c,
            exts.last,
            "dSubheadingSize",
            "colFontMainFaded",
            style: "italic",
            RectF(xx + hpad + headPaints.last.width, yy, bounds.r, bounds.b),
            horizontalAlign: TextAlign.left,
            verticalAlign: TextAlignVertical.top);

        //now step down to draw the words
        y += headPaints.last.height;
        y += vpad;
        bodyPaints.last.paint(c, Offset(xx, bounds.t + y + vpad));
      }

      for (var h in headPaints) {
        h.dispose();
      }
      for (var b in bodyPaints) {
        b.dispose();
      }

      c.restore();
    },
  );
}
