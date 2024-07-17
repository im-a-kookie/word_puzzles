import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:word_puzzles/fourdle/fourdlestate.dart';
import 'package:word_puzzles/hexel/hexelstate.dart';
import 'package:word_puzzles/menu/menustate.dart';
import 'package:word_puzzles/styles.dart';
import 'package:word_puzzles/utils/utils.dart';
import 'package:word_puzzles/utils/uicontroller.dart';
import 'package:word_puzzles/dictionary.dart';

import 'utils/types.dart';

FourdleGameState? fourPage;
HexelGameState? hexPage;

UIPage curPage = MenuState();
UIPage menuPage = curPage;

Future dictionaryCreation = Dictionary.initializeDictionary().then((value) {
  menuPage.tryGetByID("fourButton")?.tags["target"] =
      fourPage = FourdleGameState();
  menuPage.tryGetByID("fourButton")?.tags["target"] =
      hexPage = HexelGameState();
});

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: curPage.getTitle(),
      home: const MainPageArea(),
    );
  }
}

class MainPageArea extends StatefulWidget {
  const MainPageArea({super.key});
  @override
  State<MainPageArea> createState() => _MainPageState();
}

class _MainPageState extends State<MainPageArea>
    with TickerProviderStateMixin
    implements Animator {
  String initialLetters = "Plz Wait-Loading";

  void runSetups() async {
    Style.setStyleFromFile("assets/themes/default.json");
    setState(() {});
    await dictionaryCreation;
    setState(() {});
    curPage.loadPage();
    setState(() {
      curPage.dirty = true;
    });
  }

  ///Returns true if the given cells are cardinally adjacent (include diagonal)
  bool isAdjacent(int x0, int y0, int x1, int y1) {
    return (x0 - x1).abs() <= 1 && (y0 - y1).abs() <= 1;
  }

  @override
  void initState() {
    super.initState();
    runSetups();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: curPage.getTitle(),
      home: Scaffold(
        // appBar: AppBar(
        //   title: Text(curPage.getTitle()),
        //   backgroundColor:
        //       Style.t?.getCol("colPrimaryFill", defaultColor: Colors.black) ??
        //           Colors.black,
        //   shadowColor: Colors.black,
        //   foregroundColor:
        //       Style.t?.getCol("colPrimaryFill", defaultColor: Colors.white) ??
        //           Colors.white,
        // ),
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Style.t?.getCol("colGradient0",
                      defaultColor: const Color.fromARGB(255, 19, 61, 119)) ??
                  const Color.fromARGB(255, 19, 61, 119),
              Style.t?.getCol("colGradient1",
                      defaultColor: const Color.fromARGB(255, 51, 15, 80)) ??
                  const Color.fromARGB(255, 51, 15, 80),
            ],
          )),
          child: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                double availableWidth = constraints.maxWidth;
                double availableHeight = constraints.maxHeight;
                return SizedBox(
                  width: availableWidth,
                  height: availableHeight,
                  child: buildGrid(
                    availableWidth,
                    availableHeight,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _width = 0;
  double _height = 0;
  UIPage? acter;

  ///Creates a GridView builder that does little more than render all our other stuff
  Widget buildGrid(double width, double height) {
    //Create a grid builder with attached gesture and input capturers
    curPage.widgetController = this;
    acter ??= curPage;
    //catch resizing stuffffff
    if (_width != width || _height != height) {
      curPage.dirty = true;
    }
    _width = width;
    _height = height;

    return Listener(
        onPointerSignal: (event) {
          setState(() {
            if (event is PointerScrollEvent) {
              curPage.widgetController = this;
              curPage.scroll(Size(width, height), event.localPosition,
                  event.scrollDelta.dy * 0.3);
            }
          });
        },
        child: GestureDetector(
          onTapDown: (details) {
            if (acter == curPage) {
              curPage.widgetController = this;
              curPage.tapDown(Size(width, height), details);
            }
            acter = curPage;
          },
          onTapUp: (details) {
            if (acter == curPage) {
              curPage.widgetController = this;
              curPage.tapUp(Size(width, height), details);
            }
            acter = curPage;
          },
          onPanStart: (details) {
            if (acter == curPage) {
              curPage.widgetController = this;
              curPage.panStart(Size(width, height), details);
            }
            acter = curPage;
          },
          onPanUpdate: (details) {
            if (acter == curPage) {
              curPage.widgetController = this;
              curPage.panUpdate(Size(width, height), details);
            }
            acter = curPage;
          },
          onPanEnd: (details) {
            if (acter == curPage) {
              curPage.widgetController = this;
              curPage.panEnd(Size(width, height), details);
            }
            acter = curPage;
          },
          onPanCancel: () => curPage.panEnd(Size(width, height), null),
          //Lastly we just jam in the rendering thing
          child: CustomPaint(
              painter: GamePainter(curPage),
              child: SizedBox(width: width, height: height) //
              ),
          //
        ) //
        ); //
  }

  @override
  void startAnimation(double duration, void Function(double x) update,
      void Function(double x) done) {
    AnimationController a = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (duration * 1000).floor()));

    a.addListener(() => setState(() => update.call(a.value)));

    a.forward(from: 0.0).then((x) {
      a.dispose();
      done.call(0);
      setState(() {});
    });
  }

  int playCounts = 0;

  ///Simple sound playing async function that we use to play sounds
  void playAsync(String s, {double volume = 0.2}) async {
    if (playCounts > 20) {
      Future.delayed(const Duration(milliseconds: 1000))
          .then((x) => playCounts = 0);
      return;
    }
    //rate limit the sounds
    ++playCounts;
    Future.delayed(const Duration(milliseconds: 300))
        .then((x) => playCounts = max(0, playCounts - 1));
    //set up the player to play the sound
    AudioPlayer player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.release);
    player.onPlayerComplete.listen((_) {
      player.dispose();
      playCounts = max(0, playCounts - 1);
    });

    //now blargh
    await player.play(AssetSource(s), volume: volume);
  }

  @override
  void playSound(String sound, {double volume = 0.2}) {
    playAsync(sound, volume: volume);
  }

  @override
  void invalidate() {
    setState(() {
      curPage.dirty = true;
    });
  }
}
