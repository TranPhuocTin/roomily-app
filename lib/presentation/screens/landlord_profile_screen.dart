import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:roomily/core/services/session_service.dart';
import 'package:roomily/presentation/screens/sign_in_screen.dart';
import 'package:roomily/presentation/widgets/common/section_divider.dart';
import 'package:roomily/presentation/screens/edit_landlord_info_screen.dart';
import 'package:roomily/data/repositories/contract_repository.dart';
import 'package:roomily/data/blocs/contract/contract_cubit.dart';
import 'package:roomily/presentation/widgets/profile/profile_menu_item.dart';
import 'package:roomily/presentation/screens/user_detail_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:roomily/data/blocs/wallet/wallet_cubit.dart';
import 'package:roomily/data/blocs/wallet/wallet_state.dart';
import 'package:roomily/data/repositories/wallet_repository.dart';
import 'package:roomily/data/models/withdraw_info_create.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/user/user_cubit.dart';
import 'package:roomily/data/blocs/user/user_state.dart';
import 'package:roomily/presentation/screens/wallet_management_screen.dart';

import '../../core/di/app_dependency_manager.dart';

class LandlordProfileScreen extends StatefulWidget {
  const LandlordProfileScreen({super.key});

  @override
  State<LandlordProfileScreen> createState() => _LandlordProfileScreenState();
}

class _LandlordProfileScreenState extends State<LandlordProfileScreen> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isScrolled = false;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  double _userBalance = 0;

  // Màu sắc chính của ứng dụng
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color accentGreen = const Color(0xFF00C897);
  final Color accentRed = const Color(0xFFFF456C);
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Đăng ký observer để theo dõi vòng đời ứng dụng
    WidgetsBinding.instance.addObserver(this);
    
    // Get user balance if available from BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<UserCubit>().state is UserInfoLoaded) {
        final state = context.read<UserCubit>().state as UserInfoLoaded;
        setState(() {
          _userBalance = state.user.balance;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Hủy đăng ký observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }
  
  void _navigateToContractInfo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Đang tải thông tin...'),
              ],
            ),
          ),
        );
      },
    );
    
    try {
      final contractCubit = ContractCubit(repository: GetIt.I<ContractRepository>());
      final landlordInfo = await contractCubit.getLandlordInfo();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditLandlordInfoScreen(
            initialInfo: landlordInfo,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải thông tin hợp đồng: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Đảm bảo gọi super.build khi sử dụng AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu items
                  _buildMenuSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account section
          Padding(
            padding: const EdgeInsets.only(left: 0, top: 0, bottom: 8),
            child: Text(
              'Quản lý',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          ProfileMenuItem(
            icon: Icons.person,
            iconColor: Colors.purple,
            title: 'Thông tin cá nhân',
            subtitle: 'Xem và cập nhật thông tin cá nhân',
            onTap: () {
              // Điều hướng đến UserDetailScreen để xem thông tin chi tiết
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserDetailScreen(),
                ),
              );
            },
          ),

          // Add wallet management menu item
          BlocBuilder<UserCubit, UserInfoState>(
            builder: (context, state) {
              if (state is UserInfoLoaded) {
                _userBalance = state.user.balance;
              }
              
              return ProfileMenuItem(
                icon: Icons.account_balance_wallet,
                iconColor: Colors.amber,
                title: 'Quản lý ví',
                subtitle: 'Số dư: ${currencyFormatter.format(_userBalance)}',
                onTap: () {
                  // Navigate to wallet management screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletManagementScreen(),
                    ),
                  ).then((_) {
                    // Refresh user info when returning
                    if (mounted) {
                      context.read<UserCubit>().getUserInfo();
                    }
                  });
                },
              );
            }
          ),
          
          ProfileMenuItem(
            icon: Icons.edit,
            iconColor: primaryColor,
            title: 'Chỉnh sửa thông tin',
            subtitle: 'Cập nhật thông tin cá nhân và hợp đồng',
            onTap: _navigateToContractInfo,
          ),

          const SectionDivider(),
          
          // Settings section
          Padding(
            padding: const EdgeInsets.only(left: 0, top: 16, bottom: 8),
            child: Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // ProfileMenuItem(
          //   icon: Icons.notifications,
          //   iconColor: Colors.orange,
          //   title: 'Thông báo',
          //   subtitle: 'Quản lý cài đặt thông báo',
          //   onTap: () {
          //     // Navigate to notifications settings
          //   },
          // ),
          
          // ProfileMenuItem(
          //   icon: Icons.security,
          //   iconColor: Colors.green,
          //   title: 'Bảo mật',
          //   subtitle: 'Quản lý mật khẩu và bảo mật',
          //   onTap: () {
          //     // Navigate to security settings
          //   },
          // ),
          
          ProfileMenuItem(
            icon: Icons.language,
            iconColor: Colors.teal,
            title: 'Ngôn ngữ',
            subtitle: 'Tiếng Việt',
            onTap: () {
              _showLanguageSelectionDialog();
            },
          ),

          // const SectionDivider(),
          
          // Support section
          // Padding(
          //   padding: const EdgeInsets.only(left: 0, top: 16, bottom: 8),
          //   child: Text(
          //     'Hỗ trợ',
          //     style: TextStyle(
          //       fontSize: 14,
          //       fontWeight: FontWeight.bold,
          //       color: Colors.grey[600],
          //     ),
          //   ),
          // ),
          //
          // ProfileMenuItem(
          //   icon: Icons.help,
          //   iconColor: Colors.indigo,
          //   title: 'Trợ giúp & Hỗ trợ',
          //   subtitle: 'Câu hỏi thường gặp và liên hệ hỗ trợ',
          //   onTap: () {
          //     // Navigate to help & support
          //   },
          // ),
          
          ProfileMenuItem(
            icon: Icons.logout,
            iconColor: Colors.red,
            title: 'Đăng xuất',
            subtitle: 'Đăng xuất khỏi tài khoản',
            onTap: () {
              _showLogoutConfirmationDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn ngôn ngữ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('Tiếng Việt', 'vi'),
              _buildLanguageOption('English', 'en'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String language, String code) {
    final isSelected = (language == 'Tiếng Việt'); // Default to Vietnamese

    return ListTile(
      title: Text(language),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: primaryColor,
            )
          : null,
      onTap: () {
        // Handle language change
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chuyển ngôn ngữ sang: $language'),
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  // Show confirmation dialog before logout
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  // Handle the logout process
  Future<void> _handleLogout() async {
    try {
      _showLogoutLoading();
      final sessionService = GetIt.I<SessionService>();
      await sessionService.logout();
      // await GetIt.I<AppDependencyManager>().resetAll();
      await GetIt.I<AppDependencyManager>().initializeCore();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi đăng xuất: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show loading indicator during logout
  void _showLogoutLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Đang đăng xuất...'),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to show wallet management dialog
  void _showWalletManagementDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Quản lý ví',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Số dư hiện tại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<UserCubit, UserInfoState>(
                        builder: (context, state) {
                          double balance = 0;
                          if (state is UserInfoLoaded) {
                            balance = state.user.balance;
                          }
                          
                          return Text(
                            currencyFormatter.format(balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Nạp tiền'),
                        onPressed: () {
                          // Close this dialog
                          Navigator.pop(dialogContext);
                          // TODO: Navigate to add money screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng đang phát triển'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: accentGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.account_balance),
                        label: const Text('Rút tiền'),
                        onPressed: () {
                          // Close this dialog
                          Navigator.pop(dialogContext);
                          // Show withdraw dialog
                          _showWithdrawOptionsDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Add wallet functionality - reusing code from dashboard screen
  void _showWithdrawOptionsDialog(BuildContext context) {
    // Create WalletCubit instance if needed
    final walletCubit = WalletCubit(
      walletRepository: WalletRepositoryImpl(),
    );
    
    // Show dialog with loading state initially
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: walletCubit,
        child: BlocConsumer<WalletCubit, WalletState>(
          listener: (context, state) {
            if (state is WithdrawInfoFailure) {
              // If failed to get withdraw info, show create withdraw form
              Navigator.of(dialogContext).pop();
              _showCreateWithdrawInfoDialog(context, walletCubit);
            } else if (state is WithdrawInfoSuccess) {
              // If withdraw info found, show withdraw money dialog
              Navigator.of(dialogContext).pop();
              _showWithdrawMoneyDialog(context, walletCubit, state.withdrawInfo);
            }
          },
          builder: (context, state) {
            if (state is WithdrawInfoLoading) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Đang tải thông tin rút tiền...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Return a placeholder; the listener will handle navigation
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    
    // Trigger loading withdraw info
    walletCubit.getWithdrawInfo();
  }

  // Dialog to create withdrawal information
  void _showCreateWithdrawInfoDialog(BuildContext context, WalletCubit walletCubit) {
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: walletCubit,
        child: BlocConsumer<WalletCubit, WalletState>(
          listener: (context, state) {
            if (state is WithdrawInfoCreateSuccess) {
              // If creation successful, get the withdraw info again
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Thông tin tài khoản đã được lưu'),
                  backgroundColor: accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.of(dialogContext).pop();
              
              // Add delay before loading withdraw info again to ensure state is properly reset
              Future.delayed(const Duration(milliseconds: 300), () {
                // Load withdraw info again after creating
                if (mounted) {
                  walletCubit.getWithdrawInfo();
                }
              });
            } else if (state is WithdrawInfoCreateFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: ${state.errorMessage}'),
                  backgroundColor: accentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Thêm tài khoản ngân hàng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Vui lòng nhập thông tin tài khoản ngân hàng để rút tiền',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          // Bank name field
                          TextFormField(
                            controller: bankNameController,
                            decoration: InputDecoration(
                              labelText: 'Tên ngân hàng',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              prefixIcon: Icon(Icons.account_balance, color: primaryColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên ngân hàng';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Account number field
                          TextFormField(
                            controller: accountNumberController,
                            decoration: InputDecoration(
                              labelText: 'Số tài khoản',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              prefixIcon: Icon(Icons.credit_card, color: primaryColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập số tài khoản';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Account name field
                          TextFormField(
                            controller: accountNameController,
                            decoration: InputDecoration(
                              labelText: 'Tên chủ tài khoản',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              prefixIcon: Icon(Icons.person, color: primaryColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên chủ tài khoản';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: textSecondaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: state is WithdrawInfoCreateLoading
                            ? null
                            : () {
                              if (formKey.currentState!.validate()) {
                                final withdrawInfoCreate = WithdrawInfoCreate(
                                  bankName: bankNameController.text.trim(),
                                  accountNumber: accountNumberController.text.trim(),
                                  accountName: accountNameController.text.trim(),
                                );
                                walletCubit.createWithdrawInfo(withdrawInfoCreate);
                              }
                            },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: state is WithdrawInfoCreateLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Lưu', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Dialog to withdraw money
  void _showWithdrawMoneyDialog(BuildContext context, WalletCubit walletCubit, withdrawInfo) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: walletCubit,
        child: BlocConsumer<WalletCubit, WalletState>(
          listener: (context, state) {
            if (state is WithdrawMoneySuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Yêu cầu rút tiền đã được gửi'),
                  backgroundColor: accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.of(dialogContext).pop();
              
              // Refresh user info to update balance
              if (context.mounted) {
                context.read<UserCubit>().getUserInfo();
                
                // Reset wallet cubit state to avoid stuck in loading after withdrawal
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    walletCubit.getWithdrawInfo();
                  }
                });
              }
            } else if (state is WithdrawMoneyFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: ${state.errorMessage}'),
                  backgroundColor: accentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.monetization_on,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Rút tiền',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Bank account info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Số dư khả dụng:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondaryColor,
                                ),
                              ),
                              BlocBuilder<UserCubit, UserInfoState>(
                                builder: (context, state) {
                                  double balance = 0;
                                  if (state is UserInfoLoaded) {
                                    balance = state.user.balance;
                                  }
                                  
                                  return Text(
                                    currencyFormatter.format(balance),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: accentGreen,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Icon(Icons.account_balance, size: 18, color: textSecondaryColor),
                              const SizedBox(width: 8),
                              Text(
                                withdrawInfo.bankName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.credit_card, size: 18, color: textSecondaryColor),
                              const SizedBox(width: 8),
                              Text(
                                withdrawInfo.accountNumber,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 18, color: textSecondaryColor),
                              const SizedBox(width: 8),
                              Text(
                                withdrawInfo.accountName,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Số tiền muốn rút',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          prefixIcon: Icon(Icons.money, color: primaryColor),
                          suffixText: 'VND',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Nhập số tiền cần rút',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số tiền';
                          }
                          
                          double? amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Số tiền không hợp lệ';
                          }
                          
                          if (amount <= 0) {
                            return 'Số tiền phải lớn hơn 0';
                          }
                          
                          // Get current balance from UserCubit
                          double balance = 0;
                          if (context.read<UserCubit>().state is UserInfoLoaded) {
                            balance = (context.read<UserCubit>().state as UserInfoLoaded).user.balance;
                          }
                          
                          if (amount > balance) {
                            return 'Số tiền vượt quá số dư hiện tại';
                          }
                          
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: textSecondaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: state is WithdrawMoneyLoading
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  double amount = double.parse(amountController.text);
                                  walletCubit.withdrawMoney(amount);
                                }
                              },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: state is WithdrawMoneyLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Rút tiền', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}