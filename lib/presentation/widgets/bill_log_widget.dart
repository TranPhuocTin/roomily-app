import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/presentation/widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';
import 'package:roomily/core/utils/bill_status.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import '../../data/blocs/rented_room/rented_room_cubit.dart';
import '../../data/blocs/rented_room/rented_room_state.dart';

class BillLogWidget extends StatefulWidget {
  final String rentedRoomId;
  final BillLog? initialBillLog; // Thêm tham số cho dữ liệu prefetch
  final bool autoLoad; // Cho phép tắt tự động tải dữ liệu

  const BillLogWidget({
    Key? key,
    required this.rentedRoomId,
    this.initialBillLog, // Dữ liệu prefetch từ màn hình cha
    this.autoLoad = true, // Mặc định là tự động tải nếu không có dữ liệu prefetch
  }) : super(key: key);

  @override
  State<BillLogWidget> createState() => _BillLogWidgetState();
}

class _BillLogWidgetState extends State<BillLogWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Add a local flag to track whether we're submitting readings
  bool _isSubmittingReadings = false;
  
  // Add a key to force rebuild when needed
  Key _billLogKey = UniqueKey();
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );
    
    _animationController.forward();
    
    // Chỉ tải dữ liệu khi không có dữ liệu prefetch và autoLoad = true
    if (widget.initialBillLog == null && widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('Initial data load - no prefetched data available');
          _loadActiveBillLog();
        }
      });
    } else if (widget.initialBillLog != null) {
      debugPrint('Using prefetched BillLog data with ID: ${widget.initialBillLog!.id}');
      // Nếu có dữ liệu prefetch, kiểm tra xem dữ liệu có trong trạng thái CHECKING hay không
      if (widget.initialBillLog!.billStatus == BillStatus.CHECKING) {
        setState(() {
          _isSubmittingReadings = true;
        });
      }
    }
  }
  
  // Helper method to load active bill log
  void _loadActiveBillLog() {
    debugPrint('Calling getActiveBillLog for rentedRoomId: ${widget.rentedRoomId}');
    context.read<RentedRoomCubit>().getActiveBillLog(widget.rentedRoomId);
  }
  
  // Force rebuild the entire widget with a new key
  void _forceCompleteRebuild() {
    if (mounted) {
      setState(() {
        _billLogKey = UniqueKey();
        debugPrint('Forcing complete UI rebuild with new key: $_billLogKey');
      });
    }
  }
  
  // Force refresh UI with latest data
  void _forceRefresh() {
    if (mounted) {
      setState(() {
        debugPrint('Forcing UI refresh');
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Add a helper method to check if a bill log is empty
  bool _isBillLogEmpty(BillLog? billLog) {
    if (billLog == null) return true;
    return billLog.id.startsWith('empty-') || 
           (billLog.billStatus == BillStatus.MISSING && billLog.roomId == 'empty');
  }

  @override
  void didUpdateWidget(covariant BillLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data khi widget được cập nhật với rentedRoomId mới hoặc khi initialBillLog thay đổi
    if (oldWidget.rentedRoomId != widget.rentedRoomId || 
        oldWidget.initialBillLog?.id != widget.initialBillLog?.id) {
      debugPrint('rentedRoomId or initialBillLog changed, reloading data');
      
      // Nếu có dữ liệu prefetch mới, sử dụng nó thay vì gọi API
      if (widget.initialBillLog != null && 
          (oldWidget.initialBillLog == null || oldWidget.initialBillLog?.id != widget.initialBillLog?.id)) {
        debugPrint('Using new prefetched BillLog data with ID: ${widget.initialBillLog!.id}');
        // Kiểm tra trạng thái CHECKING
        if (widget.initialBillLog!.billStatus == BillStatus.CHECKING) {
          setState(() {
            _isSubmittingReadings = true;
          });
        }
        // Force rebuild to apply the new data
        _forceCompleteRebuild();
      } else if (widget.autoLoad) {
        // Nếu không có dữ liệu prefetch mới và autoLoad = true, gọi API
        _loadActiveBillLog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu có dữ liệu prefetch và chưa có dữ liệu từ Cubit, hiển thị ngay dữ liệu prefetch
    if (widget.initialBillLog != null && (context.watch<RentedRoomCubit>().state is RentedRoomInitial)) {
      // Check if the prefetched data is an empty bill log
      if (_isBillLogEmpty(widget.initialBillLog)) {
        debugPrint('Prefetched bill log is empty, showing empty state');
        return _buildEmptyState();
      }
      
      return FadeTransition(
        opacity: _fadeAnimation,
        child: KeyedSubtree(
          key: ValueKey<String>('prefetched-bill-${widget.initialBillLog!.id}-${widget.initialBillLog!.billStatus}-$_isSubmittingReadings'),
          child: _buildBillView(widget.initialBillLog!),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: MultiBlocListener(
        listeners: [
          BlocListener<RentedRoomCubit, RentedRoomState>(
            listener: (context, state) {
              debugPrint('BlocListener triggered with state: ${state.runtimeType}');
              
              if (state is BillLogFailure) {
                // Reset submission flag on error
                setState(() {
                  debugPrint('Resetting _isSubmittingReadings to false due to BillLogFailure');
                  _isSubmittingReadings = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${state.error}'),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Thử lại',
                      onPressed: () {
                        _loadActiveBillLog();
                      },
                      textColor: Colors.white,
                    ),
                  ),
                );
              } else if (state is BillLogSuccess) {
                // Log bill status for debugging
                debugPrint('Got BillLogSuccess: billStatus=${state.billLog.billStatus}, isSubmitting=$_isSubmittingReadings, billId=${state.billLog.id}');
                
                // Dừng animation hiện tại và bắt đầu lại để tạo hiệu ứng fresh
                _animationController.reset();
                _animationController.forward();
                
                // Force complete rebuild to ensure the UI is updated with the newest data
                _forceCompleteRebuild();
                
                // Always check and reset submission flag regardless of previous state
                if (_isSubmittingReadings) {
                  setState(() {
                    debugPrint('Resetting _isSubmittingReadings to false due to BillLogSuccess with ${state.billLog.billStatus}');
                    _isSubmittingReadings = false;
                  });
                }
                
                // Display success message if one is provided
                if (state.message != null) {
                  // Check if this is a CHECKING status after update
                  if (state.billLog.billStatus == BillStatus.CHECKING) {
                    // For utility reading submission, show a more specific message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chỉ số đang được kiểm tra bởi chủ trọ'),
                        backgroundColor: Colors.purple,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    // For other success states
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message!),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } else if (state is BillLogConfirmSuccess) {
                // Debug log for confirmation success
                debugPrint('Got BillLogConfirmSuccess: ${state.message}');
                
                // IMPORTANT: Immediately mark readings as submitted
                // This ensures the button disappears right away
                setState(() {
                  debugPrint('Setting _isSubmittingReadings to true due to BillLogConfirmSuccess');
                  _isSubmittingReadings = true;
                });
                
                // Force complete rebuild to ensure UI reflects state immediately
                _forceCompleteRebuild();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Note: We don't need to call getActiveBillLog here
                // because the Cubit already does this automatically
              } else if (state is BillLogLoading) {
                // We don't need to change _isSubmittingReadings here
                // as it should be set by the action that triggered the loading
                debugPrint('Got BillLogLoading, current _isSubmittingReadings: $_isSubmittingReadings');
              }
            },
          ),
        ],
        child: KeyedSubtree(
          key: _billLogKey,
          child: BlocBuilder<RentedRoomCubit, RentedRoomState>(
            builder: (context, state) {
              // Debug log to verify builder execution with exact state type
              debugPrint('Building BillLogWidget with state: ${state.runtimeType}');
              
              // Force setState để refresh UI khi nhận được BillLogSuccess
              if (state is BillLogSuccess) {
                debugPrint('BlocBuilder received BillLogSuccess with billStatus=${state.billLog.billStatus}');
              }
              
              if (state is BillLogLoading) {
                // Nếu có dữ liệu prefetch, sử dụng nó thay vì hiển thị loading
                if (widget.initialBillLog != null) {
                  debugPrint('Using prefetched data during loading state');
                  return _buildBillView(widget.initialBillLog!);
                }
                // Khi lần đầu truy cập, hiển thị shimmer chỉ header
                return _buildHeaderShimmerView();
              } else if (state is BillLogSuccess) {
                // Kiểm tra xem bill log có rỗng không
                if (_isBillLogEmpty(state.billLog)) {
                  debugPrint('Bill log is empty, showing empty state');
                  return _buildEmptyState();
                }
                
                // Bọc widget kết quả với ValueKey để đảm bảo Flutter rebuild widget khi bill status thay đổi
                return KeyedSubtree(
                  key: ValueKey<String>('bill-${state.billLog.id}-${state.billLog.billStatus}-$_isSubmittingReadings'),
                  child: _buildBillView(state.billLog),
                );
              } else if (state is BillLogFailure) {
                // Nếu có lỗi nhưng có dữ liệu prefetch, vẫn hiển thị dữ liệu prefetch
                if (widget.initialBillLog != null) {
                  debugPrint('Using prefetched data despite error state');
                  
                  // Check if the prefetched data is an empty bill log
                  if (_isBillLogEmpty(widget.initialBillLog)) {
                    debugPrint('Prefetched bill log is empty in error state, showing empty state');
                    return _buildEmptyState();
                  }
                  
                  return _buildBillView(widget.initialBillLog!);
                }
                return _buildErrorView(state.error);
              } else if (state is BillLogConfirmSuccess) {
                // Khi nhận trạng thái BillLogConfirmSuccess, hiển thị loading thu gọn
                // vì chúng ta biết rằng đang chờ kết quả sau khi đã gửi chỉ số
                debugPrint('Showing collapsed loading view due to BillLogConfirmSuccess');
                return _buildCollapsedLoadingView();
              } else if (state is RentedRoomInitial) {
                // Initial state case - nếu có dữ liệu prefetch, hiển thị nó
                if (widget.initialBillLog != null) {
                  debugPrint('Using prefetched data in initial state');
                  return _buildBillView(widget.initialBillLog!);
                }
                // Khi lần đầu truy cập, hiển thị shimmer header
                return _buildHeaderShimmerView();
              }
              
              // Fallback - nếu có dữ liệu prefetch, hiển thị nó
              if (widget.initialBillLog != null) {
                debugPrint('Using prefetched data in fallback case');
                
                // Check if the prefetched data is an empty bill log
                if (_isBillLogEmpty(widget.initialBillLog)) {
                  debugPrint('Prefetched bill log is empty in fallback, showing empty state');
                  return _buildEmptyState();
                }
                
                return _buildBillView(widget.initialBillLog!);
              }
              
              debugPrint('Unknown state, showing header shimmer view');
              return _buildHeaderShimmerView();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    // Kiểm tra nếu là đang trong trạng thái CHECKING hoặc đang gửi chỉ số
    // thì hiển thị shimmer thu gọn, nếu không thì hiển thị shimmer đầy đủ
    if (_isSubmittingReadings) {
      return _buildCollapsedLoadingView();
    } else {
      return _buildHeaderShimmerView();  // Mặc định chỉ hiển thị header shimmer
    }
  }

  // Shimmer mới chỉ cho header của ExpansionTile
  Widget _buildHeaderShimmerView() {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          title: Row(
            children: [
              // Tạo shimmer cho icon
              Container(
                padding: const EdgeInsets.all(4),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              // Tạo shimmer cho text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: 100,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              // Tạo shimmer cho status badge
              Container(
                height: 22,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ],
          ),
          trailing: Container(
            width: 24,
            height: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Shimmer cho trạng thái đầy đủ (expanded)
  Widget _buildExpandedLoadingView() {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: 150,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 22,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content shimmer
            Container(
              height: 12,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Container(
              height: 12,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Container(
              height: 12,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Container(
              height: 12,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            
            // Bottom action shimmer
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 40,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer cho trạng thái thu gọn (collapsed)
  Widget _buildCollapsedLoadingView() {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 12,
                    width: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 120,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Container(
              height: 22,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Không thể tải thông tin hóa đơn',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _loadActiveBillLog();
            },
            icon: Icon(Icons.refresh),
            label: Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillView(BillLog billLog) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    
    // Debug log cho billLog status mỗi khi component build
    debugPrint('_buildBillView called with billStatus=${billLog.billStatus}, id=${billLog.id}');
    
    // Validate and fix inconsistent state
    // If the bill is in CHECKING state but _isSubmittingReadings is false,
    // we should update the flag to be consistent
    if (billLog.billStatus == BillStatus.CHECKING && !_isSubmittingReadings) {
      debugPrint('State inconsistency detected: Bill is CHECKING but _isSubmittingReadings=false');
      // Fix the state without triggering a setState to avoid an infinite loop
      Future.microtask(() {
        if (mounted) {
          setState(() {
            debugPrint('Fixing state: setting _isSubmittingReadings=true');
            _isSubmittingReadings = true;
            // Force rebuild to apply the change
            _forceCompleteRebuild();
          });
        }
      });
    }
    
    // Format dates
    String fromDate = _formatDate(billLog.fromDate);
    String toDate = _formatDate(billLog.toDate);
    
    // Determine bill status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (billLog.billStatus) {
      case BillStatus.PENDING:
        statusColor = Colors.orange;
        statusText = 'Chờ thanh toán';
        statusIcon = Icons.pending_actions;
        break;
      case BillStatus.PAID:
        statusColor = Colors.green;
        statusText = 'Đã thanh toán';
        statusIcon = Icons.check_circle;
        break;
      case BillStatus.UNPAID:
        statusColor = Colors.orange;
        statusText = 'Chưa thanh toán';
        statusIcon = Icons.money_off_sharp;
      case BillStatus.CANCELLED:
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        statusIcon = Icons.cancel;
        break;
      case BillStatus.MISSING:
        statusColor = Colors.blue;
        statusText = 'Chưa cập nhật';
        statusIcon = Icons.info;
        break;
      case BillStatus.CHECKING:
        statusColor = Colors.purple;
        statusText = 'Đang kiểm tra';
        statusIcon = Icons.search;
        break;
      case BillStatus.WATER_RE_ENTER:
        statusColor = Colors.cyan;
        statusText = 'Cần nhập lại chỉ số nước';
        statusIcon = Icons.water_drop;
        break;
      case BillStatus.ELECTRICITY_RE_ENTER:
        statusColor = Colors.amber;
        statusText = 'Cần nhập lại chỉ số điện';
        statusIcon = Icons.electric_bolt;
        break;
      case BillStatus.RE_ENTER:
        statusColor = Colors.deepOrange;
        statusText = 'Cần nhập lại chỉ số';
        statusIcon = Icons.refresh;
        break;
      default:
        statusColor = Colors.blue;
        statusText = billLog.billStatus.toString().split('.').last;
        statusIcon = Icons.receipt;
    }

    // Calculate total amount
    double totalAmount = billLog.rentalCost +
        (billLog.electricityBill ?? 0) + 
        (billLog.waterBill ?? 0);

    if(billLog.rentalCostPaid == true) {
      totalAmount -= billLog.rentalCost;
    }
        
    // Determine if the update button should be shown
    // Debug logging for visibility decision
    debugPrint('Button visibility calculation: isSubmitting=$_isSubmittingReadings, status=${billLog.billStatus}');
    
    final bool showUpdateButton = !_isSubmittingReadings && (
        billLog.billStatus == BillStatus.MISSING || 
        billLog.billStatus == BillStatus.RE_ENTER || 
        billLog.billStatus == BillStatus.WATER_RE_ENTER || 
        billLog.billStatus == BillStatus.ELECTRICITY_RE_ENTER
    );
    
    debugPrint('Show update button: $showUpdateButton');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: _buildBillHeader(billLog, currencyFormat, statusColor, statusText, statusIcon, totalAmount),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Kỳ thanh toán: $fromDate - $toDate',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              if(billLog.rentalCostPaid == false || billLog.electricityBill != null ||
                 billLog.waterBill != null)
                _buildBillSection('Chi tiết hóa đơn'),
              
              if(billLog.rentalCostPaid == false)
                _buildBillItem(
                  'Tiền thuê phòng',
                  currencyFormat.format(billLog.rentalCost),
                  icon: Icons.home,
                  iconColor: Colors.green,
                ),
              
              if (billLog.electricityBill != null)
                _buildBillItem(
                  'Tiền điện ${billLog.electricity != null ? "(${billLog.electricity} kWh)" : ""}', 
                  currencyFormat.format(billLog.electricityBill!),
                  icon: Icons.electric_bolt,
                  iconColor: Colors.amber,
                ),
              
              if (billLog.waterBill != null)
                _buildBillItem(
                  'Tiền nước ${billLog.water != null ? "(${billLog.water} m³)" : ""}', 
                  currencyFormat.format(billLog.waterBill!),
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                ),
              
              if (billLog.billStatus == BillStatus.RE_ENTER || 
                  billLog.billStatus == BillStatus.WATER_RE_ENTER || 
                  billLog.billStatus == BillStatus.ELECTRICITY_RE_ENTER)
                _buildInfoMessage(
                  'Cần nhập lại chỉ số điện nước',
                  icon: Icons.warning_amber,
                  color: Colors.amber,
                ),
                
              const SizedBox(height: 8),
              Divider(thickness: 1, color: Colors.grey[200]),
              const SizedBox(height: 8),
              if(billLog.rentalCostPaid == false || billLog.electricityBill != null ||
                 billLog.waterBill != null)
                  _buildTotalAmount('Tổng cộng', currencyFormat.format(totalAmount)),
              
              const SizedBox(height: 16),
              
              if (billLog.billStatus == BillStatus.PENDING)
                _buildActionButton(
                  'Thanh toán ngay',
                  Icons.payment,
                  Colors.green,
                  () => _handlePayment(context, billLog),
                ),
                
              if (showUpdateButton)
                _buildActionButton(
                  'Cập nhật chỉ số điện nước',
                  Icons.update,
                  Colors.teal,
                  () => _showUtilityReadingDialog(context, billLog),
                ),
                
              if (_isSubmittingReadings && billLog.billStatus != BillStatus.CHECKING)
                _buildInfoMessage(
                  'Đang gửi chỉ số, vui lòng đợi...',
                  icon: Icons.sync,
                  color: Colors.teal,
                ),
                
              if (billLog.billStatus == BillStatus.CHECKING || 
                  (_isSubmittingReadings && 
                   (billLog.billStatus == BillStatus.MISSING || 
                    billLog.billStatus == BillStatus.RE_ENTER || 
                    billLog.billStatus == BillStatus.WATER_RE_ENTER || 
                    billLog.billStatus == BillStatus.ELECTRICITY_RE_ENTER)))
                _buildInfoMessage(
                  'Chỉ số đang được kiểm tra',
                  icon: Icons.hourglass_empty,
                  color: Colors.purple,
                ),
                
              if (billLog.electricityImageUrl != null || billLog.waterImageUrl != null)
                Container(
                  margin: EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMeterImageButton(
                        context, 
                        Icons.electric_bolt, 
                        'Hình ảnh đồng hồ điện', 
                        billLog.electricityImageUrl
                      ),
                      const SizedBox(width: 12),
                      _buildMeterImageButton(
                        context, 
                        Icons.water_drop, 
                        'Hình ảnh đồng hồ nước', 
                        billLog.waterImageUrl
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillHeader(
    BillLog billLog,
    NumberFormat currencyFormat,
    Color statusColor,
    String statusText,
    IconData statusIcon,
    double totalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Month and amount in a more compact layout
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tháng ${_getMonthYear(billLog.fromDate)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        currencyFormat.format(totalAmount),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Status badge with more compact design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildBillItem(String label, String amount, {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: EdgeInsets.all(6),
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor ?? Colors.blue),
            ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMessage(String message, {required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMeterImageButton(BuildContext context, IconData icon, String label, String? imageUrl) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: imageUrl == null ? null : () {
          _showMeterImage(context, label, imageUrl);
        },
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  void _showMeterImage(BuildContext context, String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Không thể tải hình ảnh',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement download function
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tính năng đang phát triển'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        icon: Icon(Icons.download),
                        label: Text('Tải xuống'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Đóng'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
  
  String _getMonthYear(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  void _showUtilityReadingDialog(BuildContext context, BillLog billLog) {
    final TextEditingController electricityController = TextEditingController();
    final TextEditingController waterController = TextEditingController();
    
    // Pre-fill with current values if available
    if (billLog.electricity != null) {
      electricityController.text = (billLog.electricity! + 1).toString(); // Default to current + 1
    }
    if (billLog.water != null) {
      waterController.text = (billLog.water! + 1).toString(); // Default to current + 1
    }
    
    // Track selected images
    File? electricityImage;
    File? waterImage;

    final picker = ImagePicker();
    
    Future<void> _getImage(ImageSource source, bool isElectricity) async {
      try {
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1000,
        );
        
        if (pickedFile != null) {
          if (isElectricity) {
            electricityImage = File(pickedFile.path);
          } else {
            waterImage = File(pickedFile.path);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    // Function to handle the submission process with improved validation
    void _handleSubmission() {
      // Validate inputs
      if (electricityController.text.isEmpty || waterController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập đầy đủ các chỉ số'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Ensure input values are valid integers
      final int? electricity = int.tryParse(electricityController.text);
      final int? water = int.tryParse(waterController.text);
      
      if (electricity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ số điện không hợp lệ. Vui lòng nhập số nguyên'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (water == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ số nước không hợp lệ. Vui lòng nhập số nguyên'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Get previous readings
      final int prevElectricity = billLog.electricity ?? 0;
      final int prevWater = billLog.water ?? 0;
      
      // Validate if new readings are greater than previous ones
      if (electricity < prevElectricity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ số điện mới phải lớn hơn chỉ số cũ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (water < prevWater) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ số nước mới phải lớn hơn chỉ số cũ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Helper method to proceed with submission
      void proceedWithSubmission(int elec, int wtr) {
        // Close dialog first
        Navigator.pop(context);
        
        // Immediately set the submission flag to hide the button right away
        this.setState(() {
          debugPrint('Setting _isSubmittingReadings = true BEFORE API call');
          _isSubmittingReadings = true;
        });
        
        // Force complete rebuild right now to hide button immediately
        _forceCompleteRebuild();

        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text('Đang cập nhật chỉ số điện nước...'),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Make API call
        debugPrint('Calling updateUtilityReadings with E:$elec, W:$wtr');
        context.read<RentedRoomCubit>().updateUtilityReadings(
          billLog.id,
          elec,
          wtr,
          widget.rentedRoomId,
          electricityImage: electricityImage,
          waterImage: waterImage,
        );
      }
      
      // Validate if readings seem unreasonably high
      if (electricity > prevElectricity + 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chỉ số điện tăng nhiều bất thường. Vui lòng kiểm tra lại'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Vẫn gửi',
              textColor: Colors.white,
              onPressed: () => proceedWithSubmission(electricity, water),
            ),
          ),
        );
        return;
      }
      
      if (water > prevWater + 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chỉ số nước tăng nhiều bất thường. Vui lòng kiểm tra lại'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Vẫn gửi',
              textColor: Colors.white,
              onPressed: () => proceedWithSubmission(electricity, water),
            ),
          ),
        );
        return;
      }
      
      // If all validations pass, proceed with submission
      proceedWithSubmission(electricity, water);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.document_scanner_outlined, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cập nhật chỉ số điện nước',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          Text(
                            'Ghi nhận chỉ số cho kỳ thanh toán ${_getMonthYear(billLog.fromDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.teal.shade300),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Electricity section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.teal.withOpacity(0.3), width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.electric_bolt, color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Chỉ số điện',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Current reading display
                      if (billLog.electricity != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Chỉ số hiện tại: ',
                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              ),
                              Text(
                                '${billLog.electricity} kWh',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: 16),
                      
                      // New reading input with improved validation
                      TextField(
                        controller: electricityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Chỉ số mới',
                          hintText: 'Nhập chỉ số điện hiện tại',
                          prefixIcon: const Icon(Icons.numbers, color: Colors.teal),
                          suffixText: 'kWh',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.teal),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Image selector
                      InkWell(
                        onTap: () => _showImagePickerForType(
                          context, 
                          'electricity',
                          (source) async {
                            await _getImage(source, true);
                            setState(() {});
                          }
                        ),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: electricityImage != null 
                                  ? Colors.teal 
                                  : Colors.grey[300]!,
                              width: electricityImage != null ? 2 : 1,
                            ),
                          ),
                          child: electricityImage != null
                              ? Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        electricityImage!,
                                        width: double.infinity,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            electricityImage = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap: () {
                                          _showImagePickerForType(
                                            context, 
                                            'electricity',
                                            (source) async {
                                              await _getImage(source, true);
                                              setState(() {});
                                            }
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(10),
                                              bottomLeft: Radius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Đổi ảnh',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt, color: Colors.teal, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Chụp ảnh đồng hồ điện',
                                      style: TextStyle(color: Colors.teal[700]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Nhấn vào đây để chọn ảnh',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Water section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop, color:  Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Chỉ số nước',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:  Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Current reading display
                      if (billLog.water != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Chỉ số hiện tại: ',
                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              ),
                              Text(
                                '${billLog.water} m³',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: 16),
                      
                      // New reading input for water with validation
                      TextField(
                        controller: waterController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Chỉ số mới',
                          hintText: 'Nhập chỉ số nước hiện tại',
                          prefixIcon: const Icon(Icons.numbers, color: Colors.teal),
                          suffixText: 'm³',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.teal),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Image selector
                      InkWell(
                        onTap: () => _showImagePickerForType(
                          context, 
                          'water',
                          (source) async {
                            await _getImage(source, false);
                            setState(() {});
                          }
                        ),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: waterImage != null 
                                  ? Colors.teal
                                  : Colors.grey[300]!,
                              width: waterImage != null ? 2 : 1,
                            ),
                          ),
                          child: waterImage != null
                              ? Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        waterImage!,
                                        width: double.infinity,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            waterImage = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap: () {
                                          _showImagePickerForType(
                                            context, 
                                            'water',
                                            (source) async {
                                              await _getImage(source, false);
                                              setState(() {});
                                            }
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(10),
                                              bottomLeft: Radius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Đổi ảnh',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt, color:  Colors.teal, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Chụp ảnh đồng hồ nước',
                                      style: TextStyle(color:  Colors.teal),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Nhấn vào đây để chọn ảnh',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSubmission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Gửi chỉ số',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePickerForType(BuildContext context, String type, Function(ImageSource) onSourceSelected) {
    final Color themeColor = type == 'electricity' ? Colors.teal :  Colors.teal;
    final String title = type == 'electricity' ? 'đồng hồ điện' : 'đồng hồ nước';
    final IconData typeIcon = type == 'electricity' ? Icons.electric_bolt : Icons.water_drop;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: themeColor),
                SizedBox(width: 12),
                Text(
                  'Chụp ảnh $title',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: themeColor),
              ),
              title: Text('Chụp ảnh mới'),
              subtitle: Text('Sử dụng camera để chụp ảnh'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                onSourceSelected(ImageSource.camera);
              },
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: themeColor),
              ),
              title: Text('Chọn từ thư viện'),
              subtitle: Text('Sử dụng ảnh có sẵn trong thư viện'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                onSourceSelected(ImageSource.gallery);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Handle payment logic
  void _handlePayment(BuildContext context, BillLog billLog) {
    // TODO: Implement payment flow
    // This could navigate to a payment screen or show a payment dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thanh toán hóa đơn'),
          content: Text(
            'Chức năng thanh toán hóa đơn đang được phát triển. '
            'Vui lòng thanh toán qua các kênh khác như QR code hoặc chuyển khoản trực tiếp.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Show QR code or other payment options
                // This could be implemented later
              },
              child: Text('Xem các cách thanh toán'),
            ),
          ],
        );
      },
    );
  }

  // Phục hồi _buildEmptyState()
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long, 
              color: Colors.blue, 
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa có hóa đơn',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sẽ hiển thị khi có cập nhật từ chủ trọ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: Colors.blue),
            onPressed: () {
              _loadActiveBillLog();
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }
} 