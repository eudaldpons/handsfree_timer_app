import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import '../controllers/timer_controller.dart';
import '../../domain/services/audio_service.dart';
import '../providers/audio_service_provider.dart';
import '../providers/theme_provider.dart';
import '../../domain/services/app_rating_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AirPods connection status
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AirPods Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              timerState.isAirPodsConnected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth_disabled,
                              color: timerState.isAirPodsConnected
                                  ? Colors.green
                                  : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              timerState.isAirPodsConnected
                                  ? 'AirPods connected'
                                  : 'AirPods not connected',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Default timer settings
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Default Timer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                            'Default duration when starting with AirPods:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (int seconds in TimerController.gymPresets)
                              ChoiceChip(
                                label: Text(_formatDuration(seconds)),
                                selected:
                                    timerState.defaultTimerDuration == seconds,
                                onSelected: (selected) {
                                  if (selected) {
                                    controller.setDefaultTimerDuration(seconds);
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sound settings
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sound Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Sound'),
                          subtitle:
                              const Text('Play sound when timer completes'),
                          value: timerState.isSoundEnabled,
                          onChanged: (value) {
                            controller.toggleSound(value);
                          },
                        ),
                        if (timerState.isSoundEnabled) ...[
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Select sound:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                AudioPlayerService.availableSounds.length,
                            itemBuilder: (context, index) {
                              final sound =
                                  AudioPlayerService.availableSounds[index];
                              return RadioListTile<String>(
                                title: Text(sound.name),
                                value: sound.id,
                                groupValue: timerState.selectedSound,
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.setSelectedSound(value);
                                    // Play sound preview
                                    ref
                                        .read(audioServiceProvider)
                                        .previewSound(value);
                                  }
                                },
                                secondary: IconButton(
                                  icon: const Icon(Icons.play_circle_outline),
                                  onPressed: () {
                                    // Play sound preview
                                    ref
                                        .read(audioServiceProvider)
                                        .previewSound(sound.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Appearance settings
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Theme'),
                          subtitle: Text(
                              ref.watch(themeModeProvider.notifier).themeName),
                          trailing: IconButton(
                            icon: Icon(
                              ref.watch(themeModeProvider) == ThemeMode.light
                                  ? Icons.light_mode
                                  : ref.watch(themeModeProvider) ==
                                          ThemeMode.dark
                                      ? Icons.dark_mode
                                      : Icons.settings_brightness,
                            ),
                            onPressed: () {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme();
                            },
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Select Theme'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RadioListTile<ThemeMode>(
                                      title: const Text('System'),
                                      value: ThemeMode.system,
                                      groupValue: ref.watch(themeModeProvider),
                                      onChanged: (value) {
                                        if (value != null) {
                                          ref
                                              .read(themeModeProvider.notifier)
                                              .setThemeMode(value);
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                    RadioListTile<ThemeMode>(
                                      title: const Text('Light'),
                                      value: ThemeMode.light,
                                      groupValue: ref.watch(themeModeProvider),
                                      onChanged: (value) {
                                        if (value != null) {
                                          ref
                                              .read(themeModeProvider.notifier)
                                              .setThemeMode(value);
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                    RadioListTile<ThemeMode>(
                                      title: const Text('Dark'),
                                      value: ThemeMode.dark,
                                      groupValue: ref.watch(themeModeProvider),
                                      onChanged: (value) {
                                        if (value != null) {
                                          ref
                                              .read(themeModeProvider.notifier)
                                              .setThemeMode(value);
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Rate App Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Support Us',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: const Text('Rate this App'),
                          subtitle: const Text('Help others discover this app'),
                          onTap: () async {
                            final InAppReview inAppReview =
                                InAppReview.instance;
                            final appRatingService = AppRatingService();

                            if (await inAppReview.isAvailable()) {
                              inAppReview.requestReview();
                              await appRatingService.manuallyRated();
                            } else {
                              inAppReview.openStoreListing(
                                appStoreId:
                                    //TODO: Add your App Store ID
                                    '123456789', // Replace with your App Store ID
                              );
                              await appRatingService.manuallyRated();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds % 60 == 0) {
      return '${seconds ~/ 60} min';
    } else {
      return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
  }
}
