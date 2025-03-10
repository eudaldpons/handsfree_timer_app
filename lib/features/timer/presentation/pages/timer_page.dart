import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/timer_controller.dart';
import '../widgets/timer_display_widget.dart';
import '../widgets/timer_controls_widget.dart';
import '../providers/audio_service_provider.dart';
import 'settings_page.dart';
import 'package:flutter/foundation.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerControllerProvider);
    final audioService = ref.read(audioServiceProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AirPods connection status

            // AirPods control toggle card - always shown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        timerState.isAirPodsConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: timerState.isAirPodsConnected
                            ? (timerState.isAirPodsControlEnabled
                                ? Colors.green
                                : Colors.grey)
                            : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AirPods Control',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              timerState.isAirPodsConnected
                                  ? (timerState.isAirPodsControlEnabled
                                      ? 'Enabled - Use taps to control timer'
                                      : 'Disabled - Touch controls inactive')
                                  : 'AirPods not connected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: timerState.isAirPodsControlEnabled &&
                            timerState.isAirPodsConnected,
                        onChanged: timerState.isAirPodsConnected
                            ? (value) {
                                controller.toggleAirPodsControl(value);
                              }
                            : null,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Debug controls - only visible in debug mode

            // Main timer content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Timer display
                      TimerDisplayWidget(),
                      SizedBox(height: 40),
                      // Timer controls
                      TimerControlsWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
