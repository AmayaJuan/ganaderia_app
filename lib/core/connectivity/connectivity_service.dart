import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static Future<bool> isOnline({required bool simulateOffline}) async {
    if (simulateOffline) return false;

    final results = await Connectivity().checkConnectivity();
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);

    if (!hasNetwork) return false;

    if (kIsWeb) return true;

    return _nativeCheck();
  }

  static Future<bool> _nativeCheck() async {
    try {
      return await _resolveHost('google.com');
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resolveHost(String host) async {
    try {
      return true;
    } catch (_) {
      return false;
    }
  }
}