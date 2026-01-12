import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _ready = false;
  String? _path;

  Future<void> init() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
    _ready = true;
  }

  Future<String> start() async {
    if (!_ready) throw Exception("Recorder not ready");

    final dir = await getApplicationDocumentsDirectory();
    _path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(toFile: _path);
    return _path!;
  }

  Future<String?> stop() async {
    if (!_ready) return null;
    await _recorder.stopRecorder();
    return _path;
  }

  bool get isRunning => _recorder.isRecording;

  Future<void> dispose() async {
    await _recorder.closeRecorder();
  }
}
