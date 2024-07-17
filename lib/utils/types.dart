import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/uielement.dart';

///A helper interface for things you can click
abstract class Clickable {
  void onClickDown(TapDownDetails details);
  void onClickUp(TapUpDetails details);
  void startDrag(DragStartDetails details);
  void updateDrag(DragUpdateDetails details);
  void endDrag(DragEndDetails details);
}

///A currently unused helper class for things that can
///receive keyboard inputs
abstract class Typeable {}

///A helper interface for things which are paintable
abstract class Paintable {
  void paintPre(Canvas canvas, Size size);
  void paintMid(Canvas canvas, Size size);
  void paintPost(Canvas canvas, Size size);
}

///A helper interface for playing back sounds. Should be overridden by something that,
///ideally, caches sounds and animations for simplicity
abstract class Animator {
  ///notifies the notifiable instance that the render area has changed
  void invalidate();

  ///Callback for playing an animation.
  void startAnimation(double duration, void Function(double x) update,
      void Function(double x) done);

  ///Callback for playing sounds to the user
  void playSound(String sound, {double volume = 0.1});
}

///A parent interface for classes which represent word searching games,
///provides some functionality that will help us access them dynamically
abstract class WordSearcher {
  ///Returns the letters that are used for this state object
  Uint8List getLetters();

  ///Feeds this state object a new collection of letters. This function should accordingly handle
  ///all solution updating logic, and should call [computeSolutions]. If words are provided in [found]
  ///then the implementing class should load them into the list of found words list.
  void pushLetters(Uint8List newLetters, {Iterable<String>? found});

  ///Computes list of all valid solution words for this instance.
  ///
  ///It is expected that the instance will store these words, to be
  ///accordingly returned by getSolutions and getBonusWords.
  void computeSolutions();

  ///Gets the list of all valid solution words for this state object.
  ///Any word in this collection will be counted for points by the Scorebar widget.
  HashMap<String, List<int>> getSolutions();

  ///Gets the list of all valid bonus words for this object. These words may e.g be
  ///unusual words exclusive to the extended dictionary. They will not count for points
  ///when using the Scorebar.
  HashMap<String, List<int>> getBonusWords();

  ///Sets the list of all [words] to this object.
  ///
  ///It is expected that sunsequent calls to [getFoundWords] will return
  ///the values provided in [words].
  void setFoundWords(Iterable<String> words);

  ///Gets the list of all words found in this state object.
  ///
  ///It is undefined whether this function returns the original collection
  ///as a reference, or a copy of the collection. For word setting, it is
  ///recommended to use [setFoundWords]
  Iterable<String> getFoundWords();
}

//some generic helper types for making callbacks more legibile

typedef CallbackDragUpdate = void Function(
    UIElement sender, RectF bounds, DragUpdateDetails value);
typedef CallbackDragStart = void Function(
    UIElement sender, RectF bounds, DragStartDetails value);
typedef CallbackDragEnd = void Function(
    UIElement sender, RectF bounds, DragEndDetails? value);
typedef CallbackTapDown = void Function(
    UIElement sender, RectF bounds, TapDownDetails value);
typedef CallbackTapUp = void Function(
    UIElement sender, RectF bounds, TapUpDetails value);
typedef CallbackPaint = void Function(
    UIElement sender, RectF bounds, Canvas c, Size s);
typedef CallbackScroll = void Function(
    UIElement sender, RectF bounds, double amount);
typedef CallbackInit = void Function(UIElement sender, dynamic state);

enum Layouts { portrait, landscape }
