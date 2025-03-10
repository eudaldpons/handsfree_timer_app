import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../controllers/timer_controller.dart';
import '../../domain/entities/timer_state.dart';

class TimerDisplayWidget extends ConsumerStatefulWidget {
  const TimerDisplayWidget({super.key});

  @override
  ConsumerState<TimerDisplayWidget> createState() => _TimerDisplayWidgetState();
}

class _TimerDisplayWidgetState extends ConsumerState<TimerDisplayWidget> {
  bool _adjustingSeconds = false;

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);

    // Reset to minutes mode when timer starts or stops
    if (timerState.isRunning || timerState.isPaused) {
      _adjustingSeconds = false;
    }

    // Calcular el progreso para el indicador circular
    final progress = timerState.totalSeconds > 0
        ? timerState.remainingSeconds / timerState.totalSeconds
        : 0.0;

    return Center(
      child: LayoutBuilder(builder: (context, constraints) {
        // Use 75% of the available width, but ensure it's not too large
        final size =
            min(constraints.maxWidth * 0.75, constraints.maxHeight * 0.9);

        return SizedBox(
          width: size,
          height: size,
          child: GestureDetector(
            onPanUpdate: timerState.isRunning || timerState.isPaused
                ? null
                : (details) {
                    // Solo permitir ajustes cuando el temporizador no está en ejecución
                    final center = Offset(size / 2, size / 2);
                    final position = details.localPosition;

                    // Calcular el ángulo desde el centro
                    final angle = (atan2(position.dy - center.dy,
                                    position.dx - center.dx) *
                                180 /
                                pi +
                            90) %
                        360;

                    // Determinar si estamos dentro del círculo
                    final distance = (position - center).distance;

                    if (distance <= size / 2) {
                      if (_adjustingSeconds) {
                        // Adjust seconds
                        final seconds = (angle / 360 * 60).round() % 60;
                        controller.setSeconds(seconds);
                      } else {
                        // Adjust minutes
                        final minutes = (angle / 360 * 60).round() % 60;
                        controller.setMinutes(minutes);
                      }
                    }
                  },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Single circle for progress/time setting
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: timerState.isRunning || timerState.isPaused
                        ? progress
                        : _adjustingSeconds
                            ? timerState.seconds / 60
                            : timerState.minutes / 60,
                    strokeWidth: size * 0.05, // Proportional stroke width
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: timerState.isRunning || timerState.isPaused
                        ? _getColorForRemainingTime(timerState.remainingSeconds)
                        : _adjustingSeconds
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),

                // Mostrar tiempo
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!timerState.isRunning && !timerState.isPaused)
                      _buildInteractiveTimeDisplay(
                        context,
                        timerState,
                        size,
                      ),
                    if (timerState.isRunning || timerState.isPaused)
                      Text(
                        _formatTime(
                          timerState.hours,
                          timerState.minutes,
                          timerState.seconds,
                        ),
                        style: TextStyle(
                          fontSize: size * 0.2, // Proportional font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!timerState.isRunning && !timerState.isPaused)
                      Text(
                        _adjustingSeconds
                            ? 'Drag to set seconds'
                            : 'Drag to set minutes',
                        style: TextStyle(
                          fontSize: size * 0.05, // Proportional font size
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInteractiveTimeDisplay(
    BuildContext context,
    TimerState timerState,
    double size,
  ) {
    final minutesStr = timerState.minutes.toString().padLeft(2, '0');
    final secondsStr = timerState.seconds.toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minutes
        GestureDetector(
          onTap: () {
            setState(() {
              _adjustingSeconds = false;
            });
          },
          child: Text(
            minutesStr,
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: !_adjustingSeconds
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ),
        Text(
          ':',
          style: TextStyle(
            fontSize: size * 0.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Seconds
        GestureDetector(
          onTap: () {
            setState(() {
              _adjustingSeconds = true;
            });
          },
          child: Text(
            secondsStr,
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: _adjustingSeconds ? Colors.orange : null,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int hours, int minutes, int seconds) {
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Color _getColorForRemainingTime(int remainingSeconds) {
    if (remainingSeconds <= 3) {
      return Colors.red;
    } else if (remainingSeconds <= 10) {
      return Colors.orange;
    } else if (remainingSeconds <= 30) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
}
