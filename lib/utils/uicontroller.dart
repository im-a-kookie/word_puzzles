import 'dart:collection';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/utils.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/types.dart';
import 'package:word_puzzles/utils/uielement.dart';
import 'package:shared_preferences/shared_preferences.dart';

///Parent class providing main UI control behaviours
abstract class UIPage {
  bool dirty = false;

  ///The UI elements in the game window
  List<UIElement> elements = List.empty(growable: true);

  ///The orientation mode at present
  Layouts orientationMode = Layouts.portrait;

  ///The current scaling multiplier of the GUI
  double scale = 1.0;

  ///The scaling denominator. Generally doesn't need changing.
  double scaleBase = 300;

  ///The animation parent for this element
  Animator? widgetController;

  bool isDaily = true;

  UIPage() {
    pages[getId()] = this;
  }

  String getId();

  String getTitle();

  ///Converts this state tag to a String value, from which it can be
  ///adequately reconstructed by fromSaveString(String s)
  String toSaveString(String key);

  ///Sets the data in this state object based on the given string value.
  void fromSaveString(String s, String key);

  ///Must provide a map of bounding rectangles, keyed to their id.
  ///By keying this ID into the instantiation of the child UI Elements,
  ///they will automatically be assigned into the described layout.
  ///
  ///The return should contain a #landscape or #portrait key, depending on the
  ///determined layout mode, and a #scale rectangle which is used to scale
  ///the UI consistently
  HashMap<String, RectF> getUILayout(Size canvas, dynamic stateObject);

  ///Called when the UI controller is loaded. This is triggered whenever the controller's
  ///page is loaded, so it may be called multiple times. Therefore, the implementation
  ///expects idempotency, or at least, the implementation should NOT assume that this is
  ///only called once.
  void loadPage();

  ///Refreshes the layouts of the child elements in this controller
  void refreshLayouts();

  ///Tries to get the given element by its string id
  UIElement? tryGetByID(String id) {
    for (var e in elements) {
      if (e.id == id) return e;
    }
    return null;
  }

  ///Returns a collection of UI elements that are beneath the given point, [o]
  Iterable<UIElement> getUnder(HashMap<String, RectF> rects, Offset o) =>
      elements.where((x) {
        return !x.hidden &&
            rects.containsKey(x.id) &&
            rects[x.id]!.containsPoint(o);
      });

  ///Returns a collection of UI elements that are beneath the given point, [o]
  Iterable<UIElement> getAndUpdateAtPoint(Size size, Offset o) {
    var rects = getAndRefreshUI(size);
    return elements.where((x) {
      if (x.hidden) return false;
      var r = rects[x.id];
      if (r != null) {
        x.bounds = r;
        return r.containsPoint(o);
      }
      return false;
    });
  }

  ///Provides a collection of bounds for each UI component, refreshing the layout in the progress.
  ///Refer to getUILayout.
  HashMap<String, RectF> getAndRefreshUI(Size size) {
    var rects = getUILayout(size, this);
    var l = orientationMode;
    if (rects.containsKey("#landscape")) orientationMode = Layouts.landscape;
    if (rects.containsKey("#portrait")) orientationMode = Layouts.portrait;

    if (orientationMode != l) {
      refreshLayouts();
    }

    var g = rects["#scale"];
    if (g != null) scale = g.w / scaleBase;
    Style.t?.uiScale = scale;

    return rects;
  }

  ///Called to initialize UI elements. May be called more than once, for example when
  ///the state changes.
  void cleanUi() {
    for (var e in elements) {
      e.stateTag = this;
      e.init?.call(e, this);
    }
    refreshLayouts();
  }

  ///Gets a seed from the given date
  int getDaySeed() {
    var t = DateTime.now();
    return t.day + (t.month << 5) + t.year << 9;
  }

  ///Called when the interface is tapped
  void tapDown(Size canvas, TapDownDetails details) {
    for (var e in getAndUpdateAtPoint(canvas, details.localPosition)) {
      e.onClickDown(details);
    }
  }

  ///called when the tap is released
  void tapUp(Size canvas, TapUpDetails details) {
    var rects = getAndRefreshUI(canvas);
    for (var e in elements) {
      if (e.hidden) continue;

      if (!rects.containsKey(e.id)) continue;

      e.bounds = rects[e.id]!;
      e.onClickUp(details);
    }
  }

  ///Called when the user pans (swipes) over the interface area
  void panStart(Size canvas, DragStartDetails details) {
    for (var e in getAndUpdateAtPoint(canvas, details.localPosition)) {
      e.startDrag(details);
    }
  }

  ///Called when the user ends a pan gesture captured by the interface area
  void panEnd(Size canvas, DragEndDetails? details) {
    var rects = getAndRefreshUI(canvas);
    for (var e in elements) {
      if (e.hidden) continue;
      if (!rects.containsKey(e.id)) continue;
      e.bounds = rects[e.id]!;
      e.endDrag(details);
    }
  }

  ///Called when a pan gesture captured by the interface area, is updated (aka moves)
  void panUpdate(Size canvas, DragUpdateDetails details) {
    for (var e in getAndUpdateAtPoint(canvas, details.localPosition)) {
      e.updateDrag(details);
    }
  }

  ///Called when a scroll action is given to the interface area.
  ///
  ///<b>Note:</b> This will not capture vertical swiping, which should be
  ///managed explicitly by the relevant UI elements
  void scroll(Size canvas, Offset point, double amount) {
    //process each element
    for (var e in getAndUpdateAtPoint(canvas, point)) {
      //set and thingy its scrolling
      if (!e.tags.containsKey("scroll")) e.tags["scroll"] = 0.0;
      e.tags["scroll"] += amount * scale;
    }
  }

  ///Called when the interface area is redrawn. Calls the Start, Middle, and End paint
  ///events, allowing some basic layering logic to be applied, since I'm too lazy to
  ///add depth sorting.
  void paintStart(Canvas c, Size s) {
    if (Style.t == null) return;

    //get the rectangles
    var rects = getAndRefreshUI(s);
    List<UIElement> paintMe = List.empty(growable: true);

    for (var e in elements) {
      if (e.hidden) continue;

      if (rects.containsKey(e.id)) {
        e.bounds = rects[e.id]!;
      } else {
        continue;
      }

      paintMe.add(e);
      if (e.tags.containsKey("hidden") || e.hidden) continue;
      e.paintPre(c, s);
    }

    for (var e in paintMe) {
      if (e.tags.containsKey("hidden") || e.hidden) continue;
      e.paintMid(c, s);
    }

    for (var e in paintMe) {
      if (e.tags.containsKey("hidden") || e.hidden) continue;
      e.paintPost(c, s);
    }
  }

  ///Snapshots the state at the current moment, then asynchronously
  ///saves it to the preferences
  void saveData(String key) {
    aSaveData(key, toSaveString(key));
  }

  ///Saves the state object to the given string key
  Future<void> aSaveData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  ///Loads the state object from the given string key.
  Future<bool> loadData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString(key);
      if (data != null) {
        fromSaveString(data, key);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
