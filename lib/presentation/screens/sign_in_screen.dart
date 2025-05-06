import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/cache/intro_preference.dart';
import 'package:roomily/core/cache/language_preference.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/core/localization/app_localization.dart';
import 'package:roomily/data/repositories/budget_plan_repository.dart';
import 'package:roomily/presentation/screens/budget_plan_preference_screen.dart';
import 'package:roomily/presentation/screens/sign_up_screen.dart';
import 'package:roomily/presentation/screens/splash_screen.dart';
import 'package:roomily/presentation/screens/landlord_dashboard_screen.dart';
import 'package:roomily/presentation/widgets/common/custom_bottom_navigation_bar.dart';
import 'package:roomily/presentation/widgets/verification/custom_text_form_field.dart';

import '../../core/di/app_dependency_manager.dart';
import '../../data/blocs/auth/auth_cubit.dart';
import '../../data/blocs/auth/auth_state.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberPassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void onSignUpPressed(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignUpScreen()));
  }

  // Phương thức reset intro và khởi động lại ứng dụng
  Future<void> _resetIntroAndRestart(BuildContext context) async {
    await IntroPreference.reset();
    
    // Hiển thị dialog thông báo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Intro'),
        content: const Text('Intro screens have been reset. The app will restart to show the intro screens.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              // Khởi động lại ứng dụng từ splash screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Phương thức reset ngôn ngữ và khởi động lại ứng dụng
  Future<void> _resetLanguageAndRestart(BuildContext context) async {
    await LanguagePreference.reset();
    
    // Hiển thị dialog thông báo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Language'),
        content: const Text('Language selection has been reset. The app will restart to show the language selection screen.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              // Khởi động lại ứng dụng từ splash screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Phương thức reset tất cả và khởi động lại ứng dụng
  Future<void> _resetAllAndRestart(BuildContext context) async {
    await IntroPreference.reset();
    await LanguagePreference.reset();
    
    // Hiển thị dialog thông báo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text('All settings have been reset. The app will restart.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              // Khởi động lại ứng dụng từ splash screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      
      context.read<AuthCubit>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    return null;
  }

  void _navigateBasedOnRole(bool isLandlord) {
    print('Navigating based on role: isLandlord = $isLandlord');
    if (isLandlord) {
      // Điều hướng đến giao diện Landlord
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandlordDashboardScreen()),
        (route) => false,
      );
    } else {
      // Check if user budget preferences exist
      // _checkUserPreferences();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CustomBottomNavigationBar()),
            (route) => false,
      );
    }
  }

  // New method to check if user preferences exist
  Future<void> _checkUserPreferences() async {
    final budgetPlanRepository = GetIt.instance<BudgetPlanRepository>();

    try {
      final hasPreferences = await budgetPlanRepository.isUserPreferenceExists();

      if (!hasPreferences) {
        // If no preferences exist, navigate to preference screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BudgetPlanPreferenceScreen()),
          (route) => false,
        );
      } else {
        // If preferences exist, navigate to home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CustomBottomNavigationBar()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error checking user preferences: $e');
      // On error, default to home screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CustomBottomNavigationBar()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy đối tượng localization
    final appLocalization = AppLocalization.of(context);
    
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        setState(() {
          _isLoading = state.status == AuthStatus.loading;
        });
        
        if (state.status == AuthStatus.authenticated) {
          print('User authenticated with roles: ${state.roles}');
          print('User is landlord: ${state.isLandlord}');
          await GetIt.I<AppDependencyManager>().initializeAll();
          _navigateBasedOnRole(state.isLandlord);
        } else if (state.status == AuthStatus.initializing) {
          // Hiển thị thông báo hoặc dialog đang khởi tạo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang khởi tạo dữ liệu ứng dụng...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state.status == AuthStatus.error) {
          String errorMessage = state.errorMessage ?? 'Đăng nhập thất bại';
          
          // Xử lý thông báo lỗi đặc biệt
          if (errorMessage.contains('401') || 
              errorMessage.contains('Unauthorized') ||
              errorMessage.contains('Tên đăng nhập hoặc mật khẩu không đúng')) {
            errorMessage = 'Tên đăng nhập hoặc mật khẩu không đúng';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset('assets/icons/roomily_signin_icon.png'),
                    ),
                    SizedBox(height: 40),

                    // Tiêu đề đăng nhập
                    Text(
                      appLocalization.translate('auth', 'signIn'),
                      style: AppTextStyles.heading4
                    ),
                    SizedBox(height: 24),

                    // Trường nhập email
                    CustomTextFormField(
                      controller: _emailController,
                      labelText: appLocalization.translate('auth', 'email'),
                      customIcon: Icon(
                        Icons.mail_outline,
                        color: Colors.grey,
                      ),
                      validator: _validateEmail,
                    ),
                    SizedBox(height: 16),

                    // Trường nhập mật khẩu
                    CustomTextFormField(
                      controller: _passwordController,
                      labelText: appLocalization.translate('auth', 'password'),
                      isPassword: true,
                      customIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                      ),
                      validator: _validatePassword,
                    ),
                    SizedBox(height: 16),

                    // Hàng "Ghi nhớ mật khẩu" và "Quên mật khẩu"
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     // "Ghi nhớ mật khẩu" với switch
                    //     Row(
                    //       children: [
                    //         Switch(
                    //           value: _rememberPassword,
                    //           onChanged: (value) {
                    //             setState(() {
                    //               _rememberPassword = value;
                    //             });
                    //           },
                    //           activeColor: Colors.blue,
                    //         ),
                    //         SizedBox(width: 8),
                    //         Text(
                    //           appLocalization.translate('auth', 'rememberPassword'),
                    //           style: AppTextStyles.bodyMediumBold
                    //         ),
                    //       ],
                    //     ),
                    //     // "Quên mật khẩu" text
                    //     GestureDetector(
                    //       onTap: () {
                    //         // Xử lý quên mật khẩu
                    //       },
                    //       child: Text(
                    //         appLocalization.translate('auth', 'forgotPassword'),
                    //         style: AppTextStyles.bodyMediumBold
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(height: 24),
                    
                    // Nút đăng nhập và các tùy chọn đăng nhập khác
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        return Center(
                          child: Column(
                            children: [
                              // Nút đăng nhập
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        appLocalization.translate('auth', 'signIn'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              // SizedBox(height: 16),
                              // Text(
                              //   appLocalization.translate('auth', 'orContinueWith') ?? 'Hoặc tiếp tục với',
                              //   style: TextStyle(
                              //     color: Colors.grey[600],
                              //     fontSize: 14,
                              //   ),
                              // ),
                              SizedBox(height: 24),
                              // Dòng "Chưa có tài khoản? Đăng ký"
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    appLocalization.translate('auth', 'dontHaveAccount') ?? 'Chưa có tài khoản?',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => onSignUpPressed(context),
                                    child: Text(
                                      appLocalization.translate('auth', 'signUp') ?? 'Đăng ký',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
  
  Widget _socialLoginButton(String iconPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}

