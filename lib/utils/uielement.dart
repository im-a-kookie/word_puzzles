import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:word_puzzles/utils/rect.dart';
import 'package:word_puzzles/utils/types.dart';

///An overarching UI element container. Provides access to some simple UI interactions
///and contains useful data for doing things with.
class UIElement implements Clickable, Paintable {
  HashMap tags = HashMap();
  String id;
  dynamic stateTag;
  RectF bounds = RectF(0, 0, 0, 0);
  bool hidden = false;

  CallbackInit? init;
  CallbackTapDown? fOnClickDown;
  CallbackTapUp? fOnClickUp;
  CallbackDragStart? fOnStartDrag;
  CallbackDragUpdate? fOnUpdateDrag;
  CallbackDragEnd? fOnEndDrag;
  CallbackScroll? fOnScroll;

  CallbackPaint? fPaintStart;
  CallbackPaint? fPaintMid;
  CallbackPaint? fPaintEnd;

  UIElement(this.id, this.stateTag,
      {this.fOnClickDown,
      this.fOnClickUp,
      this.fOnStartDrag,
      this.fOnUpdateDrag,
      this.fOnEndDrag,
      this.fOnScroll,
      this.fPaintStart,
      this.fPaintEnd,
      this.fPaintMid,
      this.init});

  @override
  void endDrag(DragEndDetails? details) {
    fOnEndDrag?.call(this, bounds, details);
  }

  @override
  void onClickDown(TapDownDetails details) {
    fOnClickDown?.call(this, bounds, details);
  }

  @override
  void onClickUp(TapUpDetails details) {
    fOnClickUp?.call(this, bounds, details);
  }

  @override
  void startDrag(DragStartDetails details) {
    fOnStartDrag?.call(this, bounds, details);
  }

  @override
  void updateDrag(DragUpdateDetails details) {
    fOnUpdateDrag?.call(this, bounds, details);
  }

  @override
  void paintMid(Canvas canvas, Size size) {
    fPaintMid?.call(this, bounds, canvas, size);
  }

  @override
  void paintPost(Canvas canvas, Size size) {
    fPaintEnd?.call(this, bounds, canvas, size);
  }

  @override
  void paintPre(Canvas canvas, Size size) {
    fPaintStart?.call(this, bounds, canvas, size);
  }
}
