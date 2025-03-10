import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../domain/entities/timer_state.dart';
import '../../domain/services/airpods_service.dart';
import '../../domain/services/audio_service.dart';
import '../../presentation/providers/audio_service_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final timerControllerProvider =
    StateNotifierProvider<TimerController, TimerState>((ref) {
  return GetIt.I<TimerController>(param1: ref);
});

class TimerController extends StateNotifier<TimerState> {
  Timer? _timer;
  late AirPodsService _airPodsService;
  AudioPlayerService? _audioService;
  final Ref ref;
  static const String _defaultDurationKey = 'default_timer_duration';

  // Presets comunes para gimnasio (en segundos)
  static const List<int> gymPresets = [30, 45, 60, 90, 120, 180, 300];

  TimerController(this.ref) : super(const TimerState()) {
    _initServices();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultDuration = prefs.getInt(_defaultDurationKey) ??
          60; // Default to 60 seconds if not set

      // Update the default duration in state
      state = state.copyWith(defaultTimerDuration: defaultDuration);

      // Also set the timer to show this duration initially
      setTotalSeconds(defaultDuration);
    } catch (e) {
      debugPrint('Error loading saved settings: $e');
    }
  }

  Future<void> _initServices() async {
    try {
      // Inicializar servicios
      _airPodsService = AirPodsService();

      // Safely get the audio service
      try {
        _audioService = ref.read(audioServiceProvider);
      } catch (e) {
        debugPrint('Error initializing audio service: $e');
        // We'll handle null _audioService in methods that use it
      }

      // Escuchar eventos de AirPods
      _airPodsService.connectionStream.listen((connected) {
        state = state.copyWith(isAirPodsConnected: connected);
      });

      _airPodsService.eventStream.listen((event) {
        if (state.isAirPodsControlEnabled) {
          _handleAirPodsEvent(event);
        }
      });

      // Escuchar estado de reproducción de audio if available
      _audioService?.playingStateStream.listen((playing) {
        state = state.copyWith(isAudioPlaying: playing);
      });
    } catch (e) {
      debugPrint('Error in _initServices: $e');
    }
  }

  void _handleAirPodsEvent(AirPodsEvent event) {
    switch (event) {
      case AirPodsEvent.singleTap:
        // Iniciar/pausar temporizador con un solo toque
        if (!state.isRunning && !state.isPaused) {
          if (state.totalSeconds > 0) {
            startTimer();
          } else {
            // Si no hay tiempo configurado, usar el predeterminado
            setTotalSeconds(state.defaultTimerDuration);
            startTimer();
          }
        } else if (state.isRunning) {
          pauseTimer();
        } else if (state.isPaused) {
          resumeTimer();
        }
        break;
      case AirPodsEvent.doubleTap:
        // Detener temporizador con doble toque
        if (state.isRunning || state.isPaused) {
          stopTimer();
        }
        break;
      case AirPodsEvent.longPress:
        // Reiniciar temporizador con pulsación larga
        resetTimer();
        break;
    }
  }

  // Simular un evento de AirPods (para pruebas)
  void simulateAirPodsEvent(AirPodsEvent event) {
    _airPodsService.simulateAirPodsEvent(event);
  }

  void toggleAirPodsControl(bool enabled) {
    state = state.copyWith(isAirPodsControlEnabled: enabled);

    // Start or stop background audio based on AirPods control state
    final audioService = ref.read(audioServiceProvider);
    if (enabled) {
      // Start background audio when AirPods control is enabled
      debugPrint('AirPods control enabled - starting background audio');
      audioService.startBackgroundAudio();
    } else if (!enabled) {
      // Optionally stop background audio when AirPods control is disabled
      // Only if timer is not running
      if (!state.isRunning) {
        debugPrint('AirPods control disabled - stopping background audio');
        audioService.stopBackgroundAudio();
      } else {
        debugPrint(
            'AirPods control disabled but timer running - keeping background audio');
      }
    }
  }

  void toggleVibration(bool enabled) {
    state = state.copyWith(isVibrationEnabled: enabled);
  }

  void toggleSound(bool enabled) {
    state = state.copyWith(isSoundEnabled: enabled);
  }

  Future<void> setDefaultTimerDuration(int seconds) async {
    state = state.copyWith(defaultTimerDuration: seconds);

    // Save the default duration to persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_defaultDurationKey, seconds);
    } catch (e) {
      debugPrint('Error saving default timer duration: $e');
    }

    // If timer is not running, update the display to show the new default
    if (!state.isRunning && !state.isPaused) {
      setTotalSeconds(seconds);
    }
  }

  void setHours(int hours) {
    if (hours >= 0 && hours <= 23) {
      state = state.copyWith(hours: hours);
      _updateTotalSeconds();
    }
  }

  void setMinutes(int minutes) {
    if (minutes >= 0 && minutes <= 59) {
      state = state.copyWith(minutes: minutes);
      _updateTotalSeconds();
    }
  }

  void setSeconds(int seconds) {
    if (seconds >= 0 && seconds <= 59) {
      state = state.copyWith(seconds: seconds);
      _updateTotalSeconds();
    }
  }

  void setTotalSeconds(int totalSeconds) {
    if (totalSeconds < 0) return;

    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    state = state.copyWith(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      totalSeconds: totalSeconds,
      remainingSeconds: totalSeconds,
    );
  }

  void _updateTotalSeconds() {
    final int totalSeconds =
        state.hours * 3600 + state.minutes * 60 + state.seconds;
    state = state.copyWith(
      totalSeconds: totalSeconds,
      remainingSeconds: totalSeconds,
    );
  }

  void startTimer() {
    if (state.totalSeconds <= 0) return;

    state = state.copyWith(isRunning: true, isPaused: false);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 0) {
        _onTimerComplete();
        return;
      }

      final int remainingSeconds = state.remainingSeconds - 1;
      final int hours = remainingSeconds ~/ 3600;
      final int minutes = (remainingSeconds % 3600) ~/ 60;
      final int seconds = remainingSeconds % 60;

      state = state.copyWith(
        remainingSeconds: remainingSeconds,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      );
    });
  }

  void _onTimerComplete() {
    stopTimer();

    // Debug log
    debugPrint(
        'Timer completed, sound enabled: ${state.isSoundEnabled}, sound: ${state.selectedSound}');

    // Reproducir sonido de notificación si está habilitado
    if (state.isSoundEnabled && _audioService != null) {
      debugPrint('Playing sound: ${state.selectedSound}');
      _audioService!.playNotificationSound(state.selectedSound);
    } else {
      debugPrint(
          'Sound not played: audioService is ${_audioService == null ? 'null' : 'available'}');
    }

    // Vibrar si está habilitado
    if (state.isVibrationEnabled) {
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
    }
  }

  void pauseTimer() {
    if (!state.isRunning) return;

    _timer?.cancel();
    state = state.copyWith(isRunning: false, isPaused: true);
  }

  void resumeTimer() {
    if (!state.isPaused) return;

    startTimer();
  }

  void stopTimer() {
    _timer?.cancel();

    // Restaurar valores originales
    final int hours = state.totalSeconds ~/ 3600;
    final int minutes = (state.totalSeconds % 3600) ~/ 60;
    final int seconds = state.totalSeconds % 60;

    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      remainingSeconds: state.totalSeconds,
    );
  }

  void resetTimer() {
    _timer?.cancel();
    state = const TimerState();
  }

  void addSeconds(int secondsToAdd) {
    if (!state.isRunning && !state.isPaused) {
      final newTotalSeconds = state.totalSeconds + secondsToAdd;
      setTotalSeconds(newTotalSeconds);
    } else {
      final newRemainingSeconds = state.remainingSeconds + secondsToAdd;
      if (newRemainingSeconds <= 0) {
        stopTimer();
        return;
      }

      final int hours = newRemainingSeconds ~/ 3600;
      final int minutes = (newRemainingSeconds % 3600) ~/ 60;
      final int seconds = newRemainingSeconds % 60;

      state = state.copyWith(
        remainingSeconds: newRemainingSeconds,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      );
    }
  }

  void setSelectedSound(String soundId) {
    state = state.copyWith(selectedSound: soundId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _airPodsService.dispose();
    _audioService?.dispose();
    super.dispose();
  }
}
