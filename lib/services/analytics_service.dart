// import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  // final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logGameStart(String gameName) async {
    // await _analytics.logEvent(
    //   name: 'game_start',
    //   parameters: {'game_name': gameName},
    // );
  }

  Future<void> logGameEnd(
    String gameName,
    int score,
    int durationSeconds,
  ) async {
    // await _analytics.logEvent(
    //   name: 'game_end',
    //   parameters: {
    //     'game_name': gameName,
    //     'score': score,
    //     'duration_seconds': durationSeconds,
    //   },
    // );
  }

  Future<void> logAdWatched(String adType, String rewardType) async {
    // await _analytics.logEvent(
    //   name: 'ad_watched',
    //   parameters: {'ad_type': adType, 'reward_type': rewardType},
    // );
  }

  Future<void> logScreenView(String screenName) async {
    // await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    // await _analytics.logEvent(name: name, parameters: parameters);
  }
}
