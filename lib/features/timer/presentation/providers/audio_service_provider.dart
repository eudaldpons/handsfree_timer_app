import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../../domain/services/audio_service.dart';
import 'package:get_it/get_it.dart';

// Provider for AudioSession
final audioSessionProvider = FutureProvider<AudioSession>((ref) async {
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ));
    return session;
  } catch (e) {
    debugPrint('Error initializing AudioSession: $e');
    rethrow;
  }
});

// Provider for AudioPlayerService
final audioServiceProvider = Provider<AudioPlayerService>((ref) {
  try {
    final audioService = GetIt.instance<AudioPlayerService>();
    return audioService;
  } catch (e) {
    throw Exception('AudioPlayerService not registered in GetIt: $e');
  }
});
