import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioRecorder _rec = AudioRecorder();

  Future<bool> hasPermission() async {
    return await _rec.hasPermission();
  }

  Future<String?> start() async {
    if (!await hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );
    return filePath;
  }

  Future<String?> stop() async {
    return await _rec.stop();
  }
}
