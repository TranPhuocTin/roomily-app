import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/blocs/transaction/transaction_cubit.dart';
import 'package:roomily/data/blocs/transaction/transaction_state.dart';
import 'package:roomily/data/repositories/transaction_repository_impl.dart';
import 'package:roomily/core/utils/transaction_type.dart';
import 'package:roomily/data/blocs/payment/payment_cubit.dart';
import 'package:roomily/data/blocs/payment/payment_state.dart';
import 'package:roomily/data/repositories/payment_repository_impl.dart';
import 'package:roomily/presentation/screens/payment_qr_screen.dart';

import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/user/user_state.dart';
import '../../data/repositories/user_repository_impl.dart';

class TenantPendingTransactionsScreen extends StatefulWidget {
  final String? rentedRoomId;

  const TenantPendingTransactionsScreen({super.key, this.rentedRoomId});

  @override
  State<TenantPendingTransactionsScreen> createState() =>
      _TenantPendingTransactionsScreenState();
}

class _TenantPendingTransactionsScreenState extends State<TenantPendingTransactionsScreen> {
  late TransactionCubit _transactionCubit;
  late UserCubit _userCubit;
  late PaymentCubit _paymentCubit;
  bool _isLoadingPayment = false;

  @override
  void initState() {
    super.initState();
    _transactionCubit = TransactionCubit(
      transactionRepository: TransactionRepositoryImpl(),
    );
    _userCubit = UserCubit(
      userRepository: UserRepositoryImpl(),
    );
    _paymentCubit = PaymentCubit(
      paymentRepository: PaymentRepositoryImpl(),
    );
    
    // Fetch data initially
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.rentedRoomId != null) {
      // Load transaction data
      _transactionCubit.getTransactions(widget.rentedRoomId!);
    }
  }

  String _formatCurrency(String amount) {
    try {
      final value = double.parse(amount);
      final formatter =
          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
      return formatter.format(value);
    } catch (e) {
      return '$amount đ';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _getTransactionTypeText(TransactionType type) {
    switch (type) {
      case TransactionType.DEPOSIT:
        return 'Nạp tiền';
      case TransactionType.WITHDRAWAL:
        return 'Rút tiền';
      case TransactionType.RENT_PAYMENT:
        return 'Thanh toán tiền trọ';
      default:
        return 'Khác';
    }
  }

  Color _getTransactionTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.DEPOSIT:
        return Colors.green;
      case TransactionType.WITHDRAWAL:
        return Colors.red;
      case TransactionType.RENT_PAYMENT:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _loadPaymentDetails(String checkoutId) async {
    if (_isLoadingPayment) return;

    setState(() {
      _isLoadingPayment = true;
    });

    try {
      await _paymentCubit.getCheckout(checkoutId: checkoutId);
      
      // Check if the state is successful
      final state = _paymentCubit.state;
      if (state is PaymentResponseSuccess && mounted) {
        // Navigate to the payment QR screen with the response
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentQRScreen(
              paymentResponse: state.paymentResponse,
              inAppWallet: false,
              isLandlordDashboard: false,
            ),
          ),
        );
      } else if (state is PaymentResponseFailure && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thông tin thanh toán: ${state.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPayment = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _transactionCubit.close();
    _userCubit.close();
    _paymentCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _transactionCubit),
        BlocProvider.value(value: _userCubit),
        BlocProvider.value(value: _paymentCubit),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chờ thanh toán'),
          elevation: 0,
        ),
        body: Stack(
          children: [
            _buildPendingTransactionsContent(),
            if (_isLoadingPayment)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTransactionsContent() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionInitial) {
          if (widget.rentedRoomId != null) {
            _transactionCubit.getTransactions(widget.rentedRoomId!);
          }
          return const Center(child: CircularProgressIndicator());
        } else if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TransactionLoaded) {
          // Only show transactions with PENDING status
          final pendingTransactions = state.transactions.where((transaction) => 
              transaction.status.toUpperCase() == 'PENDING' || 
              transaction.status.toUpperCase() == 'CHỜ XỬ LÝ'
          ).toList();
          
          if (pendingTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Không có giao dịch đang chờ xử lý',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (widget.rentedRoomId != null) {
                await _transactionCubit.getTransactions(widget.rentedRoomId!);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingTransactions.length,
              itemBuilder: (context, index) {
                final transaction = pendingTransactions[index];
                // Request user info from UserCubit when building this item
                _userCubit.getUserInfoById(transaction.userId);
                
                String paymentActionText = _getPaymentActionText(transaction.type);
                
                return InkWell(
                  onTap: () {
                    // Kiểm tra xem transaction có checkoutId không và gọi API để lấy thông tin thanh toán
                    if (transaction.checkoutResponseId != null && transaction.checkoutResponseId!.isNotEmpty) {
                      _loadPaymentDetails(transaction.checkoutResponseId!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không có thông tin thanh toán cho giao dịch này'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with amount and date
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _getTransactionTypeText(transaction.type),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                _formatCurrency(transaction.amount),
                                style: TextStyle(
                                  color: _getTransactionTypeColor(transaction.type),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        const Divider(),

                        // Transaction details
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User information
                              BlocBuilder<UserCubit, UserInfoState>(
                                builder: (context, userState) {
                                  String userDisplayName = transaction.userName;

                                  if (userState is UserInfoByIdLoaded &&
                                      userState.user.id == transaction.userId) {
                                    // Use the most descriptive name available
                                    userDisplayName = userState.user.fullName ??
                                        userState.user.username ??
                                        transaction.userName;
                                  }

                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getTransactionTypeColor(transaction.type)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: _getTransactionTypeColor(
                                              transaction.type),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$paymentActionText bởi:',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              userDisplayName.isNotEmpty
                                                  ? userDisplayName
                                                  : 'Người dùng #${transaction.userId}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 12),

                              // Transaction info row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ngày thực hiện:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDate(transaction.createdAt),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trạng thái:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Đang xử lý',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Xem thanh toán hint
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.touch_app, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Nhấn để xem thông tin thanh toán',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        } else if (state is TransactionError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: ${state.message}',
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (widget.rentedRoomId != null) {
                      _transactionCubit.getTransactions(widget.rentedRoomId!);
                    }
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Không có dữ liệu'));
      },
    );
  }

  String _getPaymentActionText(TransactionType type) {
    switch (type) {
      case TransactionType.DEPOSIT:
        return 'Nạp tiền';
      case TransactionType.WITHDRAWAL:
        return 'Rút tiền';
      case TransactionType.RENT_PAYMENT:
        return 'Thanh toán';
      default:
        return 'Thực hiện';
    }
  }
} 