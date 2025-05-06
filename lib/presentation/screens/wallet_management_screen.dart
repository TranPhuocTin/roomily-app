import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/blocs/wallet/wallet_cubit.dart';
import 'package:roomily/data/blocs/wallet/wallet_state.dart';
import 'package:roomily/data/blocs/user/user_cubit.dart';
import 'package:roomily/data/blocs/user/user_state.dart';
import 'package:roomily/data/models/withdraw_info.dart';
import 'package:roomily/data/models/withdraw_info_create.dart';
import 'package:roomily/data/repositories/wallet_repository.dart';

class WalletManagementScreen extends StatefulWidget {
  const WalletManagementScreen({Key? key}) : super(key: key);

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color backgroundColor = const Color(0xFFF8FAFF);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);
  final Color accentGreen = const Color(0xFF00C897);
  final Color accentRed = const Color(0xFFFF456C);
  
  late final WalletCubit _walletCubit;
  double _userBalance = 0;
  
  @override
  void initState() {
    super.initState();
    _walletCubit = WalletCubit(
      walletRepository: WalletRepositoryImpl(),
    );
    _loadWithdrawInfo();
    
    // Get initial balance and ensure it's updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
    });
  }
  
  void _loadUserInfo() {
    if (context.mounted) {
      context.read<UserCubit>().getUserInfo();
      
      // Check if we already have user info in the state
      final userState = context.read<UserCubit>().state;
      if (userState is UserInfoLoaded) {
        setState(() {
          _userBalance = userState.user.balance;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _walletCubit.close();
    super.dispose();
  }
  
  void _loadWithdrawInfo() {
    _walletCubit.getWithdrawInfo();
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _walletCubit),
        BlocProvider.value(value: context.read<UserCubit>()),
      ],
      child: BlocListener<UserCubit, UserInfoState>(
        listener: (context, state) {
          if (state is UserInfoLoaded) {
            setState(() {
              _userBalance = state.user.balance;
            });
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text('Quản lý ví',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            foregroundColor: Colors.white,
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
          body: RefreshIndicator(
            onRefresh: () async {
              _loadWithdrawInfo();
              _loadUserInfo();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildWalletBalanceCard(),
                  _buildWithdrawInfoSection(),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showCreateWithdrawInfoDialog(context, _walletCubit);
            },
            backgroundColor: primaryColor,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
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
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Số dư hiện tại',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadUserInfo,
                tooltip: 'Cập nhật số dư',
              ),
            ],
          ),
          const SizedBox(height: 20),
          BlocBuilder<UserCubit, UserInfoState>(
            builder: (context, state) {
              // Use cached balance or state balance
              double balance = _userBalance;
              if (state is UserInfoLoaded) {
                balance = state.user.balance;
              }
              
              return Text(
                currencyFormatter.format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: InkWell(
              onTap: () => _showWithdrawOptionsDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.paid, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Rút tiền',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Text(
              'Thông tin tài khoản rút tiền',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
          ),
          BlocBuilder<WalletCubit, WalletState>(
            builder: (context, state) {
              if (state is WithdrawInfoLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (state is WithdrawInfoSuccess) {
                return _buildWithdrawInfoCard(state.withdrawInfo);
              } else if (state is WithdrawInfoFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bạn chưa có thông tin tài khoản',
                          style: TextStyle(
                            fontSize: 16,
                            color: textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm tài khoản'),
                          onPressed: () {
                            _showCreateWithdrawInfoDialog(context, _walletCubit);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawInfoCard(WithdrawInfo withdrawInfo) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      withdrawInfo.bankName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Được thêm vào: ${withdrawInfo.lastWithdrawDate ?? 'Chưa rút tiền'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showCreateWithdrawInfoDialog(context, _walletCubit, withdrawInfo);
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.credit_card, 'Số tài khoản', withdrawInfo.accountNumber),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Chủ tài khoản', withdrawInfo.accountName),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.history, 'Lần cuối rút tiền', 
                withdrawInfo.lastWithdrawDate ?? 'Chưa rút tiền'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.paid),
                label: const Text('Rút tiền'),
                onPressed: () {
                  _showWithdrawMoneyDialog(context, _walletCubit, withdrawInfo);
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
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Method to show withdraw options dialog
  void _showWithdrawOptionsDialog(BuildContext context) {
    _walletCubit.getWithdrawInfo();
  }

  // Dialog to create withdrawal information
  void _showCreateWithdrawInfoDialog(BuildContext context, WalletCubit walletCubit, [WithdrawInfo? existingInfo]) {
    final bankNameController = TextEditingController(text: existingInfo?.bankName);
    final accountNumberController = TextEditingController(text: existingInfo?.accountNumber);
    final accountNameController = TextEditingController(text: existingInfo?.accountName);
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
                          existingInfo != null 
                              ? 'Cập nhật tài khoản'
                              : 'Thêm tài khoản',
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
                      existingInfo != null
                          ? 'Cập nhật thông tin tài khoản ngân hàng để rút tiền'
                          : 'Vui lòng nhập thông tin tài khoản ngân hàng để rút tiền',
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
                            : Text(
                                existingInfo != null ? 'Cập nhật' : 'Lưu', 
                                style: const TextStyle(fontSize: 16)
                              ),
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
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: walletCubit),
          BlocProvider.value(value: context.read<UserCubit>()),
        ],
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
                _loadUserInfo();
                
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
                                  // Use cached balance or state balance
                                  double balance = _userBalance;
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
                          
                          // Use the cached balance instead of trying to read from state
                          if (amount > _userBalance) {
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