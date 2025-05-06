import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/bill_log.dart';
import 'package:roomily/core/utils/bill_status.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';

import '../../data/blocs/rented_room/rented_room_cubit.dart';
import '../../data/blocs/rented_room/rented_room_state.dart';

class RentalBillingScreen extends StatefulWidget {
  final Room room;

  const RentalBillingScreen({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  State<RentalBillingScreen> createState() => _RentalBillingScreenState();
}

class _RentalBillingScreenState extends State<RentalBillingScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final RentedRoomCubit _rentedRoomCubit;
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  bool _isRefreshing = false;
  // Cache the bill log to maintain state between tab switches
  BillLog? _cachedBillLog;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _rentedRoomCubit = RentedRoomCubit(
      rentedRoomRepository: RentedRoomRepositoryImpl(),
    );
    
    // Always fetch the active bill log when the screen initializes
    _rentedRoomCubit.getActiveBillLogByRoomId(widget.room.id!);
    
    // Listen for tab changes to ensure data is loaded when returning to tabs
    _tabController.addListener(_handleTabChange);
  }
  
  void _handleTabChange() {
    // If we're switching back to the overview tab, ensure data is available
    if (_tabController.index == 0 && _cachedBillLog == null && !_isRefreshing) {
      _refreshBillLog();
    }
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _rentedRoomCubit.close();
    super.dispose();
  }

  void _refreshBillLog() {
    setState(() {
      _isRefreshing = true;
    });
    
    _rentedRoomCubit.getActiveBillLogByRoomId(widget.room.id!).then((_) {
      setState(() {
        _isRefreshing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        title: Text(
          'Quản lý hóa đơn - ${widget.room.title}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBillLog,
            color: Colors.white,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Lịch sử'),
            Tab(text: 'Cài đặt'),
          ],
        ),
      ),
      body: BlocProvider.value(
        value: _rentedRoomCubit,
        child: BlocConsumer<RentedRoomCubit, RentedRoomState>(
          listener: (context, state) {
            // When refreshing is done, update isRefreshing status
            if (_isRefreshing && state is! BillLogLoading) {
              setState(() {
                _isRefreshing = false;
              });
            }
            
            // Xử lý state khi xác nhận chỉ số thành công
            if (state is BillLogConfirmSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            // Only use billLog from the cubit state
            BillLog? billLog;
            
            if (state is BillLogSuccess) {
              // Use the bill log from the current state and cache it
              billLog = state.billLog;
              
              // Check if this is an "empty" bill (no billing period yet)
              if (billLog.id.startsWith('empty-') || (billLog.billStatus == BillStatus.MISSING && billLog.roomId == 'empty')) {
                debugPrint('Empty bill log detected: not billing period yet');
                // Set to null to trigger the "not billing period" message
                billLog = null;
              }
              
              _cachedBillLog = billLog;
            } else if (_cachedBillLog != null && !(state is BillLogLoading)) {
              // Use cached bill log when not loading and no new data available
              billLog = _cachedBillLog;
            }
            
            return TabBarView(
              controller: _tabController,
              children: [
                // Wrap each tab in a keyed widget to preserve state
                KeyedSubtree(
                  key: const ValueKey('overview_tab'),
                  child: _buildOverviewTab(billLog, state),
                ),
                KeyedSubtree(
                  key: const ValueKey('history_tab'),
                  child: _buildHistoryTab(),
                ),
                KeyedSubtree(
                  key: const ValueKey('settings_tab'),
                  child: _buildSettingsTab(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BillLog? billLog, RentedRoomState state) {
    if (state is BillLogLoading || _isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is BillLogFailure && _cachedBillLog == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Lỗi: ${state.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshBillLog,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    // If we have a failure but also cached data, show the cached data
    if (state is BillLogFailure && _cachedBillLog != null) {
      billLog = _cachedBillLog;
      // Show a small error toast but still display cached data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật: ${state.error}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
    
    if (billLog == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.blue[200]),
            const SizedBox(height: 16),
            Text(
              'Chưa đến kỳ thu tiền',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Hiện tại chưa đến kỳ thanh toán cho phòng này. Hóa đơn sẽ được tạo vào đầu tháng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    
    // Calculate dates
    final fromDate = _formatDate(billLog.fromDate);
    final toDate = _formatDate(billLog.toDate);
    
    // Calculate total amount
    final totalAmount = billLog.rentalCost + 
        (billLog.electricityBill ?? 0) + 
        (billLog.waterBill ?? 0);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(billLog),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin hóa đơn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Kỳ thanh toán', '$fromDate - $toDate'),
                  const Divider(),
                  _buildInfoRow('Tiền phòng', currencyFormat.format(billLog.rentalCost)),
                  const Divider(),
                  _buildInfoRow(
                    'Tiền điện', 
                    billLog.electricityBill != null 
                        ? currencyFormat.format(billLog.electricityBill!) 
                        : 'Chưa cập nhật',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Tiền nước', 
                    billLog.waterBill != null 
                        ? currencyFormat.format(billLog.waterBill!) 
                        : 'Chưa cập nhật',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Tổng cộng', 
                    currencyFormat.format(totalAmount), 
                    isTotal: true
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildUtilityReadingsCard(billLog),
          const SizedBox(height: 16),
          _buildActionButtons(billLog),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BillLog billLog) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String statusDescription;
    
    switch (billLog.billStatus) {
      case BillStatus.PENDING:
        statusColor = Colors.orange;
        statusText = 'Chờ thanh toán';
        statusIcon = Icons.pending_actions;
        statusDescription = 'Người thuê cần thanh toán hóa đơn này';
        break;
      case BillStatus.PAID:
        statusColor = Colors.green;
        statusText = 'Đã thanh toán';
        statusIcon = Icons.check_circle;
        statusDescription = 'Hóa đơn đã được thanh toán đầy đủ';
        break;
      case BillStatus.MISSING:
        statusColor = Colors.blue;
        statusText = 'Chưa có chỉ số';
        statusIcon = Icons.info_outline;
        statusDescription = 'Người thuê chưa cung cấp chỉ số điện nước';
        break;
      case BillStatus.CHECKING:
        statusColor = Colors.purple;
        statusText = 'Cần xác nhận';
        statusIcon = Icons.fact_check;
        statusDescription = 'Người thuê đã gửi chỉ số điện nước, bạn cần xác nhận';
        break;
      case BillStatus.WATER_RE_ENTER:
        statusColor = Colors.cyan;
        statusText = 'Yêu cầu nhập lại nước';
        statusIcon = Icons.water_drop;
        statusDescription = 'Bạn đã yêu cầu người thuê nhập lại chỉ số nước';
        break;
      case BillStatus.ELECTRICITY_RE_ENTER:
        statusColor = Colors.amber;
        statusText = 'Yêu cầu nhập lại điện';
        statusIcon = Icons.electric_bolt;
        statusDescription = 'Bạn đã yêu cầu người thuê nhập lại chỉ số điện';
        break;
      case BillStatus.RE_ENTER:
        statusColor = Colors.deepOrange;
        statusText = 'Yêu cầu nhập lại';
        statusIcon = Icons.refresh;
        statusDescription = 'Bạn đã yêu cầu người thuê nhập lại chỉ số điện nước';
        break;
      case BillStatus.CANCELLED:
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        statusIcon = Icons.cancel;
        statusDescription = 'Hóa đơn này đã bị hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không xác định';
        statusIcon = Icons.help_outline;
        statusDescription = 'Trạng thái hóa đơn không xác định';
    }
    
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusDescription,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.blueGrey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityReadingsCard(BillLog billLog) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chỉ số điện nước',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildUtilityReadingItem(
                    'Điện',
                    Icons.electric_bolt,
                    billLog.electricity != null ? '${billLog.electricity} kWh' : 'Chưa cập nhật',
                    billLog.electricityImageUrl,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUtilityReadingItem(
                    'Nước',
                    Icons.water_drop,
                    billLog.water != null ? '${billLog.water} m³' : 'Chưa cập nhật',
                    billLog.waterImageUrl,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityReadingItem(
    String label,
    IconData icon,
    String value,
    String? imageUrl,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (imageUrl != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                _showImageDialog(label, imageUrl);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, size: 14, color: color),
                    const SizedBox(width: 4),
                    const Text(
                      'Xem ảnh',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BillLog billLog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (billLog.billStatus == BillStatus.CHECKING)
          ElevatedButton.icon(
            onPressed: () {
              _showConfirmUtilityReadingsDialog(billLog);
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Xác nhận chỉ số điện nước'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
            ),
          ),

        if (billLog.billStatus == BillStatus.PENDING)
          ElevatedButton.icon(
            onPressed: () {

            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Chờ người dùng thanh toán'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
            ),
          ),

        if (billLog.billStatus == BillStatus.MISSING)
          ElevatedButton.icon(
            onPressed: () {
              // Gửi nhắc nhở tới người thuê
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi nhắc nhở tới người thuê')),
              );
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Nhắc người thuê gửi chỉ số'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<RentedRoomCubit, RentedRoomState>(
      builder: (context, state) {
        // Load bill log history when tab is built initially
        if (state is! BillLogHistoryLoading && 
            state is! BillLogHistorySuccess && 
            state is! BillLogHistoryFailure) {
          context.read<RentedRoomCubit>().getBillLogHistory(widget.room.id!);
        }
        
        if (state is BillLogHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is BillLogHistoryFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: ${state.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<RentedRoomCubit>().getBillLogHistory(widget.room.id!);
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        
        if (state is BillLogHistorySuccess) {
          final billLogs = state.billLogs;
          
          if (billLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử thanh toán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lịch sử thanh toán sẽ xuất hiện ở đây',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: billLogs.length,
            itemBuilder: (context, index) {
              final billLog = billLogs[index];
              return _buildBillHistoryItem(billLog);
            },
          );
        }
        
        // Default case - Shouldn't normally reach here
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Lịch sử thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<RentedRoomCubit>().getBillLogHistory(widget.room.id!);
                },
                child: const Text('Tải lịch sử'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildBillHistoryItem(BillLog billLog) {
    // Calculate total amount
    final totalAmount = billLog.rentalCost + 
        (billLog.electricityBill ?? 0) + 
        (billLog.waterBill ?? 0);
    
    // Format date range
    final fromDate = _formatDate(billLog.fromDate);
    final toDate = _formatDate(billLog.toDate);
    
    // Determine bill status color and icon
    Color statusColor;
    IconData statusIcon;
    
    switch (billLog.billStatus) {
      case BillStatus.PAID:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case BillStatus.CANCELLED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case BillStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.receipt_long;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Show bill details in a dialog
          _showBillDetailsDialog(billLog);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$fromDate - $toDate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getBillStatusText(billLog.billStatus),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiền phòng',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        currencyFormat.format(billLog.rentalCost),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tổng cộng',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        currencyFormat.format(totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getBillStatusText(BillStatus status) {
    switch (status) {
      case BillStatus.PENDING:
        return 'Chờ thanh toán';
      case BillStatus.PAID:
        return 'Đã thanh toán';
      case BillStatus.MISSING:
        return 'Chưa có chỉ số';
      case BillStatus.CHECKING:
        return 'Cần xác nhận';
      case BillStatus.WATER_RE_ENTER:
        return 'Nhập lại nước';
      case BillStatus.ELECTRICITY_RE_ENTER:
        return 'Nhập lại điện';
      case BillStatus.RE_ENTER:
        return 'Nhập lại chỉ số';
      case BillStatus.CANCELLED:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }
  
  void _showBillDetailsDialog(BillLog billLog) {
    final fromDate = _formatDate(billLog.fromDate);
    final toDate = _formatDate(billLog.toDate);
    
    final totalAmount = billLog.rentalCost + 
        (billLog.electricityBill ?? 0) + 
        (billLog.waterBill ?? 0);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chi tiết hóa đơn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Kỳ thanh toán: $fromDate - $toDate',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Tiền phòng', billLog.rentalCost),
              _buildDetailRow('Tiền điện', billLog.electricityBill),
              _buildDetailRow('Tiền nước', billLog.waterBill),
              const Divider(),
              _buildDetailRow('Tổng cộng', totalAmount, isTotal: true),
              const SizedBox(height: 20),
              Text(
                'Trạng thái: ${_getBillStatusText(billLog.billStatus)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, dynamic value, {bool isTotal = false}) {
    final formattedValue = value != null ? currencyFormat.format(value) : 'Không có';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formattedValue,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.blueGrey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    // This would typically include payment settings
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Cài đặt thanh toán',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tính năng này đang được phát triển',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String label, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                backgroundColor: 
                  label == 'Điện' ? Colors.amber : Colors.blue,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Chỉ số $label',
                  style: const TextStyle(color: Colors.white),
                ),
                centerTitle: true,
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Không thể tải ảnh',
                              style: TextStyle(color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showConfirmUtilityReadingsDialog(BillLog billLog) {
    bool isElectricityChecked = true;
    bool isWaterChecked = true;
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fact_check, color: Colors.purple),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Xác nhận chỉ số điện nước',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Người thuê đã gửi các chỉ số sau:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Hiển thị chỉ số và icon trong card cho trực quan
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber.withOpacity(0.3)),
                    ),
                    color: Colors.amber.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.electric_bolt, color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Chỉ số điện', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  '${billLog.electricity ?? "Chưa cung cấp"} kWh',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (billLog.electricityImageUrl != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                _showImageDialog('Điện', billLog.electricityImageUrl!);
                              },
                              icon: const Icon(Icons.image, size: 16),
                              label: const Text('Xem ảnh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.withOpacity(0.8),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(60, 32),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                    color: Colors.blue.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.water_drop, color: Colors.blue, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Chỉ số nước', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  '${billLog.water ?? "Chưa cung cấp"} m³',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (billLog.waterImageUrl != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                _showImageDialog('Nước', billLog.waterImageUrl!);
                              },
                              icon: const Icon(Icons.image, size: 16),
                              label: const Text('Xem ảnh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.withOpacity(0.8),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(60, 32),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    'Xác nhận chỉ số:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Checkboxes
                  CheckboxListTile(
                    title: const Text('Chỉ số điện chính xác'),
                    value: isElectricityChecked,
                    onChanged: (value) {
                      setState(() {
                        isElectricityChecked = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amber,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('Chỉ số nước chính xác'),
                    value: isWaterChecked,
                    onChanged: (value) {
                      setState(() {
                        isWaterChecked = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.blue,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (nếu có)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      hintText: 'Nhập ghi chú nếu cần...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Đóng dialog
                          Navigator.pop(context);
                          
                          // Hiển thị loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang xác nhận chỉ số...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          
                          // Gọi API xác nhận
                          _rentedRoomCubit.confirmUtilityReadings(
                            billLog.id,
                            isElectricityChecked: isElectricityChecked,
                            isWaterChecked: isWaterChecked,
                            landlordComment: commentController.text.isEmpty ? null : commentController.text,
                            roomId: billLog.roomId,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Xác nhận'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 