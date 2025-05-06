import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/repositories/rented_room_repository.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/presentation/screens/payment_screen.dart';
import 'package:roomily/presentation/screens/tenant_rented_room_bill_screen.dart';
import 'package:roomily/presentation/screens/tenant_pending_transactions_screen.dart';
import 'package:roomily/presentation/widgets/bill_log_widget.dart';
import 'package:roomily/core/utils/bill_status.dart';
import 'package:roomily/core/utils/rented_room_status.dart';
import 'package:roomily/data/models/bill_log.dart';
import 'package:roomily/data/models/rented_room.dart';
import 'package:roomily/data/models/room.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../data/blocs/payment/payment_cubit.dart';
import '../../data/blocs/rented_room/rented_room_cubit.dart';
import '../../data/blocs/rented_room/rented_room_state.dart';
import '../../data/blocs/transaction/transaction_cubit.dart';
import '../../data/blocs/transaction/transaction_state.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../main.dart';
import '../../presentation/screens/contract_viewer_screen.dart';
import '../../data/blocs/contract/contract_cubit.dart';
import '../../data/repositories/contract_repository_impl.dart';
import '../../data/repositories/contract_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../presentation/screens/tenant_contract_info_screen.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_state.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:open_file/open_file.dart';
import '../../presentation/screens/dev_mode_screen.dart';

class TenantRoomManagementScreen extends StatefulWidget {
  final String rentedRoomId;
  final Room? roomDetail;

  const TenantRoomManagementScreen({
    Key? key,
    required this.rentedRoomId,
    this.roomDetail,
  }) : super(key: key);

  @override
  State<TenantRoomManagementScreen> createState() => _TenantRoomManagementScreenState();
}

class _TenantRoomManagementScreenState extends State<TenantRoomManagementScreen> {
  late final RentedRoomCubit _rentedRoomCubit;
  late final TransactionCubit _transactionCubit;
  BillLog? _billLog;
  List<RentedRoom> _rentedRooms = [];
  RentedRoom? _currentRoom;
  Room? _roomDetail;

  @override
  void initState() {
    super.initState();
    _rentedRoomCubit = RentedRoomCubit(
      rentedRoomRepository: RentedRoomRepositoryImpl(),
    );
    _transactionCubit = TransactionCubit(
      transactionRepository: TransactionRepositoryImpl(),
    );
    // Lưu thông tin phòng từ tham số
    _roomDetail = widget.roomDetail;
    // Fetch rooms and active bill log right away
    _fetchRentedRooms();
    _prefetchBillLogData();
    // Fetch pending transactions
    _fetchPendingTransactions();
  }

  // Fetch pending transactions
  void _fetchPendingTransactions() {
    if (widget.rentedRoomId.isNotEmpty) {
      _transactionCubit.getTransactions(widget.rentedRoomId);
    }
  }

  // Phương thức refresh tất cả dữ liệu cần thiết
  Future<void> _refreshAllData({bool showMessage = true}) async {
    debugPrint('🔄 Refreshing all tenant room data');
    
    try {
      // Refresh tất cả dữ liệu cần thiết đồng thởi
      await Future.wait([
        _rentedRoomCubit.getRentedRooms(),
        _rentedRoomCubit.getActiveBillLog(widget.rentedRoomId),
        _transactionCubit.getTransactions(widget.rentedRoomId),
      ]);
      
      // Hiển thị thông báo nếu cần
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dữ liệu đã được cập nhật'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fetchRentedRooms() {
    debugPrint('Fetching rented rooms');
    _rentedRoomCubit.getRentedRooms();
  }

  // Phương thức prefetch dữ liệu bill log
  void _prefetchBillLogData() {
    debugPrint('Prefetching bill log data for room: ${widget.rentedRoomId}');
    _rentedRoomCubit.getActiveBillLog(widget.rentedRoomId);
  }

  // Format lại ngày tháng
  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Format tiền tệ
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

  @override
  void dispose() {
    _rentedRoomCubit.close();
    _transactionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _rentedRoomCubit),
        BlocProvider.value(value: _transactionCubit),
      ],
      child: BlocConsumer<RentedRoomCubit, RentedRoomState>(
        listener: (context, state) {
          if (state is BillLogFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BillLogSuccess) {
            // Refresh the current bill log displayed in the UI
            setState(() {
              _billLog = state.billLog;
            });
          } else if (state is BillLogConfirmSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is RentedRoomSuccess) {
            setState(() {
              _rentedRooms = state.rentedRooms ?? [];

              // Tìm phòng hiện tại theo id hoặc roomId
              _currentRoom = null;
              for (var room in _rentedRooms) {
                if (room.id == widget.rentedRoomId || room.roomId == widget.rentedRoomId) {
                  _currentRoom = room;
                  break;
                }
              }

              debugPrint('Found current room: ${_currentRoom?.id}');
            });
          }
        },
        builder: (context, state) {
          if (state is RentedRoomInitial) {
            context.read<RentedRoomCubit>().getRentedRooms();
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if ((state is RentedRoomLoading && _rentedRooms.isEmpty) ||
              _currentRoom == null) {
            return const Scaffold(
                body: Center(
              child: CircularProgressIndicator(),
            ));
          }
          return Scaffold(
            body: Container(
              color: Colors.white,
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh all necessary data
                  await _refreshAllData();
                },
                child: CustomScrollView(
                  // Enable always scrollable physics to ensure pull-to-refresh works
                  // even when content is not scrollable
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 120,
                      backgroundColor: Colors.teal,
                      pinned: true,
                      floating: false,
                      centerTitle: false,
                      elevation: 0,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: Text(
                        _roomDetail?.title ?? 'Phòng ${_currentRoom?.roomId ?? widget.rentedRoomId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.teal,
                                Colors.teal.shade50,
                              ],
                              stops: [0.4, 1.0],
                            ),
                          ),
                          padding: EdgeInsets.fromLTRB(16, 60, 16, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.home,
                                    color: Colors.teal, size: 25),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.account_balance_wallet,
                                            color: Colors.teal,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatCurrency(
                                                _currentRoom?.rentedRoomWallet ??
                                                    '0'),
                                            style: TextStyle(
                                              color: Colors.teal,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _roomDetail != null 
                                        ? _roomDetail!.address
                                        : (_getRentedRoomStatusText(_currentRoom) +
                                          ' | Hết hạn: ${_formatDate(_currentRoom?.endDate ?? '2024-12-31')}'),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_roomDetail != null) Text(
                                      _getRentedRoomStatusText(_currentRoom) +
                                        ' | Hết hạn: ${_formatDate(_currentRoom?.endDate ?? '2024-12-31')}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Phần đơn hàng/hóa đơn
                    _buildBillSection(),

                    // Phần tiện ích của tôi
                    _buildUtilitiesSection(),
                    
                    // Phần hợp đồng
                    _buildContractSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Phần hóa đơn/thanh toán
  Widget _buildBillSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Update the BillLogWidget here with a key that depends on the billLog state
          // This will force a rebuild when the billLog changes
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: BillLogWidget(
                key: ValueKey(_billLog?.id ?? widget.rentedRoomId),
                rentedRoomId: widget.rentedRoomId,
                initialBillLog: _billLog, // Truyền dữ liệu đã prefetch
                autoLoad:
                    _billLog == null, // Chỉ tự động tải nếu chưa có dữ liệu
              )
              // child: UtilityBillCard(
              //   key: ValueKey(_billLog?.id ?? widget.roomId),
              //   rentedRoomId: widget.roomId,
              // ),
              ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // Phần tiện ích chính
  Widget _buildUtilitiesSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader('Tiện ích của tôi', null),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildUtilityCard(
                    Icons.payment,
                    'Nộp tiền',
                    'Thanh toán nhanh',
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(create: (context) {
                            return PaymentCubit(
                              paymentRepository: PaymentRepositoryImpl(),
                            );
                          }, child: PaymentScreen(rentedRoomId: widget.rentedRoomId, isLandlordDashboard: false)),
                        ),
                      ).then((_) async {
                        // Always refresh data when returning from payment screen
                        await _refreshAllData(showMessage: false);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<TransactionCubit, TransactionState>(
                    builder: (context, state) {
                      // Count pending transactions
                      int pendingCount = 0;
                      if (state is TransactionLoaded) {
                        pendingCount = state.transactions.where((transaction) => 
                          transaction.status.toUpperCase() == 'PENDING' || 
                          transaction.status.toUpperCase() == 'CHỜ XỬ LÝ'
                        ).length;
                      }
                      
                      return _buildUtilityCardWithBadge(
                        Icons.pending_actions,
                        'Chờ thanh toán',
                        'HĐ chưa thanh toán',
                        Colors.amber,
                        pendingCount,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TenantPendingTransactionsScreen(
                                rentedRoomId: widget.rentedRoomId,
                              ),
                            ),
                          ).then((_) async {
                            // Refresh data when returning
                            await _refreshAllData(showMessage: false);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Expanded(
                //   child: _buildUtilityCard(
                //     Icons.warning,
                //     'Khiếu nại',
                //     'Báo cáo sự cố',
                //     Colors.red,
                //     () => _showComplaintDialog(),
                //   ),
                // ),
                // const SizedBox(width: 16),
                Expanded(
                  child: _buildUtilityCard(
                    Icons.history,
                    'Lịch sử',
                    'Xem lịch sử giao dịch',
                    Colors.green,
                    () async {
                      await context.read<RentedRoomCubit>().getBillLogHistoryByRentedRoomId(widget.rentedRoomId);
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => TenantRentedRoomBillScreen(rentedRoomId: widget.rentedRoomId,),));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildUtilityCard(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method for utility card with badge
  Widget _buildUtilityCardWithBadge(IconData icon, String title, String subtitle,
      Color color, int badgeCount, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 30),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget để tạo header cho từng phần
  Widget _buildSectionHeader(String title, String? action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action != null)
            Row(
              children: [
                Text(
                  action,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[600], size: 18),
              ],
            ),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context, bool isElectricity,
      Function(ImageSource) onSourceSelected) {
    final Color themeColor = isElectricity ? Colors.amber : Colors.blue;
    final String title = isElectricity ? 'đồng hồ điện' : 'đồng hồ nước';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chụp ảnh $title',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt, color: themeColor),
              title: Text('Chụp ảnh mới'),
              subtitle: Text('Sử dụng camera để chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                onSourceSelected(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_library, color: themeColor),
              title: Text('Chọn từ thư viện'),
              subtitle: Text('Sử dụng ảnh có sẵn trong thư viện'),
              onTap: () {
                Navigator.pop(context);
                onSourceSelected(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Gửi khiếu nại',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn loại khiếu nại',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildComplaintTypeChip('Điện'),
                _buildComplaintTypeChip('Nước'),
                _buildComplaintTypeChip('Internet'),
                _buildComplaintTypeChip('Cơ sở vật chất'),
                _buildComplaintTypeChip('An ninh'),
                _buildComplaintTypeChip('Khác'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Mô tả vấn đề',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết vấn đề của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImagePicker(
                      context,
                      true,
                      (source) {},
                    ),
                    icon: Icon(Icons.attach_file),
                    label: Text('Đính kèm'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Submit complaint
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.send),
                    label: Text('Gửi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintTypeChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {},
    );
  }

  // Helper method to get status text based on RentedRoomStatus
  String _getRentedRoomStatusText(RentedRoom? room) {
    if (room == null) return 'Đang thuê';

    switch (room.status) {
      case RentedRoomStatus.IN_USE:
        return 'Đang thuê';
      case RentedRoomStatus.PENDING:
        return 'Đang chờ xác nhận';
      case RentedRoomStatus.DEPOSIT_NOT_PAID:
        return 'Chưa thanh toán đặt cọc';
      case RentedRoomStatus.BILL_MISSING:
        return 'Thiếu hóa đơn';
      case RentedRoomStatus.DEBT:
        return 'Đang nợ';
      case RentedRoomStatus.CANCELLED:
        return 'Đã hủy';
      default:
        return 'Đang thuê';
    }
  }

  // Add the method to open contract viewer
  void _openContractViewer() {
    if (_currentRoom != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContractViewerScreen(
            roomId: widget.rentedRoomId,
            isRentedRoom: true, // This is a rented room contract
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải hợp đồng. Phòng chưa được thuê.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exitRentedRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thoát phòng'),
        content: const Text('Bạn có chắc chắn muốn thoát phòng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Thoát phòng'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final repo = RentedRoomRepositoryImpl();
    final result = await repo.exitRentedRoom(widget.rentedRoomId);
    result.when(
      success: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thoát phòng thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      },
      failure: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thoát phòng thất bại: $message'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  // Phần hợp đồng
  Widget _buildContractSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader('Quản lý hợp đồng', null),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description, color: Colors.purple),
                  ),
                  title: const Text('Xem hợp đồng'),
                  subtitle: const Text('Xem chi tiết hợp đồng thuê phòng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openContractViewer,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download, color: Colors.blue),
                  ),
                  title: const Text('Tải hợp đồng'),
                  subtitle: const Text('Lưu hợp đồng dưới dạng PDF'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _downloadContractPdf,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_document, color: Colors.green),
                  ),
                  title: const Text('Cập nhật thông tin'),
                  subtitle: const Text('Cập nhật thông tin người thuê'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openTenantInfoEditor,
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text('Thoát phòng'),
                  subtitle: const Text('Bạn sẽ rời khỏi phòng này'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exitRentedRoom,
                ),
                // Thêm mục cho Dev Mode
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.developer_mode, color: Colors.blueGrey),
                  ),
                  title: const Text('Chế độ nhà phát triển'),
                  subtitle: const Text('Chỉ dành cho nhà phát triển'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openDevMode,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
        ],
      ),
    );
  }
  
  // Method to download contract PDF
  void _downloadContractPdf() async {
    if (_currentRoom != null) {
      try {
        // Hiển thị loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Đang tải xuống PDF...'),
                ],
              ),
            );
          },
        );
        
        // Tải PDF từ API sử dụng GetIt
        final contractRepository = GetIt.I<ContractRepository>();
        final pdfBytes = await contractRepository.downloadRentedRoomContractPdf(widget.rentedRoomId);
        
        // Lưu file PDF vào application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'hopdong_${_currentRoom?.roomId ?? widget.rentedRoomId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        
        // Đóng dialog
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Mở file PDF
        final result = await OpenFile.open(file.path);
        if (result.type != 'done') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể mở file PDF: ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Đóng dialog nếu đang hiển thị
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Hiển thị thông báo lỗi
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi tải xuống PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải hợp đồng. Phòng chưa được thuê.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to open tenant info editor
  void _openTenantInfoEditor() {
    if (_currentRoom != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TenantContractInfoScreen(
            roomId: widget.rentedRoomId,
          ),
        ),
      ).then((updated) {
        if (updated == true) {
          // Reload contract data if needed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thông tin hợp đồng đã được cập nhật'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật. Phòng chưa được thuê.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to open dev mode screen
  void _openDevMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DevModeScreen(
          rentedRoomId: widget.rentedRoomId,
        ),
      ),
    ).then((_) async {
      // Refresh data when returning from dev mode
      await _refreshAllData(showMessage: true);
    });
  }
}
