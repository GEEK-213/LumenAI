import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _ready = false;

  Future<void> init() async {
    await _player.openPlayer();
    _ready = true;
  }

  Future<void> play(String path) async {
    if (!_ready) return;

    if (_player.isPlaying) {
      await _player.stopPlayer();
    }

    await _player.startPlayer(fromURI: path, codec: Codec.aacADTS);
  }

  Future<void> stop() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
  }

  bool get isPlaying => _player.isPlaying;

  Future<void> dispose() async {
    await _player.stopPlayer();
  }
}
