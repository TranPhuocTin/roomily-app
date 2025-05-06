import 'package:flutter/material.dart';

// Import color scheme
import 'package:roomily/presentation/screens/add_room_screen_v2.dart';

class BasicInfoStep extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController squareMetersController;
  final TextEditingController maxPeopleController;
  final String selectedRoomType;
  final Function(String?) onRoomTypeChanged;

  // UI Constants
  static const Color primaryColor = RoomColorScheme.basicInfo;
  static const Color textColor = RoomColorScheme.text;
  static const Color surfaceColor = RoomColorScheme.surface;

  const BasicInfoStep({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    required this.squareMetersController,
    required this.maxPeopleController,
    required this.selectedRoomType,
    required this.onRoomTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Thông tin cơ bản'),
          
          // Title field with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuint,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildInputField(
            controller: titleController,
            labelText: 'Tiêu đề',
            hintText: 'Nhập tiêu đề cho phòng của bạn',
            icon: Icons.title,
            required: true,
          ),
          ),
          
          // Description field with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuint,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildInputField(
            controller: descriptionController,
            labelText: 'Mô tả',
            hintText: 'Mô tả chi tiết về phòng của bạn',
            icon: Icons.description,
            maxLines: 3,
            required: true,
          ),
          ),
          
          // Room details with animation - contains both fields side by side
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuint,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: _buildInputField(
            controller: squareMetersController,
            labelText: 'Diện tích (m²)',
            hintText: 'Nhập diện tích phòng',
            icon: Icons.square_foot,
            keyboardType: TextInputType.number,
            required: true,
          ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
            controller: maxPeopleController,
            labelText: 'Số người tối đa',
            hintText: 'Nhập số người tối đa',
            icon: Icons.people,
            keyboardType: TextInputType.number,
            required: true,
          ),
                ),
              ],
            ),
          ),
          
          // Room type dropdown with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuint,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildRoomTypeSelector(),
          ),
          
          const SizedBox(height: 20),
          
          // Info card with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: value,
                  child: child,
                ),
              );
            },
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.home_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Loại phòng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: <String>['ROOM', 'APARTMENT', 'HOUSE']
                .map(
                  (type) => Expanded(
                    child: GestureDetector(
                      onTap: () => onRoomTypeChanged(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selectedRoomType == type
                              ? primaryColor
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: selectedRoomType == type
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                          border: Border.all(
                            color: selectedRoomType == type
                                ? primaryColor
                                : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getRoomTypeIcon(type),
                              color: selectedRoomType == type
                                  ? Colors.white
                                  : Colors.grey[600],
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getRoomTypeName(type),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selectedRoomType == type
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  IconData _getRoomTypeIcon(String type) {
    switch (type) {
      case 'ROOM':
        return Icons.hotel;
      case 'APARTMENT':
        return Icons.apartment;
      case 'HOUSE':
        return Icons.home;
      default:
        return Icons.meeting_room;
    }
  }

  String _getRoomTypeName(String type) {
    switch (type) {
      case 'ROOM':
        return 'Phòng trọ';
      case 'APARTMENT':
        return 'Căn hộ';
      case 'HOUSE':
        return 'Nhà nguyên căn';
      default:
        return 'Khác';
    }
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
          const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Mẹo tạo tiêu đề hấp dẫn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Hãy viết tiêu đề và mô tả hấp dẫn để giúp phòng của bạn nổi bật và thu hút người thuê:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
          ),
          const SizedBox(height: 12),
          _buildTipItem('Nêu rõ đặc điểm nổi bật của phòng'),
          _buildTipItem('Mô tả chi tiết về không gian, ánh sáng, tiện nghi'),
          _buildTipItem('Đề cập đến vị trí và các tiện ích gần đó'),
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
          const Padding(
            padding: EdgeInsets.only(top: 2, left: 8, right: 8),
            child: Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
        title,
        style: const TextStyle(
          color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
        ),
        ],
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: required ? '$labelText *' : labelText,
          hintText: hintText,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: surfaceColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: primaryColor,
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
          color: textColor,
        ),
        validator: required
            ? (value) => (value == null || value.isEmpty) ? 'Trường này là bắt buộc' : null
            : null,
      ),
    );
  }
} 