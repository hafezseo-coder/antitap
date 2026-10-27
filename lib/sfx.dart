import 'package:audioplayers/audioplayers.dart';

import 'storage.dart';

/// Short sound effects (assets/sfx/*.wav): tap, win, fail, record.
class Sfx {
  static bool enabled = true;
  static final Map<String, AudioPlayer> _players = {};

  static void init() {
    enabled = Storage.sound;
  }

  static void setEnabled(bool v) {
    enabled = v;
    Storage.setSound(v);
  }

  static void play(String name) {
    if (!enabled) return;
    try {
      final p = _players.putIfAbsent(name, () {
        final pl = AudioPlayer();
        pl.setPlayerMode(PlayerMode.lowLatency);
        return pl;
      });
      p.play(AssetSource('sfx/$name.wav')).catchError((_) {});
    } catch (_) {
      // Sound is optional; never break the game because of it.
    }
  }
}
