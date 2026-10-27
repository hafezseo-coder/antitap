import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob wrapper.
///
/// IMPORTANT: the IDs below are Google's public TEST IDs. Replace them with
/// your own AdMob unit IDs (and the app ID in AndroidManifest.xml) before
/// publishing, otherwise you earn nothing.
class Ads {
  static const _interstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _rewardedId = 'ca-app-pub-3940256099942544/5224354917';

  /// Show an interstitial every N finished games.
  static const int _every = 3;

  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static int _games = 0;

  static Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  static bool get rewardedReady => _rewarded != null;

  static void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (e) {
          _interstitial = null;
          debugPrint('Interstitial failed: $e');
        },
      ),
    );
  }

  static void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (e) {
          _rewarded = null;
          debugPrint('Rewarded failed: $e');
        },
      ),
    );
  }

  /// Call when the player deliberately taps "Play again". Never mid-round.
  static void maybeShowInterstitial(VoidCallback then) {
    _games++;
    final ad = _interstitial;
    if (_games >= _every && ad != null) {
      _games = 0;
      _interstitial = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _loadInterstitial();
          then();
        },
        onAdFailedToShowFullScreenContent: (a, e) {
          a.dispose();
          _loadInterstitial();
          then();
        },
      );
      ad.show();
    } else {
      then();
    }
  }

  /// Optional "continue after losing". [onReward] runs only if the user
  /// watched enough of the ad.
  static void showRewarded({required VoidCallback onReward}) {
    final ad = _rewarded;
    if (ad == null) return;
    _rewarded = null;
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (earned) onReward();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (a, reward) {
      earned = true;
    });
  }
}
