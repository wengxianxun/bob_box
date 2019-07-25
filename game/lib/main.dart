import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:flutter/gestures.dart';
import 'package:flame/flame.dart';

import 'screens/game/game.dart';
import 'screens/game/hats.dart';
import 'screens/title_screen.dart';
import 'screens/hats_screen.dart';
import 'screens/credits_screen.dart';
import 'screens/support_screen.dart';

import 'ui/background.dart';

import 'game_data.dart';
import 'sound_manager.dart';

class Main {
  static Game game;

  // Caching these images so we can use this right away on our UI
  static ui.Image hatsWithBackground;
  static ui.Image hats;
  static ui.Image bob;
  static ui.Image enemies;

  static SoundManager soundManager;
}

class GameWidget extends StatefulWidget {
  @override
  _GameWidgetState createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> with WidgetsBindingObserver {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => FutureBuilder(
              future: Future.wait([
                GameData.getScore(),
                GameData.getCoins(),
              ]),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  int initialBestScore = snapshot.data[0];
                  int initialCoins = snapshot.data[1];

                  return Scaffold(body: TitleScreen(initialBestScore: initialBestScore, initialCoins: initialCoins));
                }

                return Background();
              }
          ),
          '/hats': (context) => FutureBuilder(
              future: Future.wait([
                GameData.getCurrentHat(),
                GameData.getOwnedHats(),
                GameData.getCoins()
              ]),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  Hat currentHat = snapshot.data[0];
                  List<Hat> ownedHats = snapshot.data[1];
                  int currentCoins = snapshot.data[2];

                  return HatsScreen(current: currentHat, owned: ownedHats, currentCoins: currentCoins);
                }

                return Background();
              }

          ),
          '/credits': (context) => CreditsScreen(),
          '/support': (context) => SupportScreen(),
        });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      Main.soundManager.pauseBackgroundMusic();
    }

    if (state == AppLifecycleState.resumed) {
      Main.soundManager.resumeBackgroundMusic();
    }
  }

}

void main() async {
  Main.soundManager = SoundManager();

  bool soundsEnabled = await GameData.isSoundsEnabled();
  await Main.soundManager.init(soundsEnabled);

  // Hats images cache
  Main.hatsWithBackground = await Flame.images.load("hats-background.png");
  Main.hats = await Flame.images.load("hats.png");

  Main.bob = await Flame.images.load("bob.png");
  Main.enemies = await Flame.images.load("enemies.png");

  await Flame.init(fullScreen: true, orientation: DeviceOrientation.portraitUp);

  runApp(GameWidget());

  Main.soundManager.playMenu();

  Flame.util.addGestureRecognizer(TapGestureRecognizer()
    ..onTapDown = (TapDownDetails evt) {
      if (Main.game != null) {
        Main.game.player.stop();
      }
    }
    ..onTapUp = (TapUpDetails evt) {
      if (Main.game != null) {
        Main.game.player.resume();
        Main.game.controller.onTapUp(evt);
      }
    }
  );

  Flame.util.addGestureRecognizer(ImmediateMultiDragGestureRecognizer()
      ..onStart = (Offset) {
        if (Main.game != null) {
          Main.game.player.resume();
        }
        return null;
      }
  );
}
