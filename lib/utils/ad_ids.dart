import 'dart:io';

import 'package:flutter/foundation.dart';

class AdIds {
  AdIds._();

  // TODO: Replace with your real ad unit ids before release.
  static String get banner {
    if (kIsWeb) return '';
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get interstitial {
    if (kIsWeb) return '';
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  static String get rewarded {
    if (kIsWeb) return '';
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-3940256099942544/1712485313';
  }
}
