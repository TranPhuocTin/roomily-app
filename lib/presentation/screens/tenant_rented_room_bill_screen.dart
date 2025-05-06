import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_cubit.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_state.dart';
import 'package:roomily/data/blocs/transaction/transaction_cubit.dart';
import 'package:roomily/data/blocs/transaction/transaction_state.dart';
import 'package:roomily/data/repositories/transaction_repository_impl.dart';
import 'package:roomily/core/utils/bill_status.dart';
import 'package:roomily/core/utils/transaction_type.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/user/user_state.dart';
import '../../data/repositories/user_repository_impl.dart';

class TenantRentedRoomBillScreen extends StatefulWidget {
  final String? rentedRoomId;

  const TenantRentedRoomBillScreen({super.key, this.rentedRoomId});

  @override
  State<TenantRentedRoomBillScreen> createState() =>
      _TenantRentedRoomBillScreenState();
}

class _TenantRentedRoomBillScreenState extends State<TenantRentedRoomBillScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TransactionCubit _transactionCubit;
  late UserCubit _userCubit;
  // Track which user IDs we've already requested to avoid duplicate API calls
  final Set<String> _requestedUserIds = {};

  @override
  void initState() {
    super.initState();
    print('Rented Room Id in init state: ${widget.rentedRoomId}');
    _tabController = TabController(length: 2, vsync: this);
    _transactionCubit = TransactionCubit(
      transactionRepository: TransactionRepositoryImpl(),
    );
    _userCubit = UserCubit(
      userRepository: UserRepositoryImpl(),
    );

    // Add listener to tab controller to fetch data when switching tabs
    _tabController.addListener(_handleTabChange);
  }

  void _loadInitialData() {
    if (widget.rentedRoomId != null) {
      // Load transaction data when tab is initially set to transactions (index 1)
      _transactionCubit.getTransactions(widget.rentedRoomId!);
    }
  }

  void _handleTabChange() {
    // Load transaction data when switching to transaction tab
    print('Rented Room Id: $widget.rentedRoomId');
    if (_tabController.index == 1 && widget.rentedRoomId != null) {
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

  @override
  void dispose() {
    _tabController.dispose();
    _transactionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _transactionCubit),
        BlocProvider.value(value: _userCubit)
      ],
      child: BlocListener<RentedRoomCubit, RentedRoomState>(
        listenWhen: (prev, current) => current is BillLogHistorySuccess,
        listener: (context, state) {
          if (state is BillLogHistorySuccess && state.rentedRoomId != null) {
            _loadInitialData();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Lịch sử giao dịch'),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Hóa đơn', icon: Icon(Icons.receipt_long)),
                Tab(
                    text: 'Giao dịch',
                    icon: Icon(Icons.account_balance_wallet)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBillHistoryTab(),
              _buildTransactionHistoryTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillHistoryTab() {
    return BlocBuilder<RentedRoomCubit, RentedRoomState>(
      builder: (context, state) {
        if (state is BillLogHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BillLogHistorySuccess) {
          // Filter out bills with PENDING status
          final billLogs = state.billLogs.where((bill) => bill.billStatus != BillStatus.PENDING).toList();
          
          if (billLogs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có hóa đơn nào',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: billLogs.length,
            itemBuilder: (context, index) {
              final bill = billLogs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Hóa đơn tháng ${bill.createdAt}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8), // Add spacing
                          _buildBillStatusChip(bill.billStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildBillDetailRow('Tiền phòng:',
                          _formatCurrency(bill.rentalCost.toString())),
                      _buildBillDetailRow('Tiền điện:',
                          _formatCurrency(bill.electricityBill.toString())),
                      _buildBillDetailRow('Tiền nước:',
                          _formatCurrency(bill.waterBill.toString())),
                      const Divider(),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (state is BillLogFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: ${state.error}',
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (widget.rentedRoomId != null) {
                      context
                          .read<RentedRoomCubit>()
                          .getBillLogHistoryByRentedRoomId(
                              widget.rentedRoomId!);
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

  Widget _buildTransactionHistoryTab() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionInitial) {
          if (widget.rentedRoomId != null) {
            _transactionCubit.getTransactions(widget.rentedRoomId!);
          }
          return _buildTransactionShimmerList();
        } else if (state is TransactionLoading) {
          return _buildTransactionShimmerList();
        } else if (state is TransactionLoaded) {
          // Reset requested users when loading new transactions
          _requestedUserIds.clear();
          
          // Filter out transactions with PENDING status
          final transactions = state.transactions.where((transaction) => 
              transaction.status.toUpperCase() != 'PENDING' && 
              transaction.status.toUpperCase() != 'CHỜ XỬ LÝ'
          ).toList();
          
          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có giao dịch nào',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Request all user info at once without setState
          for (var transaction in transactions) {
            if (!_requestedUserIds.contains(transaction.userId)) {
              _requestedUserIds.add(transaction.userId);
              _userCubit.getUserInfoById(transaction.userId);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
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

  // Build a transaction item with its own BlocBuilder for user data
  Widget _buildTransactionItem(dynamic transaction) {
    return BlocBuilder<UserCubit, UserInfoState>(
      builder: (context, state) {
        // If we have loaded user data for this transaction, show the actual card
        final bool userLoaded = state is UserInfoByIdLoaded && 
                                state.user.id == transaction.userId;
        
        // Show shimmer while user data is loading
        if (!userLoaded) {
          return _buildTransactionShimmerCard();
        }

        // User data loaded, show the real card
        return _buildTransactionCard(transaction, 
            state is UserInfoByIdLoaded ? state.user : null);
      },
    );
  }

  // Updated to accept the user object directly
  Widget _buildTransactionCard(dynamic transaction, dynamic user) {
    String paymentActionText = _getPaymentActionText(transaction.type);
    String userDisplayName = transaction.userName;
    
    // Use fullName if available
    if (user != null && user.fullName != null) {
      userDisplayName = user.fullName;
    }
    
    return Card(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTransactionTypeColor(
                                transaction.type)
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
                            userDisplayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                          Text(
                            _getStatusText(transaction.status),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(
                                  transaction.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer effect for transaction list loading
  Widget _buildTransactionShimmerList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: 5, // Show 5 shimmer cards
        itemBuilder: (context, index) {
          return _buildTransactionShimmerCard();
        },
      ),
    );
  }

  // Shimmer effect for a single transaction card
  Widget _buildTransactionShimmerCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with amount and date
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    color: Colors.white,
                  ),
                  Container(
                    width: 80,
                    height: 16,
                    color: Colors.white,
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
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 150,
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Transaction info row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 120,
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 100,
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillStatusChip(BillStatus? status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case BillStatus.PAID:
        chipColor = Colors.green;
        statusText = 'Đã thanh toán';
        break;
      case BillStatus.UNPAID:
        chipColor = Colors.red;
        statusText = 'Chưa thanh toán';
        break;
      case BillStatus.PENDING:
        chipColor = Colors.orange;
        statusText = 'Đang xử lý';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBillDetailRow(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentActionText(TransactionType type) {
    switch (type) {
      case TransactionType.DEPOSIT:
        return 'Nộp tiền';
      case TransactionType.WITHDRAWAL:
        return 'Rút tiền';
      case TransactionType.RENT_PAYMENT:
        return 'Thanh toán';
      default:
        return 'Thực hiện';
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'HOÀN THÀNH':
        return 'Hoàn thành';
      case 'PENDING':
      case 'CHỜ XỬ LÝ':
        return 'Chờ xử lý';
      case 'FAILED':
      case 'THẤT BẠI':
        return 'Thất bại';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'HOÀN THÀNH':
        return Colors.green;
      case 'PENDING':
      case 'CHỜ XỬ LÝ':
        return Colors.orange;
      case 'FAILED':
      case 'THẤT BẠI':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
