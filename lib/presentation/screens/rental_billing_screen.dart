import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/bill_log.dart';
import 'package:roomily/core/utils/bill_status.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:flutter/services.dart';

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
  
  // Thêm biến đã tải dữ liệu
  bool _initialDataLoaded = false;
  
  // Lưu trữ billLog cuối cùng đã tải thành công
  BillLog? _lastLoadedBillLog;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    debugPrint('🔄 RentalBillingScreen - initState');
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    
    _tabController = TabController(length: 2, vsync: this);
    _rentedRoomCubit = RentedRoomCubit(
      rentedRoomRepository: RentedRoomRepositoryImpl(),
    );
    
    // Đánh dấu đang trong quá trình tải ban đầu
    setState(() {
      _isRefreshing = true;
    });
    
    // Tải dữ liệu ban đầu sau khi widget đã được render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
    
    _tabController.addListener(_handleTabChange);
  }

  void _loadInitialData() {
    debugPrint('🔄 Starting _loadInitialData for roomId: ${widget.room.id}');
    
    // Đảm bảo đang trong trạng thái loading
    if (!_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });
    }
    
    // Load active bill log with proper error handling
    _rentedRoomCubit.getActiveBillLogByRoomId(widget.room.id!)
      .then((value) {
        debugPrint('✅ Successfully loaded active bill log');
        setState(() {
          _isRefreshing = false;
          _initialDataLoaded = true;
        });
      })
      .catchError((error) {
        debugPrint('❌ Error loading active bill log: $error');
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _initialDataLoaded = true; // Đánh dấu đã tải dù có lỗi
          });
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi tải dữ liệu: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    
    // Load bill history
    _rentedRoomCubit.getBillLogHistory(widget.room.id!)
      .catchError((error) {
        debugPrint('❌ Error loading bill history: $error');
      });
  }

  void _handleTabChange() {
    // Nếu chuyển đến tab overview, refresh dữ liệu
    if (_tabController.index == 0 && !_isRefreshing && _initialDataLoaded) {
      _refreshBillLog();
    }
  }
  
  @override
  void dispose() {
    debugPrint('🧹 RentalBillingScreen - dispose');
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _rentedRoomCubit.close();
    super.dispose();
  }

  void _refreshBillLog() {
    debugPrint('🔄 Refreshing bill log for roomId: ${widget.room.id}');
    
    // Hiển thị loading ngay lập tức
    setState(() {
      _isRefreshing = true;
    });
    
    // Tải lại dữ liệu dựa trên tab hiện tại
    if (_tabController.index == 0) {
      // Nếu đang ở tab overview, tải bill log hiện tại
      _rentedRoomCubit.getActiveBillLogByRoomId(widget.room.id!).then((_) {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      }).catchError((error) {
        debugPrint('❌ Error refreshing bill log: $error');
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi tải dữ liệu: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } else {
      // Nếu đang ở tab history, tải lịch sử hóa đơn
      _rentedRoomCubit.getBillLogHistory(widget.room.id!).then((_) {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      }).catchError((error) {
        debugPrint('❌ Error refreshing bill history: $error');
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint('🏗️ Building RentalBillingScreen');
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.room.title,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Quản lý hóa đơn',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBillLog,
            color: Colors.black87,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black87,
          indicatorWeight: 3,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(
              text: 'Tổng quan',
            ),
            Tab(
              text: 'Lịch sử',
            ),
          ],
        ),
      ),
      body: BlocProvider<RentedRoomCubit>.value(
        value: _rentedRoomCubit,
        child: BlocConsumer<RentedRoomCubit, RentedRoomState>(
          listenWhen: (previous, current) {
            // Theo dõi các thay đổi state
            debugPrint('💫 State transition: ${previous.runtimeType} -> ${current.runtimeType}');
            return true;
          },
          listener: (context, state) {
            // Lưu trữ bill log khi tải thành công để tránh mất dữ liệu
            if (state is BillLogSuccess) {
              debugPrint('💾 Caching successful bill log: ${state.billLog.id}');
              _lastLoadedBillLog = state.billLog;
            }
            
            // Khi trạng thái loading kết thúc, update isRefreshing status
            if (_isRefreshing && state is! BillLogLoading) {
              setState(() {
                _isRefreshing = false;
              });
            }
            
            // Xử lý state khi xác nhận chỉ số thành công
            if (state is BillLogConfirmSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(8),
                ),
              );
            }
          },
          builder: (context, state) {
            debugPrint('🏗️ BlocBuilder building with state: ${state.runtimeType}');
            
            // Kiểm tra trạng thái loading - gồm cả flag _isRefreshing và state is BillLogLoading
            // Thêm logic kiểm tra !_initialDataLoaded để hiển thị loading cho lần tải đầu tiên
            final bool isLoading = _isRefreshing || 
                                   state is BillLogLoading || 
                                   !_initialDataLoaded;
            
            // Xác định bill data từ state hoặc cache
            BillLog? billData;
            if (state is BillLogSuccess) {
              billData = state.billLog;
              debugPrint('📋 Using bill data from BillLogSuccess: ${billData.id}');
            } else if (_lastLoadedBillLog != null) {
              // Sử dụng dữ liệu đã cache nếu state hiện tại không có bill data
              billData = _lastLoadedBillLog;
              debugPrint('📋 Using cached bill data: ${billData?.id}');
            }
            
            // Kiểm tra nếu là empty bill
            bool isEmptyBill = false;
            if (billData != null) {
              if (billData.id.startsWith('empty-') && 
                  billData.billStatus == BillStatus.MISSING && 
                  billData.roomId == 'empty') {
                isEmptyBill = true;
                debugPrint('⚠️ Empty bill detected with id: ${billData.id}');
              }
            }
            
            // Quyết định hiển thị bill hay empty state dựa trên các điều kiện
            final bool showBillData = billData != null && !isEmptyBill;
            
            // Generate a unique key for TabBarView
            final String overviewKey = 'overview_${showBillData ? 'has_data' : 'no_data'}_${isLoading ? 'loading' : 'ready'}';
            debugPrint('🔑 Overview tab key: $overviewKey, isLoading: $isLoading');
            
            // Tạo TabBarView với hai tab
            return TabBarView(
              controller: _tabController,
              children: [
                // Overview tab with key that changes with state
                KeyedSubtree(
                  key: ValueKey(overviewKey),
                  child: _tabController.index == 0 && isLoading
                    ? _buildLoadingView()
                    : _buildOverviewTab(billData, state),
                ),
                
                // History tab
                KeyedSubtree(
                  key: const ValueKey('history_tab'),
                  child: _buildHistoryTab(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Tách riêng widget hiển thị loading để có thể tùy chỉnh
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Đang tải thông tin hóa đơn...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BillLog? billLog, RentedRoomState state) {
    // Debug log để xác định vấn đề
    debugPrint('🏗️ _buildOverviewTab called with billLog: ${billLog?.id}, state: ${state.runtimeType}');
    
    // Xử lý trường hợp lỗi
    if (state is BillLogFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi: ${state.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshBillLog,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Kiểm tra nếu là empty bill - phải thỏa mãn TẤT CẢ các điều kiện
    bool isEmptyBill = false;
    if (billLog != null) {
      if (billLog.id.startsWith('empty-') && 
          billLog.billStatus == BillStatus.MISSING && 
          billLog.roomId == 'empty') {
        debugPrint('⚠️ Empty bill confirmed: ${billLog.id}');
        isEmptyBill = true;
      } else {
        debugPrint('✅ Valid bill log found: ${billLog.id}');
      }
    } else {
      debugPrint('⚠️ billLog is null');
    }

    // Hiển thị thông báo chưa đến kỳ thu tiền khi không có bill data hoặc là empty bill
    if (billLog == null || isEmptyBill) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today, size: 80, color: Colors.blue[300]),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa đến kỳ thu tiền',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Hiện tại chưa đến kỳ thanh toán cho phòng này.\nHóa đơn sẽ được tạo vào đầu tháng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshBillLog,
              icon: const Icon(Icons.refresh),
              label: const Text('Kiểm tra lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Hiển thị chi tiết hóa đơn
    final fromDate = _formatDate(billLog.fromDate);
    final toDate = _formatDate(billLog.toDate);
    final totalAmount = billLog.rentalCost +
        (billLog.electricityBill ?? 0) +
        (billLog.waterBill ?? 0);

    return RefreshIndicator(
      onRefresh: () async {
        _refreshBillLog();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(billLog),
            const SizedBox(height: 16),
            _buildBillInfoCard(billLog, fromDate, toDate, totalAmount),
            const SizedBox(height: 16),
            _buildUtilityReadingsCard(billLog),
            const SizedBox(height: 16),
            _buildActionButtons(billLog),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BillLog billLog) {
    final (color, icon, text, description) = _getBillStatusInfo(billLog.billStatus);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.95),
            color.withOpacity(0.8),
          ],
          stops: const [0.2, 0.8],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillInfoCard(BillLog billLog, String fromDate, String toDate, double totalAmount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blueGrey[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Chi tiết hóa đơn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blueGrey[400], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$fromDate - $toDate',
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildBillItem(
              'Tiền phòng',
              billLog.rentalCost.toDouble(),
              Icons.home,
              Colors.indigo,
            ),
            _buildBillItem(
              'Tiền điện',
              (billLog.electricityBill ?? 0).toDouble(),
              Icons.electric_bolt,
              Colors.amber,
            ),
            _buildBillItem(
              'Tiền nước',
              (billLog.waterBill ?? 0).toDouble(),
              Icons.water_drop,
              Colors.blue,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(thickness: 1),
            ),
            _buildBillItem(
              'Tổng cộng',
              totalAmount,
              Icons.account_balance_wallet,
              Colors.green,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillItem(String label, double amount, IconData icon, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? Colors.green[700] : Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityReadingsCard(BillLog billLog) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.blueGrey[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Chỉ số điện nước',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
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
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (imageUrl != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _showImageDialog(label, imageUrl),
              icon: Icon(Icons.image, size: 16, color: color),
              label: const Text('Xem ảnh'),
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BillLog billLog) {
    if (billLog.billStatus != BillStatus.CHECKING) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showConfirmUtilityReadingsDialog(billLog),
        icon: const Icon(Icons.check_circle),
        label: const Text('Xác nhận chỉ số điện nước'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<RentedRoomCubit, RentedRoomState>(
      builder: (context, state) {
        // Hiển thị loading khi đang tải
        if (_isRefreshing || state is BillLogHistoryLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Đang tải lịch sử hóa đơn...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Load bill log history when tab is built initially
        if (state is! BillLogHistoryLoading && 
            state is! BillLogHistorySuccess && 
            state is! BillLogHistoryFailure) {
          // Bắt đầu tải lịch sử hóa đơn
          context.read<RentedRoomCubit>().getBillLogHistory(widget.room.id!);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Đang tải lịch sử hóa đơn...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
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
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isRefreshing = true;
                    });
                    context.read<RentedRoomCubit>().getBillLogHistory(widget.room.id!).then((_) {
                      if (mounted) {
                        setState(() {
                          _isRefreshing = false;
                        });
                      }
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
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
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isRefreshing = true;
              });
              await context.read<RentedRoomCubit>().getBillLogHistory(widget.room.id!);
              if (mounted) {
                setState(() {
                  _isRefreshing = false;
                });
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: billLogs.length,
              itemBuilder: (context, index) {
                final billLog = billLogs[index];
                return _buildBillHistoryItem(billLog);
              },
            ),
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
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isRefreshing = true;
                  });
                  context.read<RentedRoomCubit>().getBillLogHistory(widget.room.id!).then((_) {
                    if (mounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lịch sử'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
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
        return 'Yêu cầu nhập lại nước';
      case BillStatus.ELECTRICITY_RE_ENTER:
        return 'Yêu cầu nhập lại điện';
      case BillStatus.RE_ENTER:
        return 'Yêu cầu nhập lại';
      case BillStatus.CANCELLED:
        return 'Đã hủy';
      case BillStatus.LATE:
        return 'Trễ hạn';
      case BillStatus.LATE_PAID:
        return 'Trễ hạn thanh toán';
      case BillStatus.UNPAID:
        return 'Chưa thanh toán';
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

  (Color, IconData, String, String) _getBillStatusInfo(BillStatus status) {
    switch (status) {
      case BillStatus.PENDING:
        return (
          const Color(0xFFFF9800), // Màu cam ấm áp
          Icons.pending_actions,
          'Chờ thanh toán',
          'Người thuê cần thanh toán hóa đơn này'
        );
      case BillStatus.PAID:
        return (
          const Color(0xFF4CAF50), // Màu xanh lá tươi sáng
          Icons.check_circle,
          'Đã thanh toán',
          'Hóa đơn đã được thanh toán đầy đủ'
        );
      case BillStatus.MISSING:
        return (
          const Color(0xFF42A5F5), // Màu xanh dương nhẹ nhàng
          Icons.info_outline,
          'Chưa có chỉ số',
          'Người thuê chưa cung cấp chỉ số điện nước'
        );
      case BillStatus.CHECKING:
        return (
          const Color(0xFF7E57C2), // Màu tím nhẹ
          Icons.fact_check,
          'Cần xác nhận',
          'Người thuê đã gửi chỉ số điện nước, bạn cần xác nhận'
        );
      case BillStatus.WATER_RE_ENTER:
        return (
          const Color(0xFF26C6DA), // Màu xanh nước biển
          Icons.water_drop,
          'Yêu cầu nhập lại nước',
          'Bạn đã yêu cầu người thuê nhập lại chỉ số nước'
        );
      case BillStatus.ELECTRICITY_RE_ENTER:
        return (
          const Color(0xFFFFB300), // Màu vàng đậm
          Icons.electric_bolt,
          'Yêu cầu nhập lại điện',
          'Bạn đã yêu cầu người thuê nhập lại chỉ số điện'
        );
      case BillStatus.RE_ENTER:
        return (
          const Color(0xFFFF7043), // Màu cam đỏ
          Icons.refresh,
          'Yêu cầu nhập lại',
          'Bạn đã yêu cầu người thuê nhập lại chỉ số điện nước'
        );
      case BillStatus.CANCELLED:
        return (
          const Color(0xFFEF5350), // Màu đỏ nhạt
          Icons.cancel,
          'Đã hủy',
          'Hóa đơn này đã bị hủy'
        );
      case BillStatus.LATE:
        return (
          const Color(0xFFE53935), // Màu đỏ đậm
          Icons.warning,
          'Trễ hạn',
          'Hóa đơn này đã quá hạn thanh toán'
        );
      case BillStatus.LATE_PAID:
        return (
          const Color(0xFFFF5252), // Màu đỏ tươi
          Icons.warning,
          'Trễ hạn thanh toán',
          'Người thuê đã thanh toán trễ hạn hóa đơn này'
        );
      case BillStatus.UNPAID:
        return (
          const Color(0xFFD32F2F), // Màu đỏ sẫm
          Icons.error,
          'Chưa thanh toán',
          'Người thuê chưa thanh toán hóa đơn này'
        );
      default:
        return (
          const Color(0xFF9E9E9E), // Màu xám trung tính
          Icons.help_outline,
          'Không xác định',
          'Trạng thái hóa đơn không xác định'
        );
    }
  }
} 