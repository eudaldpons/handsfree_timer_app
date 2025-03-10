import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/timer_controller.dart';

class TimerControlsWidget extends ConsumerWidget {
  const TimerControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!timerState.isRunning &&
            !timerState.isPaused &&
            timerState.totalSeconds > 0)
          _buildControlButton(
            context,
            label: 'Start',
            color: Colors.green,
            onPressed: () => controller.startTimer(),
            large: true,
          ),
        if (timerState.isRunning)
          _buildControlButton(
            context,
            label: 'Pause',
            color: Colors.orange,
            onPressed: () => controller.pauseTimer(),
            large: true,
          ),
        if (timerState.isPaused)
          _buildControlButton(
            context,
            label: 'Resume',
            color: Colors.green,
            onPressed: () => controller.resumeTimer(),
            large: true,
          ),
        if (timerState.isRunning || timerState.isPaused)
          const SizedBox(width: 20),
        if (timerState.isRunning || timerState.isPaused)
          _buildControlButton(
            context,
            label: 'Stop',
            color: Colors.red,
            onPressed: () => controller.stopTimer(),
            large: false,
          ),
        if (timerState.totalSeconds > 0 &&
            !timerState.isRunning &&
            !timerState.isPaused)
          const SizedBox(width: 20),
        if (timerState.totalSeconds > 0 &&
            !timerState.isRunning &&
            !timerState.isPaused)
          _buildControlButton(
            context,
            label: 'Reset',
            color: Colors.blue,
            onPressed: () => controller.resetTimer(),
          ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool large = false,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: large ? 120 : 100,
          height: large ? 120 : 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.all(large ? 40 : 30),
            shape: const CircleBorder(),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: large ? 18 : 14,
              fontWeight: large ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
