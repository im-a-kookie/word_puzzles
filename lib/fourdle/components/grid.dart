import 'dart:convert';
import 'dart:ui';

import 'package:word_puzzles/fourdle/fourdlestate.dart';
import 'package:word_puzzles/utils/uielement.dart';

import '../../styles.dart';

///Returns true if the given cells are cardinally adjacent (include diagonal)
bool isAdjacent(int x0, int y0, int x1, int y1) {
  return (x0 - x1).abs() <= 1 && (y0 - y1).abs() <= 1;
}

UIElement makeGridUI(FourdleGameState game) {
  return UIElement(
    "grid", //
    game, //
    fOnClickDown: (sender, bounds, details) {
      FourdleGameState g = sender.stateTag;

      g.draggedCells.clear();
      //This doesn't give perfect alignment, but it's good enough
      double boxSize = bounds.w / 4;

      //grab the hover point and correct to the box
      double hx = (details.localPosition.dx - bounds.l).floorToDouble();
      double hy = (details.localPosition.dy - bounds.t).floorToDouble();
      //and round down to the cell coords
      int x = (hx / boxSize).floor();
      int y = (hy / boxSize).floor();
      if (x >= 0 && x <= 3 && y >= 0 && y <= 3) {
        int k = 4 * y + x;
        if (!g.draggedCells.contains(k)) {
          g.draggedCells.add(k);

          g.widgetController?.playSound("audio/click1.mp3",
              volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);
        }
      }
      g.dirty = true;
      g.widgetController?.invalidate();
    },
    fOnStartDrag: (sender, bounds, value) {
      FourdleGameState g = sender.stateTag;

      //This doesn't give perfect alignment, but it's good enough
      double boxSize = bounds.w / 4;

      //grab the hover point and correct to the box
      double hx = (value.localPosition.dx - bounds.l).floorToDouble();
      double hy = (value.localPosition.dy - bounds.t).floorToDouble();
      //and round down to the cell coords
      int x = (hx / boxSize).floor();
      int y = (hy / boxSize).floor();
      if (x >= 0 && x <= 3 && y >= 0 && y <= 3) {
        int k = 4 * y + x;
        if (!g.draggedCells.contains(k)) {
          g.draggedCells.add(k);
          g.dirty = true;
          g.widgetController?.playSound("audio/click1.mp3",
              volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);
        }
      }
      g.dirty = true;
      g.widgetController?.invalidate();
    },
    //The player unclicked
    fOnClickUp: (sender, bounds, details) {
      //just unclick bro
      FourdleGameState g = sender.stateTag;
      g.draggedCells.clear();
      g.dirty = true;
      g.widgetController?.invalidate();
    },
    //The player is dragging over the grid, so we need to handle it
    fOnUpdateDrag: (sender, bounds, details) {
      FourdleGameState g = sender.stateTag;

      double boxSize = bounds.w / 4;
      var cpad = bounds.w / 24.0;
      var cellWidth = (bounds.w / 4) - (3 * cpad / 4);

      //grab the hover point and correct to the box
      double hx = (details.localPosition.dx - bounds.l).floorToDouble();
      double hy = (details.localPosition.dy - bounds.t).floorToDouble();
      //and round down to the cell coords
      int x = (hx / boxSize).floor();
      int y = (hy / boxSize).floor();

      //for diagonal movement, we need to constrain the hitbox
      //distance checking does an adequate job
      double cx = x * (cellWidth + cpad) + (cellWidth / 2) - hx;
      double cy = y * (cellWidth + cpad) + (cellWidth / 2) - hy;

      //so now we can use the radius yay
      if (cx * cx + cy * cy < (0.9 * boxSize * boxSize / 4)) {
        if (x >= 0 && x <= 3 && y >= 0 && y <= 3) {
          int k = 4 * y + x;
          if (!g.draggedCells.contains(k)) {
            //if there are cells, we can only drag to a neighbor
            if (g.draggedCells.isNotEmpty) {
              int ox = g.draggedCells.last % 4;
              int oy = g.draggedCells.last ~/ 4;
              if (isAdjacent(x, y, ox, oy)) {
                g.draggedCells.add(k);
                g.dirty = true;
                g.widgetController?.invalidate();
                g.widgetController?.playSound("audio/click1.mp3",
                    volume: Style.t?.getVal("dClickVolume", defaultVal: 0.3) ??
                        0.3);
              }
            } else {
              g.draggedCells.add(k);
              g.dirty = true;
              g.widgetController?.invalidate();
              g.widgetController?.playSound("audio/click1.mp3",
                  volume:
                      Style.t?.getVal("dClickVolume", defaultVal: 0.3) ?? 0.3);
            }
            //if we dragged backwards, then we can undrag instead
          } else if (g.draggedCells.length >= 2 &&
              g.draggedCells[g.draggedCells.length - 2] == k) {
            g.draggedCells.removeLast();
            g.dirty = true;
            g.widgetController?.invalidate();
          }
        }
      }
    },
    //When the player stops dragging, we need to clear their pressings
    fOnEndDrag: (sender, bounds, details) {
      FourdleGameState g = sender.stateTag;
      if (g.draggedCells.isEmpty) return;
      g.dirty = true;
      g.widgetController?.invalidate();
      var h = g.tryGetByID("head");

      //let's add up the letters for the word
      String s = "";
      for (int i = 0; i < g.draggedCells.length; i++) {
        s += utf8.decode([g.letters[g.draggedCells[i]]]);
      }
      //and see if it is in fact a real word
      g.messageText = s;
      //check that the word is good
      if (s.length >= 4) {
        bool easy = g.availableWords.containsKey(s);
        bool hard = g.bonusWords.containsKey(s);
        if (easy || hard) {
          if (g.foundWords.add(s)) {
            //flag that we took a word from this place
            var l = easy ? g.availableWords[s]! : g.bonusWords[s]!;
            //only decrement the "easy" or general words from the letter count thing
            if (easy) {
              g.startCounters[(l[0] >> 16) & 0xF] -= 1;
              for (int i = 0; i < l.length; ++i) {
                for (int j = 0; j < 16; j++) {
                  if ((l[i] & (0x1 << j)) != 0) {
                    g.usageCounters[j]--;
                  }
                }
              }
            }

            //it's a real word, so make it flash green
            g.greenCells.addAll(g.draggedCells);
            g.messageText = "";
            //make the green go
            g.widgetController
                ?.startAnimation(0.5, (x) {}, (x) => g.greenCells.clear());

            if (h != null) {
              if (easy) {
                g.messageText = "Nice! +${s.length}";
              } else {
                g.messageText = "Bonus Word!";
              }

              g.widgetController?.playSound("audio/ding.mp3",
                  volume:
                      Style.t?.getVal("dDingVolume", defaultVal: 0.3) ?? 0.3);

              g.widgetController?.startAnimation(0.5, (x) {
                h.tags["jiggle"] = x;
              }, (x) {
                //clear the jiggle and blank the attempted word
                h.tags.remove("jiggle");
                g.messageText = "";
              });

              //we modified the letters, so
              //save the changes
              g.saveData("${g.getId()}_c");
              if (g.isDaily) g.saveData("${g.getId()}_d");
            }
          } else {
            g.dimCells.addAll(g.draggedCells);
            g.widgetController
                ?.startAnimation(0.5, (x) {}, (x) => g.dimCells.clear());
            g.widgetController?.playSound("audio/pop.mp3",
                volume: Style.t?.getVal("dBonkVolume", defaultVal: 0.3) ?? 0.3);
            g.messageText = "Already Found!";
            g.widgetController?.startAnimation(0.5, (x) {
              h?.tags["jiggle"] = x;
            }, (x) {
              //clear the jiggle and blank the attempted word
              h?.tags.remove("jiggle");
              g.messageText = "";
            });
          }
        } else {
          g.dimCells.addAll(g.draggedCells);
          g.widgetController
              ?.startAnimation(0.5, (x) {}, (x) => g.dimCells.clear());
          g.widgetController?.playSound("audio/bonk.mp3",
              volume: Style.t?.getVal("dBonkVolume", defaultVal: 0.3) ?? 0.3);
          g.messageText = "Not Found!";
          g.widgetController?.startAnimation(0.5, (x) {
            h?.tags["jiggle"] = x;
          }, (x) {
            //clear the jiggle and blank the attempted word
            h?.tags.remove("jiggle");
            g.messageText = "";
          });
        }
      } else {
        g.dimCells.addAll(g.draggedCells);
        g.widgetController
            ?.startAnimation(0.5, (x) {}, (x) => g.dimCells.clear());
        g.widgetController?.playSound("audio/bonk.mp3",
            volume: Style.t?.getVal("dBonkVolume", defaultVal: 0.3) ?? 0.3);
        g.messageText = "Too Short!";
        g.widgetController?.startAnimation(0.5, (x) {
          h?.tags["jiggle"] = x;
        }, (x) {
          //clear the jiggle and blank the attempted word
          h?.tags.remove("jiggle");
          g.messageText = "";
        });
      }

      //and unset some things
      g.draggedCells.clear();
    },
    //The grid itself will mostly only draw the overlay of dragging
    //It must biset tiles and letters, so the middle paint event is best
    fPaintMid: (sender, bounds, c, s) {
      FourdleGameState g = sender.stateTag;

      //the coords are accessible;
      if (g.draggedCells.isNotEmpty) {
        var cpad = bounds.w / 24.0;
        var cellWidth = (bounds.w / 4) - (3 * cpad / 4);
        //get the line painter
        Paint p = Style.t!.getStroke("dSelectorRadius", "colHighlight");
        //now grab the actual points
        List<Offset> points = List.empty(growable: true);
        for (int i = 0; i < g.draggedCells.length; ++i) {
          int cx = g.draggedCells[i] % 4;
          int cy = g.draggedCells[i] ~/ 4;

          double x = bounds.l + cx * (cellWidth + cpad) + cellWidth / 2;
          double y = bounds.t + cy * (cellWidth + cpad) + cellWidth / 2;

          c.drawCircle(
              Offset(x, y),
              Style.t!.getVal("dSelectorRadiusElbow", defaultVal: 40) *
                  0.5 *
                  g.scale,
              Style.t!.getFill("colHighlight"));

          points.add(Offset(x, y));
        }
        c.drawPoints(PointMode.polygon, points, p);
      }
    },
  );
}
