import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_state.freezed.dart';

@freezed
class TimerState with _$TimerState {
  const factory TimerState({
    @Default(0) int hours,
    @Default(0) int minutes,
    @Default(0) int seconds,
    @Default(false) bool isRunning,
    @Default(false) bool isPaused,
    @Default(0) int totalSeconds,
    @Default(0) int remainingSeconds,
    @Default(false) bool isAirPodsConnected,
    @Default(false) bool isAudioPlaying,
    @Default(false) bool isAirPodsControlEnabled,
    @Default(false) bool isVibrationEnabled,
    @Default(true) bool isSoundEnabled,
    @Default(60) int defaultTimerDuration,
    @Default('Harp.mp3') String selectedSound,
  }) = _TimerState;
}
