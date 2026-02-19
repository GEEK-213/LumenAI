import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    // No explicit init needed for audioplayers usually,
    // but we can set context if needed.
  }

  Future<void> play(String path) async {
    if (path.startsWith('http')) {
      await _player.play(UrlSource(path));
    } else {
      await _player.play(DeviceFileSource(path));
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<bool> get isPlaying async => _player.state == PlayerState.playing;

  Future<void> dispose() async {
    await _player.dispose();
  }
}
