import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:roomily/core/config/dio_config.dart';

class DevModeScreen extends StatefulWidget {
  final String rentedRoomId;

  const DevModeScreen({
    Key? key,
    required this.rentedRoomId,
  }) : super(key: key);

  @override
  State<DevModeScreen> createState() => _DevModeScreenState();
}

class _DevModeScreenState extends State<DevModeScreen> {
  final Dio _dio = DioConfig.createDio();
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isSuccess = false;
  
  final TextEditingController _amountController = TextEditingController();
  bool _isPaymentLoading = false;
  String _paymentResultMessage = '';
  bool _isPaymentSuccess = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _mockExpireRentedRoom() async {
    setState(() {
      _isLoading = true;
      _resultMessage = 'Đang gửi yêu cầu...';
      _isSuccess = false;
    });

    try {
      final response = await _dio.post(
        'https://api.roomily.tech/api/v1/rented-rooms/mock/expire/${widget.rentedRoomId}',
      );
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage = 'Thành công!';
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Lỗi: ${error.toString()}';
      });
    }
  }

  Future<void> _testAddPayment() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      setState(() {
        _isPaymentSuccess = false;
        _paymentResultMessage = 'Vui lòng nhập số tiền';
      });
      return;
    }

    int? amountValue;
    try {
      amountValue = int.parse(amount);
      if (amountValue <= 0) {
        setState(() {
          _isPaymentSuccess = false;
          _paymentResultMessage = 'Số tiền phải > 0';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _isPaymentSuccess = false;
        _paymentResultMessage = 'Số tiền không hợp lệ';
      });
      return;
    }

    setState(() {
      _isPaymentLoading = true;
      _paymentResultMessage = 'Đang xử lý...';
      _isPaymentSuccess = false;
    });

    try {
      final response = await _dio.post(
        'https://api.roomily.tech/api/v1/payments/test/${widget.rentedRoomId}/$amountValue',
      );
      setState(() {
        _isPaymentLoading = false;
        _isPaymentSuccess = true;
        _paymentResultMessage = 'Thành công!';
      });
    } catch (error) {
      setState(() {
        _isPaymentLoading = false;
        _isPaymentSuccess = false;
        _paymentResultMessage = 'Lỗi: ${error.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Mode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room ID
            Text('ID: ${widget.rentedRoomId}'),
            const Divider(),
            
            // Payment Test
            const Text('Test Payment'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isPaymentLoading ? null : _testAddPayment,
                  child: _isPaymentLoading 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text('Nạp'),
                ),
              ],
            ),
            if (_paymentResultMessage.isNotEmpty)
              Text(
                _paymentResultMessage,
                style: TextStyle(
                  color: _isPaymentSuccess ? Colors.green : Colors.red,
                ),
              ),
            const Divider(),
            
            // Mock Expire
            const Text('Mock Expire'),
            ElevatedButton(
              onPressed: _isLoading ? null : _mockExpireRentedRoom,
              child: _isLoading 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Text('Expire Room'),
            ),
            if (_resultMessage.isNotEmpty)
              Text(
                _resultMessage,
                style: TextStyle(
                  color: _isSuccess ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 