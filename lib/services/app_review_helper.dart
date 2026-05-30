import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Helper to request Apple App Store ratings and reviews inside the app (ASO).
class AppReviewHelper {
  static const String _kActionCountKey = 'app_review_action_count';
  static const String _kHasReviewedKey = 'app_review_has_requested';

  /// Records a significant user action (e.g. adding a favorite, viewing maps).
  /// Prompts the user for a rating once they reach 3 actions.
  static Future<void> recordSignificantAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool(_kHasReviewedKey) ?? false;
      if (hasRequested) return;

      int count = prefs.getInt(_kActionCountKey) ?? 0;
      count++;
      await prefs.setInt(_kActionCountKey, count);

      debugPrint('[AppReviewHelper] Significant action recorded: $count/3');

      if (count >= 3) {
        await triggerReview();
      }
    } catch (e) {
      debugPrint('[AppReviewHelper] Error recording action: $e');
    }
  }

  /// Triggers the native App Store rating request dialog instantly (e.g. after submitting a review).
  static Future<void> triggerReview() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kHasReviewedKey, true);
        debugPrint('[AppReviewHelper] Native review dialog displayed!');
      }
    } catch (e) {
      debugPrint('[AppReviewHelper] Error triggering review: $e');
    }
  }
}
