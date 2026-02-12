import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:green_object/services/analytics_service.dart';
import 'ad_ids.dart';

class AdManager {
  AdManager._();

  static final AdManager instance = AdManager._();

  static const Duration _interstitialCooldown = Duration(seconds: 90);
  static const int _gameOverThreshold = 3;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  DateTime? _lastInterstitialShownAt;
  int _gameOverCount = 0;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
    _initialized = true;
  }

  void onGameOver() {
    _gameOverCount++;
    _maybeShowInterstitial();
  }

  bool get isRewardedReady => _rewarded != null;

  Future<bool> showRewarded({
    required VoidCallback onRewardEarned,
    required String rewardType,
  }) async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        onRewardEarned();
        AnalyticsService.instance.logAdWatched('rewarded', rewardType);
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    _rewarded = null;
    return completer.future;
  }

  void _maybeShowInterstitial() {
    if (_interstitial == null) return;
    if (_gameOverCount < _gameOverThreshold) return;

    final now = DateTime.now();
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!) < _interstitialCooldown) {
      return;
    }

    final ad = _interstitial;
    _interstitial = null;
    _gameOverCount = 0;
    _lastInterstitialShownAt = now;

    ad?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );

    ad?.show();
    AnalyticsService.instance.logAdWatched('interstitial', 'game_over');
  }

  void _loadInterstitial() {
    if (AdIds.interstitial.isEmpty) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => _interstitial = null,
      ),
    );
  }

  void _loadRewarded() {
    if (AdIds.rewarded.isEmpty) return;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) => _rewarded = null,
      ),
    );
  }
}
