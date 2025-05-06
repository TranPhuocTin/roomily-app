import 'package:network_info_plus/network_info_plus.dart';

class NetworkUtil {
  static final NetworkInfo _networkInfo = NetworkInfo();
  
  /// Returns the device's IPv4 address. 
  /// Returns null if the IP address cannot be retrieved.
  static Future<String?> getIPv4Address() async {
    try {
      final ipv4 = await _networkInfo.getWifiIP();
      return ipv4;
    } catch (e) {
      print('Error getting IPv4 address: $e');
      return null;
    }
  }
} 