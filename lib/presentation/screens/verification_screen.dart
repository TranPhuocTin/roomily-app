import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomily/core/localization/app_localization.dart';
import 'package:roomily/presentation/widgets/intro/gradient_button.dart';

import '../../core/config/text_styles.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  String _otpCode = '';
  bool _hasError = false;
  int _errorFieldIndex = -1; // -1 nghĩa là không có lỗi
  
  @override
  void initState() {
    super.initState();
    // Đảm bảo focus được thiết lập sau khi widget được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Kiểm tra xem chuỗi có chỉ chứa số hay không
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  // Xử lý khi người dùng nhập vào TextField
  void _handleTextChange(String value) {
    if (value.isEmpty) {
      setState(() {
        _otpCode = '';
        _hasError = false;
        _errorFieldIndex = -1;
      });
      return;
    }

    // Kiểm tra xem ký tự cuối cùng có phải là số không
    String lastChar = value.isNotEmpty ? value[value.length - 1] : '';
    bool isLastCharNumeric = lastChar.isNotEmpty ? _isNumeric(lastChar) : true;
    
    // Lọc ra chỉ các ký tự số
    String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Giới hạn độ dài tối đa là 6 ký tự
    if (numericValue.length > 6) {
      numericValue = numericValue.substring(0, 6);
    }
    
    // Cập nhật trạng thái lỗi
    int errorIndex = -1;
    if (!isLastCharNumeric) {
      // Đánh dấu ô hiện tại là lỗi
      errorIndex = numericValue.length; // Vị trí của ô đang nhập
    }
    
    // Nếu giá trị đã thay đổi (đã lọc bỏ ký tự không phải số), cập nhật lại controller
    if (numericValue != value) {
      _controller.value = TextEditingValue(
        text: numericValue,
        selection: TextSelection.collapsed(offset: numericValue.length),
      );
    }
    
    setState(() {
      _otpCode = numericValue;
      _hasError = !isLastCharNumeric;
      _errorFieldIndex = errorIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy đối tượng localization
    final appLocalization = AppLocalization.of(context);
    
    // Tính toán kích thước tối đa cho mỗi ô OTP dựa trên chiều rộng màn hình
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 60; // Trừ đi padding 30px mỗi bên
    final fieldWidth = (availableWidth - 50) / 6; // Trừ đi khoảng cách giữa các ô và chia cho 6
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(),
      body: GestureDetector(
        // Đảm bảo khi tap vào bất kỳ đâu trên màn hình cũng sẽ hiển thị bàn phím
        onTap: () {
          FocusScope.of(context).requestFocus(_focusNode);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appLocalization.translate('verification', 'verification'),
                        style: AppTextStyles.heading4,
                      ),
                      Column(
                        children: [
                          Image.asset('assets/icons/roomily_sign_up_icon.png'),
                          SizedBox(
                            height: 50,
                          ),
                        ],
                      )
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      appLocalization.translate('verification', 'sentCodeToEmail'),
                      style: AppTextStyles.bodyLargeSemiBold,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('aloaloalo@gmail.com'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  // Hiển thị thông báo lỗi nếu có
                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        appLocalization.translate('verification', 'onlyEnterNumbers'),
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  // Thêm một TextField ẩn để hiển thị bàn phím
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      onChanged: _handleTextChange,
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).requestFocus(_focusNode);
                      },
                      child: Container(
                        width: availableWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (index) => _buildOtpBox(index, fieldWidth),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  GradientButton(
                      text: appLocalization.translate('verification', 'verify'),
                      onPressed: () {
                        // Kiểm tra mã OTP khi nhấn nút tiếp theo
                        if (_otpCode.length == 6 && _isNumeric(_otpCode)) {
                          // Xử lý mã xác minh hợp lệ
                          print('Mã xác minh hợp lệ: $_otpCode');
                        } else {
                          // Hiển thị thông báo lỗi
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Vui lòng nhập đủ 6 chữ số'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      gradientColor1: const Color(0xFF23BFF9),
                      gradientColor2: const Color(0xFF99E5FF))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Xây dựng từng ô OTP riêng lẻ
  Widget _buildOtpBox(int index, double size) {
    // Xác định xem ô này có đang hiển thị lỗi không
    bool hasError = _errorFieldIndex == index;
    // Xác định xem ô này có đang được focus không
    bool isFocused = _otpCode.length == index;
    // Xác định xem ô này có giá trị không
    bool hasValue = index < _otpCode.length;
    
    // Lấy giá trị hiển thị cho ô này
    String displayValue = hasValue ? _otpCode[index] : '';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError 
              ? Colors.red 
              : (isFocused ? const Color(0xFF2CC2F9) : Colors.grey),
          width: hasError || isFocused ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        displayValue,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: hasError ? Colors.red : Colors.black,
        ),
      ),
    );
  }
}
