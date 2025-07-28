import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  void _log(String message) {
    print('[ConnectivityService] $message');
  }

  // Stream to listen for connectivity changes
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;

  // Get current connectivity status
  Future<ConnectivityResult> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _log('Current connectivity status: $result');
      return result;
    } catch (e) {
      _log('Exception in checkConnectivity: $e');
      // Return none as fallback for any connectivity check errors
      return ConnectivityResult.none;
    }
  }

  // Check if device is connected to internet
  Future<bool> isConnected() async {
    try {
      final result = await checkConnectivity();
      final connected = result != ConnectivityResult.none;
      _log('Device connected: $connected');
      return connected;
    } catch (e) {
      _log('Exception in isConnected: $e');
      return false;
    }
  }

  // Get connectivity type as string
  String getConnectivityType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'No Connection';
    }
  }
}
