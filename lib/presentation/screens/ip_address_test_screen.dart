import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';

class IPAddressTestScreen extends StatefulWidget {
  const IPAddressTestScreen({Key? key}) : super(key: key);

  @override
  State<IPAddressTestScreen> createState() => _IPAddressTestScreenState();
}

class _IPAddressTestScreenState extends State<IPAddressTestScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();
  
  String _wifiName = 'Đang tải...';
  String _wifiBSSID = 'Đang tải...';
  String _wifiIPv4 = 'Đang tải...';
  String _wifiIPv6 = 'Đang tải...';
  String _wifiGatewayIP = 'Đang tải...';
  String _wifiSubmask = 'Đang tải...';
  String _wifiBroadcast = 'Đang tải...';
  
  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    try {
      if (!mounted) return;
      
      String? wifiName = await _networkInfo.getWifiName();
      setState(() {
        _wifiName = wifiName ?? 'Không có';
      });
      
      String? wifiBSSID = await _networkInfo.getWifiBSSID();
      setState(() {
        _wifiBSSID = wifiBSSID ?? 'Không có';
      });
      
      String? wifiIPv4 = await _networkInfo.getWifiIP();
      setState(() {
        _wifiIPv4 = wifiIPv4 ?? 'Không có';
      });
      
      String? wifiIPv6 = await _networkInfo.getWifiIPv6();
      setState(() {
        _wifiIPv6 = wifiIPv6 ?? 'Không có';
      });
      
      String? wifiSubmask = await _networkInfo.getWifiSubmask();
      setState(() {
        _wifiSubmask = wifiSubmask ?? 'Không có';
      });
      
      String? wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
      setState(() {
        _wifiGatewayIP = wifiGatewayIP ?? 'Không có';
      });
      
      String? wifiBroadcast = await _networkInfo.getWifiBroadcast();
      setState(() {
        _wifiBroadcast = wifiBroadcast ?? 'Không có';
      });
    } catch (e) {
      setState(() {
        _wifiName = 'Lỗi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Tin IP Address'),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNetworkInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                title: 'Thông Tin Mạng',
                children: [
                  _buildInfoItem('Tên WiFi', _wifiName),
                  _buildInfoItem('BSSID', _wifiBSSID),
                  _buildInfoItem('IPv4 Address', _wifiIPv4),
                  _buildInfoItem('IPv6 Address', _wifiIPv6),
                  _buildInfoItem('Gateway IP', _wifiGatewayIP),
                  _buildInfoItem('Subnet Mask', _wifiSubmask),
                  _buildInfoItem('Broadcast', _wifiBroadcast),
                ],
              ),
              const SizedBox(height: 20),
              _buildPermissionInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông Tin Quyền Truy Cập',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 24),
            Text(
              Platform.isAndroid
                  ? 'Android yêu cầu quyền ACCESS_FINE_LOCATION để lấy thông tin WiFi'
                  : Platform.isIOS
                      ? 'iOS cần thêm key "Privacy - Local Network Usage Description" trong Info.plist'
                      : 'Hãy kiểm tra quyền truy cập mạng trên nền tảng này',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            if (Platform.isAndroid)
              const Text(
                'Đối với Android 10+, thêm quyền ACCESS_FINE_LOCATION và ACCESS_BACKGROUND_LOCATION trong AndroidManifest.xml',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 