import 'dart:math';
import 'dart:ui';

import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/utils/uielement.dart';

import 'types.dart';

///Handles scrollbars for the UI
class ScrollInsert {
  UIElement parent;
  double scrollY = 0, barTop = -1, barBot = -1;

  CallbackDragStart? fOnStartDrag;
  CallbackScroll? fOnScroll;
  CallbackDragUpdate? fOnUpdateDrag;
  CallbackTapUp? fOnClickUp;
  CallbackDragEnd? fOnEndDrag;
  CallbackPaint? fPaintEnd;

  ///Makes the given element scrollable using the mouse wheel or the draggy finger.
  ///Use getScrollDistance to get the rendering offsets and renderScroller to draw the scrollbar.
  ///
  ///Note that this function is idempotent, but may be disrupted if the element's tag structure
  ///is interfered with
  static void makeScrollable(UIElement element) {
    //set some necessary tag variables
    if (element.tags["scroll"] == null || element.tags["scroll"] is! double) {
      element.tags["scroll"] = 0.0;
    }
    element.tags["scroll_drags"] = false;

    ScrollInsert si;
    if (element.tags["scroller"] == null) {
      element.tags["scroller"] = si = ScrollInsert(element);
    } else {
      return;
    }

    //inject into the scroll event
    si.fOnScroll = element.fOnScroll;
    element.fOnScroll = (sender, bounds, offset) {
      si.fOnScroll?.call(sender, bounds, offset);
      sender.tags["scroll"] += offset;
      UIPage c = sender.stateTag;
      c.widgetController?.invalidate();
    };

    //inject into the drag event
    si.fOnStartDrag = element.fOnStartDrag;
    element.fOnStartDrag = (sender, bounds, details) {
      si.fOnStartDrag?.call(sender, bounds, details);
      if (sender.hidden) return;
      sender.tags["scroll_drags"] = true;
    };

    //inject into the old drag event
    si.fOnUpdateDrag = element.fOnUpdateDrag;
    element.fOnUpdateDrag = (sender, bounds, details) {
      si.fOnUpdateDrag?.call(sender, bounds, details);
      if (sender.hidden) return;
      if (sender.tags["scroll_drags"]) {
        sender.tags["scroll"] -= details.delta.dy;
      }
      UIPage c = sender.stateTag;
      c.widgetController?.invalidate();
    };

    //inject into the old end drag event
    si.fOnEndDrag = element.fOnEndDrag;
    element.fOnEndDrag = (sender, bounds, details) {
      si.fOnEndDrag?.call(sender, bounds, details);
      sender.tags["scroll_drags"] = false;
    };

    //inject into the old click-up event
    si.fOnClickUp = element.fOnClickUp;
    element.fOnClickUp = (sender, bounds, details) {
      si.fOnClickUp?.call(sender, bounds, details);
      sender.tags["scroll_drags"] = false;
      UIPage c = sender.stateTag;
      c.dirty = true;
    };

    //inject into old paint event
    si.fPaintEnd = element.fPaintEnd;
    element.fPaintEnd = (sender, bounds, canvas, size) {
      if (sender.hidden) return;
      si.fPaintEnd?.call(sender, bounds, canvas, size);
      renderScroller(canvas, element);
    };
  }

  ///Gets the scroll offset to apply to the viewing/rendering area
  static double getScrollDistance(UIElement element, double realHeight) {
    if (element.tags.containsKey("scroller")) {
      ScrollInsert si = element.tags["scroller"];
      si.compute(realHeight);
      return si.scrollY;
    }
    return 0;
  }

  ///Renders the scrollbar on the right hand side of the element
  static void renderScroller(Canvas c, UIElement element) {
    if (element.tags.containsKey("scroller")) {
      ScrollInsert si = element.tags["scroller"];
      si.drawRight(c);
    }
  }

  ScrollInsert(this.parent);

  ///computes the vertical scroll based on the expected viewport,
  ///with a full scrollable region of height: [realHeight]
  void compute(double realHeight) {
    //calculate the margins
    UIPage p = parent.stateTag;
    double fT = parent.bounds.t + 7 * p.scale;
    double fB = parent.bounds.b - 7 * p.scale;
    double fH = fB - fT;

    //calculate the scrollable area in terms of the viewport
    realHeight = max(realHeight, parent.bounds.h);
    if (realHeight - parent.bounds.h < 1e-6) {
      scrollY = 0;
      barTop = -1;
      barBot = -1;
      return;
    }

    //get the scroll amount
    double scroll = parent.tags["scroll"];
    double maxScroll = realHeight - parent.bounds.h;
    scroll = max(0, min(maxScroll, scroll)); //can't scroll off the top
    parent.tags["scroll"] = scroll;
    scrollY = scroll;

    //get a preliminary fraction
    //first calculate the size of the bar, cap it so it's always visible
    var barFrac = max(0.1, parent.bounds.h / realHeight);
    var barHeight = parent.bounds.h * barFrac;
    //now we can just place it in such that;
    //1. Scroll = 0   ==> top = 0
    //2. Scroll = max ==> top = bottom - barHeight
    barTop = fT + (scroll / maxScroll) * (fH - barHeight);
    barBot = barTop + barHeight; //simple I guess
  }

  ///Draws the scroller on the right side of the parent widget
  void drawRight(Canvas c, {String colorKey = "colPrimaryFill"}) {
    UIPage u = parent.stateTag;
    if (barBot < 0 || barTop < 0) return;

    var l = parent.bounds.r - 1 * u.scale;
    var t = barTop;
    var r = parent.bounds.r - 5 * u.scale;
    var b = barBot;
    if (l.isNaN || t.isNaN || r.isNaN || b.isNaN) return;

    c.drawRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(1.5 * u.scale)),
        Style.t!.getFill(colorKey));
  }
}
