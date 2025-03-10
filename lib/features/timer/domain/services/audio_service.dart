import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _silentPlayer =
      AudioPlayer(); // For silent background audio
  final AudioSession _session;
  bool _isAudioPlaying = false;
  bool _isBackgroundAudioRunning = false;
  final StreamController<bool> _playingStateController =
      StreamController<bool>.broadcast();

  // List of available gym sounds based on files in assets/sounds folder
  static const List<SoundOption> availableSounds = [
    SoundOption(id: 'Beep.mp3', name: 'Beep'),
    SoundOption(id: 'Cheek_pops.mp3', name: 'Cheek Pops'),
    SoundOption(id: 'Drum.mp3', name: 'Drum'),
    SoundOption(id: 'Evil.mp3', name: 'Evil'),
    SoundOption(id: 'F1_radio_sound.mp3', name: 'F1 Radio Sound'),
    SoundOption(id: 'Harp.mp3', name: 'Harp'),
    SoundOption(id: 'Rifle.mp3', name: 'Rifle'),
  ];

  Stream<bool> get playingStateStream => _playingStateController.stream;
  bool get isAudioPlaying => _isAudioPlaying;
  bool get isBackgroundAudioRunning => _isBackgroundAudioRunning;

  AudioPlayerService(this._session) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Session is already configured in the provider

      // Monitor audio interruptions
      _session.becomingNoisyEventStream.listen((_) {
        _isAudioPlaying = false;
      });

      _session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _isAudioPlaying = false;
        } else {
          _isAudioPlaying = true;
        }
      });

      // Set up media button handling
      _player.processingStateStream.listen((state) {
        debugPrint('Audio processing state: $state');
      });

      // Initialize silent audio for background operation
      await startBackgroundAudio();
    } catch (e) {
      debugPrint('Error in AudioPlayerService._init: $e');
    }
  }

  // Start playing silent audio in the background
  Future<void> startBackgroundAudio() async {
    if (_isBackgroundAudioRunning) return;

    try {
      // Configure audio session for background
      await _session.setActive(true);
      await _session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
      ));

      // Load and play silent audio
      await _silentPlayer.setAsset('assets/sounds/silent.mp3');
      await _silentPlayer.setLoopMode(LoopMode.all);
      await _silentPlayer.setVolume(0.001);
      await _silentPlayer.play();

      _isBackgroundAudioRunning = true;
      debugPrint('Background audio started (no controls)');
    } catch (e) {
      debugPrint('Error starting background audio: $e');
    }
  }

  // Stop background audio
  Future<void> stopBackgroundAudio() async {
    if (!_isBackgroundAudioRunning) return;

    try {
      await _silentPlayer.stop();
      _isBackgroundAudioRunning = false;
      debugPrint('Background audio stopped');
    } catch (e) {
      debugPrint('Error stopping background audio: $e');
    }
  }

  Future<void> playNotificationSound(String soundId) async {
    try {
      // Debug the sound ID being received
      debugPrint('Attempting to play sound: $soundId');

      // Make sure we have a valid sound ID with correct extension
      String assetPath;
      if (soundId.contains('.mp3')) {
        assetPath = 'assets/sounds/$soundId';
      } else {
        assetPath = 'assets/sounds/$soundId.mp3';
      }

      // Stop any currently playing sound
      await _player.stop();

      // Set the audio source and play
      debugPrint('Loading asset: $assetPath');
      await _player.setAsset(assetPath);
      await _player.setVolume(1.0);

      // Start playing and ensure we're in foreground mode
      await _session.setActive(true);

      // Play the sound
      await _player.play();
      _isAudioPlaying = true;

      // Notify listeners
      _playingStateController.add(true);

      // Log for debugging
      debugPrint('Playing notification sound completed setup');
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  // Add this method to keep the app alive in background
  void _startBackgroundAudio() {
    if (!_isBackgroundAudioRunning) {
      try {
        _silentPlayer.setAsset('assets/sounds/silent.mp3');
        _silentPlayer.setLoopMode(LoopMode.one);
        _silentPlayer.play();
        _isBackgroundAudioRunning = true;
      } catch (e) {
        debugPrint('Error starting background audio: $e');
      }
    }
  }

  // Play a preview of the selected sound
  Future<void> previewSound(String soundId) async {
    try {
      await _player.setAsset('assets/sounds/$soundId');
      await _player.setVolume(0.5); // Lower volume for preview
      await _player.play();
    } catch (e) {
      debugPrint('Error previewing sound: $e');
    }
  }

  void dispose() {
    stopBackgroundAudio();
    _silentPlayer.dispose();
    _player.dispose();
    _playingStateController.close();
  }

  // Add this static factory method to your AudioPlayerService class
  static Future<AudioPlayerService> create() async {
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
      androidWillPauseWhenDucked: true,
    ));

    return AudioPlayerService(session);
  }
}

// Class to represent a sound option
class SoundOption {
  final String id;
  final String name;

  const SoundOption({required this.id, required this.name});
}
