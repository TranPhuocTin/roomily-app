import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // Trong mobile_scanner 6.0.7, ta có thể sử dụng các tùy chọn đặc biệt khi khởi tạo controller
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],  // Chỉ quét mã QR
    detectionSpeed: DetectionSpeed.normal,  // Tốc độ quét mặc định
    detectionTimeoutMs: 1000,  // Thời gian timeout cho việc phát hiện
    returnImage: false,  // Không cần trả về hình ảnh
  );
  
  bool _hasScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        actions: [
          // Nút điều khiển đèn flash
          IconButton(
            tooltip: 'Bật/tắt đèn flash',
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          // Nút chuyển đổi camera trước/sau
          IconButton(
            tooltip: 'Chuyển đổi camera',
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (!_hasScanned && barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() {
                  _hasScanned = true;
                });
                // Hiển thị âm thanh/rung phản hồi khi quét thành công (tùy chọn)
                
                // Chuyển về màn hình trước với kết quả
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
            // Trong phiên bản mới, ta có các tham số mới để tùy chỉnh giao diện
            overlayBuilder: (p0, p1) {
              return _buildScannerOverlay();
            },
          ),
        ],
      ),
    );
  }
  
  // Widget tạo lớp phủ khi quét
  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderRadius: 10,
          borderColor: Colors.green,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
        color: Colors.black.withOpacity(0.5),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 320),
          child: Text(
            'Hướng camera vào mã QR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Overlay Shape
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3,
    this.borderRadius = 0,
    this.borderLength = 20,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      )
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderOffset = borderWidth / 2;
    final height = rect.height;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    canvas.drawRect(rect, boxPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cutOutRect,
        Radius.circular(borderRadius),
      ),
      boxPaint,
    );

    // Draw border top left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset + borderLength)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.left - borderOffset + borderLength, cutOutRect.top - borderOffset),
      borderPaint,
    );

    // Draw border top right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right + borderOffset - borderLength, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset + borderLength),
      borderPaint,
    );

    // Draw border bottom right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset - borderLength)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.right + borderOffset - borderLength, cutOutRect.bottom + borderOffset),
      borderPaint,
    );

    // Draw border bottom left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - borderOffset + borderLength, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
} 