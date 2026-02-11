import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:green_object/utils/ad_ids.dart';

class AdRectangle extends StatefulWidget {
  final EdgeInsetsGeometry padding;

  const AdRectangle({super.key, this.padding = const EdgeInsets.all(8)});

  @override
  State<AdRectangle> createState() => _AdRectangleState();
}

class _AdRectangleState extends State<AdRectangle> {
  BannerAd? _rectangleAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (AdIds.banner.isEmpty) return;

    final rectangleAd = BannerAd(
      size: AdSize.mediumRectangle, // 300x250 px
      adUnitId: AdIds.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() => _loaded = false);
        },
      ),
    );

    _rectangleAd = rectangleAd..load();
  }

  @override
  void dispose() {
    _rectangleAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _rectangleAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: widget.padding,
        child: SizedBox(
          width: _rectangleAd!.size.width.toDouble(),
          height: _rectangleAd!.size.height.toDouble(),
          child: AdWidget(ad: _rectangleAd!),
        ),
      ),
    );
  }
}
