import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioServices {
  static final AudioServices _instance = AudioServices._internal();
  factory AudioServices() => _instance;
  AudioServices._internal();

  final AudioPlayer player = AudioPlayer();

  Future<void> playAdhan() async {
    try {
      await player.stop();
      await player.setAudioSource(
        AudioSource.asset(
          'assets/voice/azan.mp3',
          tag: MediaItem(
            id: 'adhan',
            title: 'أذان الصلاة',
            artist: 'تنبيه',
          ),
        ),
      );
      await player.play();
    } catch (e) {
      print('Error playing adhan: $e');
    }
  }

  void dispose() {
    player.dispose();
  }
}