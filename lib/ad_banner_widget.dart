import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: ApiConstants.bannerAdUnitId, 
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded && _bannerAd != null
        ? SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          )
        : const SizedBox();
  }
}

class ApiConstants {
  static const bool isDevelopment = true;

  // AdMob設定
  static String get bannerAdUnitId {
    if (isDevelopment) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-9967376970047175/6318511278';  // Androidテスト用
      } else if (Platform.isIOS) {
        return 'ca-app-pub-9967376970047175/1394746831';  // iOSテスト用
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-9967376970047175/6318511278';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-9967376970047175/1394746831';
      }
    }
    throw UnsupportedError('Unsupported platform');
  }
}