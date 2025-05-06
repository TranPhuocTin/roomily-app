import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/core/localization/app_localization.dart';
import 'package:roomily/data/blocs/auth/auth_cubit.dart';
import 'package:roomily/data/blocs/auth/auth_state.dart';
import 'package:roomily/data/models/register_request.dart';
import 'package:roomily/presentation/screens/verification_screen.dart';
import 'package:roomily/presentation/widgets/intro/gradient_button.dart';
import 'package:roomily/presentation/widgets/verification/custom_text_form_field.dart';
import 'package:roomily/presentation/widgets/verification/login_column.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLandlord = false;
  bool _isMale = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _currentStep = 0;
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // App colors
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color lightBlue = const Color(0xFFE6F4FF);
  final Color darkGray = const Color(0xFF424242);
  final Color accentColor = const Color(0xFFFFB300);
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Get current form completeness percentage
  double get _formCompleteness {
    int totalFields = 7; // Total number of required fields
    int completedFields = 0;
    
    // Validate username
    if (_usernameController.text.isNotEmpty && _usernameController.text.length >= 4) {
      completedFields++;
    }
    
    // Validate password
    if (_passwordController.text.isNotEmpty && _passwordController.text.length >= 6) {
      completedFields++;
    }
    
    // Validate confirm password
    if (_confirmPasswordController.text.isNotEmpty && 
        _confirmPasswordController.text == _passwordController.text) {
      completedFields++;
    }
    
    // Validate full name
    if (_fullNameController.text.isNotEmpty) {
      completedFields++;
    }
    
    // Validate address
    if (_addressController.text.isNotEmpty) {
      completedFields++;
    }
    
    // Validate email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (_emailController.text.isNotEmpty && emailRegex.hasMatch(_emailController.text)) {
      completedFields++;
    }
    
    // Validate phone
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (_phoneController.text.isNotEmpty && phoneRegex.hasMatch(_phoneController.text)) {
      completedFields++;
    }
    
    return completedFields / totalFields;
  }

  Future<void> _onSignUpPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      final registerRequest = RegisterRequest(
        username: _usernameController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        address: _addressController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        gender: _isMale,
        landlord: _isLandlord,
      );
      
      final success = await context.read<AuthCubit>().register(registerRequest);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin hợp lệ'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy đối tượng localization
    final appLocalization = AppLocalization.of(context);
    
    // Lấy kích thước màn hình để tính toán padding phù hợp
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final List<Step> steps = [
      Step(
        title: const Text('Tài khoản'),
        content: _buildAccountSection(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Thông tin cá nhân'),
        content: _buildPersonalInfoSection(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Liên hệ'),
        content: _buildContactSection(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký', style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Đăng ký thất bại'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lightBlue.withOpacity(0.3),
                Colors.white,
              ],
            ),
          ),
        child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                                'Tiến độ hoàn thành',
                                style: TextStyle(
                                  color: darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(_formCompleteness * 100).toInt()}%',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _formCompleteness,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                    
                    // Stepper or scrollable form based on screen size
                    screenWidth > 600
                        ? Expanded(
                            child: Stepper(
                              type: StepperType.horizontal,
                              currentStep: _currentStep,
                              onStepTapped: (step) {
                                setState(() {
                                  _currentStep = step;
                                });
                              },
                              onStepContinue: () {
                                if (_currentStep < steps.length - 1) {
                                  setState(() {
                                    _currentStep += 1;
                                  });
                                } else {
                                  _onSignUpPressed();
                                }
                              },
                              onStepCancel: () {
                                if (_currentStep > 0) {
                                  setState(() {
                                    _currentStep -= 1;
                                  });
                                }
                              },
                              steps: steps,
                              controlsBuilder: (context, details) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    children: [
                                      if (_currentStep > 0)
                                        TextButton(
                                          onPressed: details.onStepCancel,
                                          child: const Text('QUAY LẠI'),
                                        ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: details.onStepContinue,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                        child: Text(
                                          _currentStep < steps.length - 1 ? 'TIẾP TỤC' : 'ĐĂNG KÝ',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                  // Form explanation
                                  _buildInfoCard(),
                                  const SizedBox(height: 24),
                                  
                                  // Account section
                                  _buildSectionHeader('THÔNG TIN TÀI KHOẢN'),
                                  const SizedBox(height: 16),
                                  _buildAccountSection(),
                                  const SizedBox(height: 24),
                                  
                                  // Personal information section
                                  _buildSectionHeader('THÔNG TIN CÁ NHÂN'),
                                  const SizedBox(height: 16),
                                  _buildPersonalInfoSection(),
                                  const SizedBox(height: 24),
                                  
                                  // Contact information section
                                  _buildSectionHeader('THÔNG TIN LIÊN HỆ'),
                                  const SizedBox(height: 16),
                                  _buildContactSection(),
                                  const SizedBox(height: 32),
                                  
                                  // Register button
                                  _buildSignUpButton(),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              lightBlue,
              lightBlue.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đăng ký tài khoản',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                      fontSize: 16,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/icons/roomily_sign_up_icon.png',
                  width: 48,
                  height: 48,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Điền thông tin cá nhân của bạn để tạo tài khoản mới. Thông tin này sẽ được sử dụng cho hợp đồng và giao dịch trên Roomily.',
              style: TextStyle(color: darkGray, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Username field
            _buildInputField(
                      controller: _usernameController,
              label: 'Tên đăng nhập',
              prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên đăng nhập';
                        }
                        if (value.length < 4) {
                          return 'Tên đăng nhập phải có ít nhất 4 ký tự';
                        }
                        return null;
                      },
                    ),
            const SizedBox(height: 16),
                    
            // Password field
            _buildPasswordField(
                      controller: _passwordController,
              label: 'Mật khẩu',
              prefixIcon: Icons.lock_outline,
              isVisible: _isPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
            const SizedBox(height: 16),
                    
            // Confirm password field
            _buildPasswordField(
                      controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu',
              prefixIcon: Icons.lock_outline,
              isVisible: _isConfirmPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (value != _passwordController.text) {
                          return 'Mật khẩu xác nhận không khớp';
                        }
                        return null;
                      },
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Full name field
            _buildInputField(
                      controller: _fullNameController,
              label: 'Họ và tên',
              prefixIcon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên đầy đủ';
                        }
                        return null;
                      },
                    ),
            const SizedBox(height: 16),
                    
            // Address field
            _buildInputField(
                      controller: _addressController,
              label: 'Địa chỉ',
              prefixIcon: Icons.home_outlined,
              maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập địa chỉ';
                        }
                        return null;
                      },
                    ),
            const SizedBox(height: 16),
            
            // Gender selection
            _buildGenderSelector(),
            const SizedBox(height: 16),
                    
            // Role selection
            _buildRoleSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Email field
            _buildInputField(
                      controller: _emailController,
              label: 'Email',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
            const SizedBox(height: 16),
                    
            // Phone field
            _buildInputField(
                      controller: _phoneController,
              label: 'Số điện thoại',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        final phoneRegex = RegExp(r'^[0-9]{10}$');
                        if (!phoneRegex.hasMatch(value)) {
                          return 'Số điện thoại không hợp lệ (10 chữ số)';
                        }
                        return null;
                      },
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
                      children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Giới tính',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: darkGray,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
                          children: [
                Expanded(
                  child: _buildGenderOption(
                    label: 'Nam',
                    isSelected: _isMale,
                    onTap: () {
                      setState(() {
                        _isMale = true;
                      });
                    },
                    icon: Icons.male,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGenderOption(
                    label: 'Nữ',
                    isSelected: !_isMale,
                    onTap: () {
                                setState(() {
                        _isMale = false;
                                });
                              },
                    icon: Icons.female,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : darkGray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return InkWell(
      onTap: () {
                                setState(() {
          _isLandlord = !_isLandlord;
                                });
                              },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isLandlord ? primaryColor : Colors.grey.shade300,
            width: _isLandlord ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _isLandlord ? primaryColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isLandlord ? primaryColor : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work,
                color: _isLandlord ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng ký với tư cách chủ trọ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isLandlord ? primaryColor : darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bạn sẽ có quyền đăng phòng trọ và quản lý người thuê',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                        ),
                      ],
                    ),
            ),
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                              value: _isLandlord,
                              onChanged: (value) {
                                setState(() {
                                  _isLandlord = value!;
                                });
                              },
                activeColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        prefixIcon: Icon(prefixIcon, color: darkGray.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        prefixIcon: Icon(prefixIcon, color: darkGray.withOpacity(0.7)),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: darkGray.withOpacity(0.7),
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildSignUpButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        
        return Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : _onSignUpPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add),
                      const SizedBox(width: 8),
                      Text(
                        'ĐĂNG KÝ TÀI KHOẢN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
