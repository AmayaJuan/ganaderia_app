import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Verificación de conectividad de red e internet.
class ConnectivityService {
  /// Comprueba acceso real a internet (varios fallbacks para Windows).
  static Future<bool> hasInternetAccess() async {
    try {
      final dnsGoogle = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (dnsGoogle.isNotEmpty && dnsGoogle.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final dnsCloudflare = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 3));
      if (dnsCloudflare.isNotEmpty &&
          dnsCloudflare.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final uri = Uri.parse('https://clients3.google.com/generate_204');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Devuelve si hay conexión activa (respeta simulación offline).
  static Future<bool> isOnline({required bool simulateOffline}) async {
    if (simulateOffline) return false;

    final connectivityResults = await Connectivity().checkConnectivity();
    final hasNetworkInterface = connectivityResults
        .any((result) => result != ConnectivityResult.none);

    if (!hasNetworkInterface) return false;
    return hasInternetAccess();
  }
}
