import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  Future<void> init() async {
    // Check and request permission
    if (await _recorder.hasPermission()) {
      // Permission granted
    }
  }

  Future<String> start() async {
    if (!await _recorder.hasPermission()) {
      await Permission.microphone.request();
    }

    final dir = await getApplicationDocumentsDirectory();
    _path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Start recording to file
    await _recorder.start(const RecordConfig(), path: _path!);
    return _path!;
  }

  Future<String?> stop() async {
    if (!await _recorder.isRecording()) return null;
    final path = await _recorder.stop();
    return path;
  }

  Future<bool> get isRunning async => await _recorder.isRecording();

  Future<void> dispose() async {
    _recorder.dispose();
  }
}
