import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRatingService {
  static const String _firstLaunchKey = 'first_launch_timestamp';
  static const String _hasRatedKey = 'has_rated_app';
  static const String _lastPromptKey = 'last_rating_prompt_date';
  static const Duration _initialRatingDelay =
      Duration(days: 1); // Show after 1 day initially

  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> checkAndRequestReview() async {
    try {
      if (!await _shouldShowRating()) {
        return;
      }

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await _markPromptShown();
      }
    } catch (e) {
      debugPrint('Error requesting app review: $e');
    }
  }

  Future<bool> _shouldShowRating() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user has already rated
    final bool hasRated = prefs.getBool(_hasRatedKey) ?? false;
    if (hasRated) {
      return false;
    }

    // Check first launch timestamp
    final int? firstLaunch = prefs.getInt(_firstLaunchKey);
    if (firstLaunch == null) {
      // First time using the app, save timestamp
      await prefs.setInt(
          _firstLaunchKey, DateTime.now().millisecondsSinceEpoch);
      return false;
    }

    // Get the date of the first launch
    final DateTime firstLaunchDate =
        DateTime.fromMillisecondsSinceEpoch(firstLaunch);

    // Check if at least the initial delay has passed since first launch
    final bool initialDelayPassed =
        DateTime.now().difference(firstLaunchDate) >= _initialRatingDelay;

    if (!initialDelayPassed) {
      return false; // Not enough time has passed since first launch
    }

    // After initial delay, check if we've shown the prompt today
    final String today = _getDateString(DateTime.now());
    final String? lastPromptDate = prefs.getString(_lastPromptKey);

    // If we haven't shown the prompt today, show it
    return lastPromptDate != today;
  }

  // Mark that we've shown the prompt today
  Future<void> _markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    final String today = _getDateString(DateTime.now());
    await prefs.setString(_lastPromptKey, today);
  }

  // Mark that the user has rated the app
  Future<void> _markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }

  // Helper to get a date string in YYYY-MM-DD format
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Call this when user manually rates from settings
  Future<void> manuallyRated() async {
    await _markAsRated();
  }
}
