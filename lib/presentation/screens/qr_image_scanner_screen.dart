import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRImageScannerScreen extends StatefulWidget {
  final File imageFile;
  
  const QRImageScannerScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  State<QRImageScannerScreen> createState() => _QRImageScannerScreenState();
}

class _QRImageScannerScreenState extends State<QRImageScannerScreen> {
  bool _isLoading = true;
  bool _qrFound = false;
  String? _qrData;
  
  @override
  void initState() {
    super.initState();
    _processQRCode();
  }
  
  Future<void> _processQRCode() async {
    try {
      setState(() => _isLoading = true);
      
      // Trong phiên bản 6.0.7, sử dụng MobileScannerController cho phép phân tích ảnh
      final controller = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.normal,
      );
      
      try {
        // Phân tích ảnh để tìm mã QR
        final barcodes = await controller.analyzeImage(widget.imageFile.path);
        
        if (barcodes != null && barcodes.barcodes.isNotEmpty) {
          final barcode = barcodes.barcodes.first;
          if (barcode.rawValue != null) {
            setState(() {
              _qrFound = true;
              _qrData = barcode.rawValue;
            });
            // Trả về kết quả quét
            Future.delayed(const Duration(milliseconds: 500), () {
              Navigator.pop(context, _qrData);
            });
          } else {
            setState(() {
              _qrFound = false;
              _qrData = null;
            });
          }
        } else {
          setState(() {
            _qrFound = false;
            _qrData = null;
          });
        }
      } finally {
        // Giải phóng controller
        controller.dispose();
      }
    } catch (e) {
      setState(() {
        _qrFound = false;
        _qrData = null;
      });
      print('Lỗi khi quét QR từ ảnh: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xử lý ảnh QR'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hiển thị ảnh đã chọn
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.imageFile,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 30),
              
              // Hiển thị trạng thái xử lý
              if (_isLoading)
                Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang quét mã QR...'),
                  ],
                )
              else if (_qrFound)
                Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 50),
                    const SizedBox(height: 16),
                    const Text(
                      'Đã tìm thấy mã QR!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nội dung: $_qrData',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    const Text(
                      'Không tìm thấy mã QR trong ảnh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 