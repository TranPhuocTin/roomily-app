import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_cubit.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_state.dart';
import 'package:roomily/data/models/bill_log.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/core/utils/bill_status.dart';
import 'package:roomily/presentation/screens/rental_billing_screen.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

class UpcomingPaymentsWidget extends StatefulWidget {
  final String? userId;
  final int maxPayments;
  final bool showViewAll;
  
  const UpcomingPaymentsWidget({
    Key? key,
    this.userId,
    this.maxPayments = 3,
    this.showViewAll = false,
  }) : super(key: key);

  @override
  State<UpcomingPaymentsWidget> createState() => _UpcomingPaymentsWidgetState();
}

class _UpcomingPaymentsWidgetState extends State<UpcomingPaymentsWidget> with SingleTickerProviderStateMixin {
  late final RentedRoomCubit _rentedRoomCubit;
  final _currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _hasAttemptedLoad = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);
  final Color accentGreen = const Color(0xFF00C897);
  final Color accentOrange = const Color(0xFFFF9500);
  final Color accentRed = const Color(0xFFFF456C);
  final Color accentPurple = const Color(0xFF7F5BFF);

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Tạo một cubit mới
    _rentedRoomCubit = RentedRoomCubit(
      rentedRoomRepository: RentedRoomRepositoryImpl(),
      roomRepository: RoomRepositoryImpl(),
    );
    
    // Load payments after a short delay
    Future.delayed(Duration(milliseconds: 500), _loadUpcomingPayments);
  }

  @override
  void dispose() {
    _rentedRoomCubit.close();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUpcomingPayments() async {
    // Reset animation
    _animationController.reset();
    
    // Set flag to indicate we've attempted to load
    _hasAttemptedLoad = true;
    
    try {
      // Lấy userId ưu tiên từ widget props
      String? landlordId = widget.userId;
      
      // Nếu không có userId, thử lấy từ SecureStorage
      if (landlordId == null || landlordId.isEmpty) {
        try {
          final secureStorage = GetIt.I<SecureStorageService>();
          landlordId = await secureStorage.getUserId();
        } catch (e) {
          debugPrint('❌ Không thể lấy ID từ SecureStorage: $e');
        }
      }

      // Nếu có userId hợp lệ, gọi phương thức mới để lấy dữ liệu
      if (landlordId != null && landlordId.isNotEmpty) {
        debugPrint('🔄 Loading upcoming payments for landlord: $landlordId');
        await _rentedRoomCubit.getLandlordUpcomingPayments(landlordId);
        // Start animation after data is loaded
        _animationController.forward();
      } else {
        // Nếu không có userId, hiển thị lỗi
        debugPrint('❌ Không thể xác định ID người dùng');
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi tải dữ liệu thanh toán: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rentedRoomCubit,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionHeader(
              title: 'Thanh toán sắp tới',
              actionText: widget.showViewAll ? 'Xem tất cả' : 'Làm mới',
              onAction: () {
                // Nếu là nút "Xem tất cả", có thể điều hướng đến màn hình tất cả thanh toán
                // Nếu không thì làm mới dữ liệu
                _loadUpcomingPayments();
              },
              showAction: true,
            ),
            SizedBox(height: 16),
            BlocBuilder<RentedRoomCubit, RentedRoomState>(
              builder: (context, state) {
                // Handle case where we haven't tried to load yet
                if (!_hasAttemptedLoad) {
                  return _buildLoadingState();
                }
                
                // Handle loading state
                if (state is UpcomingPaymentsLoading) {
                  return _buildLoadingState();
                } 
                
                // Handle loaded state with data
                else if (state is UpcomingPaymentsSuccess) {
                  final upcomingBills = state.upcomingBills;
                  final roomDetails = state.roomDetails;
                  
                  if (upcomingBills.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  // Sort bills by due date
                  final sortedBills = List<BillLog>.from(upcomingBills)
                    ..sort((a, b) {
                      try {
                        final dateA = DateTime.parse(a.toDate);
                        final dateB = DateTime.parse(b.toDate);
                        return dateA.compareTo(dateB);
                      } catch (_) {
                        return 0;
                      }
                    });
                  
                  // Limit the number of bills to display
                  final billsToShow = sortedBills.take(widget.maxPayments).toList();
                  
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: billsToShow
                        .map((bill) => _buildPaymentItem(bill, roomDetails))
                        .toList(),
                    ),
                  );
                } 
                
                // Handle error state
                else if (state is UpcomingPaymentsFailure) {
                  return _buildErrorState(state.error);
                }
                
                // Initial state or unknown state
                return _buildLoadingState();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          _buildPaymentShimmer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payment_outlined,
                  color: primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không có thanh toán sắp tới',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Các khoản thanh toán sắp tới sẽ hiển thị ở đây',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: accentRed, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Không thể tải thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUpcomingPayments,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 110,
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room title
                        Container(
                          height: 16,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        SizedBox(height: 8),
                        // Room ID
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price
                  Container(
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Date and status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  // Status
                  Container(
                    height: 24,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentItem(BillLog billLog, Map<String, Room> roomDetails) {
    final roomId = billLog.roomId;
    final roomName = roomDetails.containsKey(roomId) 
        ? roomDetails[roomId]!.title 
        : 'Phòng $roomId';
    
    // Tính tổng số tiền
    final totalAmount = billLog.rentalCost +
        (billLog.electricityBill ?? 0) +
        (billLog.waterBill ?? 0);
    
    // Format ngày hết hạn
    String dueDate = 'Chưa rõ';
    Color statusColor;
    IconData statusIcon;
    String statusText;
    Color iconBgColor;
    
    try {
      final dueDateObj = DateTime.parse(billLog.toDate);
      dueDate = '${dueDateObj.day}/${dueDateObj.month}/${dueDateObj.year}';
      
      // Vẫn tính daysLeft để hỗ trợ hiển thị trạng thái PENDING chi tiết hơn
      final now = DateTime.now();
      final daysLeft = dueDateObj.difference(now).inDays;
      
      // Xử lý theo BillStatus để hiển thị trạng thái chính xác
      switch (billLog.billStatus) {
        case BillStatus.PAID:
          statusColor = accentGreen;
          statusIcon = Icons.check_circle_outline;
          statusText = 'Đã thanh toán';
          iconBgColor = accentGreen;
          break;
          
        case BillStatus.LATE:
          statusColor = accentRed;
          statusIcon = Icons.warning_amber_outlined;
          statusText = 'Quá hạn';
          iconBgColor = accentRed;
          break;
          
        case BillStatus.UNPAID:
          statusColor = accentRed;
          statusIcon = Icons.money_off_outlined;
          statusText = 'Chưa thanh toán';
          iconBgColor = accentRed;
          break;
          
        case BillStatus.LATE_PAID:
          statusColor = accentPurple;
          statusIcon = Icons.history;
          statusText = 'Trễ hạn đã thanh toán';
          iconBgColor = accentPurple;
          break;
          
        case BillStatus.CANCELLED:
          statusColor = textSecondaryColor;
          statusIcon = Icons.cancel_outlined;
          statusText = 'Đã hủy';
          iconBgColor = textSecondaryColor;
          break;
          
        case BillStatus.PENDING:
          // Đối với PENDING, xét thêm daysLeft để hiển thị chi tiết hơn
          if (daysLeft < 0) {
            statusColor = accentRed;
            statusIcon = Icons.warning_amber_outlined;
            statusText = 'Quá hạn';
            iconBgColor = accentRed;
          } else if (daysLeft <= 3) {
            statusColor = accentOrange;
            statusIcon = Icons.schedule;
            statusText = 'Sắp đến hạn';
            iconBgColor = accentOrange;
          } else {
            statusColor = primaryColor;
            statusIcon = Icons.event_available_outlined;
            statusText = 'Chờ thanh toán';
            iconBgColor = primaryColor;
          }
          break;
          
        case BillStatus.CHECKING:
        case BillStatus.WATER_RE_ENTER:
        case BillStatus.ELECTRICITY_RE_ENTER:
        case BillStatus.RE_ENTER:
          statusColor = accentOrange;
          statusIcon = Icons.fact_check_outlined;
          statusText = 'Đang xác nhận';
          iconBgColor = accentOrange;
          break;
          
        case BillStatus.MISSING:
        default:
          statusColor = textSecondaryColor;
          statusIcon = Icons.help_outline;
          statusText = 'Chưa có chỉ số';
          iconBgColor = textSecondaryColor;
          break;
      }
    } catch (e) {
      // Xử lý ngoại lệ khi không parse được ngày tháng
      debugPrint('❌ Lỗi parse ngày tháng: $e');
      
      // Ngay cả khi không parse được ngày, vẫn xử lý theo BillStatus
      if (billLog.billStatus == BillStatus.PAID) {
        statusColor = accentGreen;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Đã thanh toán';
        iconBgColor = accentGreen;
      } else if (billLog.billStatus == BillStatus.LATE || 
                billLog.billStatus == BillStatus.UNPAID) {
        statusColor = accentRed;
        statusIcon = Icons.warning_amber_outlined;
        statusText = 'Chưa thanh toán';
        iconBgColor = accentRed;
      } else {
        statusColor = accentOrange;
        statusIcon = Icons.schedule;
        statusText = 'Chờ xác nhận';
        iconBgColor = accentOrange;
      }
    }
    
    return GestureDetector(
      onTap: () {
        // Navigate to bill details if room details are available
        if (roomDetails.containsKey(roomId)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RentalBillingScreen(room: roomDetails[roomId]!),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon with colored background
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [iconBgColor, iconBgColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tiền thuê: ${_currencyFormatter.format(billLog.rentalCost)}',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormatter.format(totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Due date with icon
                  Row(
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 14,
                        color: textSecondaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Hạn: $dueDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 12,
                          color: statusColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
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
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onAction,
    required bool showAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        if (showAction)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.showViewAll 
                        ? Icons.visibility_outlined 
                        : Icons.refresh_outlined,
                    size: 14,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    actionText,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 