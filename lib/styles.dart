import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:word_puzzles/utils/hexcolor.dart';
import 'package:word_puzzles/utils/logging.dart';
import 'package:flutter/services.dart' show rootBundle;

class Style {
  ///A cached style that can be shared throughout the application. Should be set using
  ///[setStyleFromFile] or [setStyleFromJson].
  static Style? t;

  ///Sets the cached style using the [resourceName] as specified in pubspec.yaml
  static Future<void> setStyleFromFile(String resourceName) async {
    t = await fromFile(resourceName);
    return;
  }

  ///Sets the cached style from the given json string.
  static Future<void> setStyleFromJson(String json) async {
    t = Style.create(json);
    return;
  }

  ///A boolean flag indicating whether this theme has been constructed
  bool isBuilt = false;

  ///The UI scaling multiplier to use when retrieving spacing and thickness values
  double uiScale = 1;

  ///A map of the colors stored by this theme, keyed by string, where the key name matches
  ///the name specified in the .json theme provided.
  Map<String, Color> colorMap = {};

  ///A map of the numerical values stored by this theme, keyed by string, where the key name matches
  ///the name specified in the .json theme provided.
  Map<String, double> varMap = {};

  ///A map of the string values stored by this theme, keyed by string, where the key name matches
  ///the name specified in the .json theme provided.
  Map<String, String> strings = {};

  ///Returns a Future representing a style created from the given filepath.
  ///The filepath is loaded from the services.dar rootBundle, so must also be
  ///specified in pubspec.yaml
  static Future<Style> fromFile(String file) async {
    var s = await rootBundle.loadString(file);
    return Style.create(s);
  }

  ///Constructs a new style from the given json string, which defines the various elements
  ///of the style.
  Style.create(String json) {
    try {
      Map<String, dynamic> m = jsonDecode(json);
      for (String k in m.keys) {
        if (k.startsWith("col")) {
          try {
            //if it's a string/hex
            Color col = Colors.black;
            if (m[k] is String && m[k].startsWith("#")) {
              String c = m[k];
              col = HexColor.fromHex(c);
              colorMap[k] = col;
              //if the value is a number already
            } else if (m[k] is num) {
              int v = (m[k] as double).floor();
              col = Color(v);
              colorMap[k] = col;
            }
          } catch (e) {
            continue;
          }
          //otherwise jam in the double or the string stuffs
        } else if (k.startsWith("d")) {
          if (m[k] is num) {
            varMap[k] = (m[k] as num).toDouble();
          } else {
            varMap[k] = 0.0;
          }
        } else if (k.startsWith("s")) {
          strings[k] = k.toString();
        }
      }
      isBuilt = true;
    } catch (e) {
      logger.wtf("Invalid theme data!");
      isBuilt = false;
    }
  }

  ///Gets a Paint object with style set to Fill, using the color specified by the key,
  ///where [colorKey] refers to a color element stored in the theme.
  ///
  ///[defaultColor] is used when colorKey is not present
  Paint getFill(String colorKey, {Color defaultColor = Colors.black}) {
    return Paint()
      ..color = colorMap[colorKey] ?? defaultColor
      ..style = PaintingStyle.fill;
  }

  ///Gets a Paint object with style set to Stroke, using the color and thickness specified by the keys,
  ///where [colorKey] and [widthKey] refer to color and numerical elements stored in the theme.
  ///
  ///[defaultColor] is used when colorKey is not present, and [defaultWidth] when the widthKey is not.
  Paint getStroke(String widthKey, String colorKey,
      {double defaultWidth = 1, Color defaultColor = Colors.black}) {
    return Paint()
      ..color = colorMap[colorKey] ?? defaultColor
      ..strokeWidth = uiScale * (varMap[widthKey] ?? defaultWidth)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
  }

  ///Constructs a text span from the given string, using [sizeKey] and [colorKey] to obtain size and color
  ///information from the respective fields in this theme. [defaultSize] and [defaultColor] can provide actual
  ///size and color values if the given keys are not present.
  ///
  ///The font style can be specified as a string. Passing "bold" will embolden the text, and "italic" will italicize.
  ///This uses a simple `String.contains` call, so `"italic bold"` will apply both styles.
  TextSpan getText(String text, String sizeKey, String colorKey,
      {String style = "normal",
      double defaultSize = 14,
      Color defaultColor = Colors.black}) {
    return TextSpan(
      text: text,
      style: TextStyle(
          color: colorMap[colorKey] ?? defaultColor,
          fontSize: uiScale * (varMap[sizeKey] ?? defaultSize),
          fontWeight:
              style.contains("bold") ? FontWeight.bold : FontWeight.normal,
          fontStyle:
              style.contains("italic") ? FontStyle.italic : FontStyle.normal),
    );
  }

  ///Retrieves a numerical value from the theme using the given [key], or returns [defaultVal] otherwise.
  double getVal(String key, {double defaultVal = 1}) {
    return varMap[key] ?? defaultVal;
  }

  ///Retrieves a Color value from the theme using the given [key], or returns [defaultColor] otherwise
  Color getCol(String key, {Color defaultColor = Colors.black}) {
    return colorMap[key] ?? defaultColor;
  }
}
