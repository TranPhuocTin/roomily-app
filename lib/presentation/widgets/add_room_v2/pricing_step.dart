import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import color scheme
import 'package:roomily/presentation/screens/add_room_screen_v2.dart';

class PricingStep extends StatefulWidget {
  final TextEditingController priceController;
  final TextEditingController depositController;
  final TextEditingController electricPriceController;
  final TextEditingController waterPriceController;

    // UI Constants
    static const Color primaryColor = RoomColorScheme.pricing;
    static const Color textColor = RoomColorScheme.text;
    static const Color surfaceColor = RoomColorScheme.surface;

  const PricingStep({
    Key? key,
    required this.priceController,
    required this.depositController,
    required this.electricPriceController,
    required this.waterPriceController,
  }) : super(key: key);

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  double get priceValue => double.tryParse(widget.priceController.text) ?? 0;
  double get depositValue => double.tryParse(widget.depositController.text) ?? 0;
  double get electricPriceValue => double.tryParse(widget.electricPriceController.text) ?? 0;
  double get waterPriceValue => double.tryParse(widget.waterPriceController.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Thông tin giá cả'),

          // Price visualization
          _buildPriceVisualization(),

          _buildInputField(
            controller: widget.priceController,
            labelText: 'Giá thuê (VNĐ/tháng)',
            hintText: 'Nhập giá thuê hàng tháng',
            icon: Icons.monetization_on,
            keyboardType: TextInputType.number,
            required: true,
            onChanged: (value) => setState(() {}),
          ),
          _buildInputField(
            controller: widget.depositController,
            labelText: 'Tiền đặt cọc (VNĐ)',
            hintText: 'Nhập số tiền đặt cọc (nếu có)',
            icon: Icons.account_balance_wallet,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() {}),
          ),
          _buildInputField(
            controller: widget.electricPriceController,
            labelText: 'Giá điện (VNĐ/kWh)',
            hintText: 'Nhập giá điện',
            icon: Icons.bolt,
            keyboardType: TextInputType.number,
            required: true,
            onChanged: (value) => setState(() {}),
          ),
          _buildInputField(
            controller: widget.waterPriceController,
            labelText: 'Giá nước (VNĐ/m³)',
            hintText: 'Nhập giá nước',
            icon: Icons.water_drop,
            keyboardType: TextInputType.number,
            required: true,
            onChanged: (value) => setState(() {}),
          ),

          const SizedBox(height: 20),
          _buildPricingTips(),
        ],
      ),
    );
  }

  Widget _buildPriceVisualization() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PricingStep.primaryColor,
            PricingStep.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PricingStep.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            formatCurrency(priceValue),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'VNĐ/tháng',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const Divider(color: Colors.white30, height: 30),
          if (depositValue > 0) ...[
            _buildPriceRow(
              'Tiền đặt cọc:',
              formatCurrency(depositValue),
            ),
            const SizedBox(height: 8),
          ],
          _buildPriceRow(
            'Giá điện:',
            '${formatCurrency(electricPriceValue)}/kWh',
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Giá nước:',
            '${formatCurrency(waterPriceValue)}/m³',
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PricingStep.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PricingStep.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: PricingStep.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Mẹo định giá hiệu quả',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Nghiên cứu giá thị trường trong khu vực để định giá hợp lý'),
          _buildTipItem('Giá điện, nước nên tham khảo giá nhà nước hoặc cao hơn một chút'),
          _buildTipItem('Tiền đặt cọc thường tương đương 1-2 tháng tiền thuê'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: PricingStep.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: PricingStep.textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: required ? '$labelText *' : labelText,
          hintText: hintText,
          prefixIcon: Icon(icon, color: PricingStep.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: PricingStep.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: PricingStep.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: PricingStep.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          color: PricingStep.textColor,
        ),
        onChanged: onChanged,
        validator: required
            ? (value) => (value == null || value.isEmpty) ? 'Trường này là bắt buộc' : null
            : null,
      ),
    );
  }

  String formatCurrency(double value) {
    if (value == 0) return '0 ₫';
    return currencyFormatter.format(value);
  }
}