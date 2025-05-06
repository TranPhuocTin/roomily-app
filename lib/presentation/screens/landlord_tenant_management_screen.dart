import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/core/utils/rented_room_status.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_cubit.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_state.dart';
import 'package:roomily/data/models/rented_room.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/presentation/screens/rental_billing_screen.dart';
import 'package:roomily/data/blocs/auth/auth_cubit.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

class LandlordTenantManagementScreen extends StatefulWidget {
  const LandlordTenantManagementScreen({Key? key}) : super(key: key);

  @override
  State<LandlordTenantManagementScreen> createState() => _LandlordTenantManagementScreenState();
}

class _LandlordTenantManagementScreenState extends State<LandlordTenantManagementScreen> {
  late final RentedRoomCubit _rentedRoomCubit;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _rentedRoomCubit = RentedRoomCubit(
      rentedRoomRepository: RentedRoomRepositoryImpl(),
      roomRepository: RoomRepositoryImpl(),
    );
    _loadLandlordRentedRooms();
  }

  void _loadLandlordRentedRooms() async {
    try {
      // Thời gian chờ nhỏ để đảm bảo tất cả services đã được khởi tạo
      await Future.delayed(const Duration(milliseconds: 500));
      
      String? landlordId;
      
      // First try to get userId from AuthCubit
      try {
        landlordId = context.read<AuthCubit>().state.userId;
      } catch (e) {
        debugPrint('Không thể lấy ID từ AuthCubit: $e');
      }
      
      // If not available, try from secure storage
      if (landlordId == null || landlordId.isEmpty) {
        debugPrint('⚠️ Landlord ID not available from AuthCubit, trying SecureStorage');
        
        try {
          final secureStorage = GetIt.I<SecureStorageService>();
          landlordId = await secureStorage.getUserId();
        } catch (e) {
          debugPrint('Không thể lấy ID từ SecureStorage: $e');
        }
      }
      
      if (landlordId != null && landlordId.isNotEmpty) {
        debugPrint('🏠 Loading rented rooms for landlord ID: $landlordId');
        _rentedRoomCubit.getRentedRoomsByLandlordId(landlordId);
      } else {
        debugPrint('❌ Could not obtain landlord ID from any source');
        
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải danh sách người thuê. Vui lòng thử lại sau.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading landlord rented rooms: $e');
    }
  }

  @override
  void dispose() {
    _rentedRoomCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quản lý người thuê',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLandlordRentedRooms,
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _rentedRoomCubit,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildRentedRoomsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên phòng...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        style: const TextStyle(fontSize: 16),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.isNotEmpty ? value.toLowerCase() : null;
          });
        },
      ),
    );
  }

  Widget _buildRentedRoomsList() {
    return BlocBuilder<RentedRoomCubit, RentedRoomState>(
      builder: (context, state) {
        if (state is LandlordRentedRoomsLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Đang tải dữ liệu...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        } else if (state is LandlordRentedRoomsFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: ${state.error}',
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadLandlordRentedRooms,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state is LandlordRentedRoomsSuccess) {
          final rentedRooms = state.rentedRooms;
          
          if (rentedRooms.isEmpty) {
            return _buildEmptyState();
          }
          
          // Filter rooms based on search query only
          final filteredRooms = rentedRooms.where((room) {
            if (_searchQuery == null || _searchQuery!.isEmpty) {
              return true;
            }
            return room.roomId.toLowerCase().contains(_searchQuery!);
          }).toList();
          
          if (filteredRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy kết quả phù hợp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thử tìm kiếm với từ khóa khác',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              _loadLandlordRentedRooms();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final rentedRoom = filteredRooms[index];
                return _buildRentedRoomItem(rentedRoom);
              },
            ),
          );
        } else if (state is RentedRoomWithDetailsSuccess) {
          // Here we have both rented room and room details, which is better
          final rentedRooms = state.rentedRooms;
          final roomDetails = state.roomDetails;
          
          if (rentedRooms.isEmpty) {
            return _buildEmptyState();
          }
          
          // Filter rooms based on search query using room title if available
          final filteredRooms = rentedRooms.where((room) {
            if (_searchQuery == null || _searchQuery!.isEmpty) {
              return true;
            }
            
            final roomDetail = roomDetails[room.roomId];
            if (roomDetail != null) {
              return roomDetail.title.toLowerCase().contains(_searchQuery!);
            } else {
              return room.roomId.toLowerCase().contains(_searchQuery!);
            }
          }).toList();
          
          if (filteredRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy kết quả phù hợp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              _loadLandlordRentedRooms();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final rentedRoom = filteredRooms[index];
                final roomDetail = roomDetails[rentedRoom.roomId];
                
                return _buildRentedRoomItem(rentedRoom, roomDetail: roomDetail);
              },
            ),
          );
        }
        
        // Default empty state
        return Center(
          child: Text(
            'Đang tải dữ liệu...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Không có phòng đang cho thuê',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Chưa có người thuê nào đang thuê phòng của bạn',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadLandlordRentedRooms,
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentedRoomItem(RentedRoom rentedRoom, {Room? roomDetail}) {
    // Format date in dd/MM/yyyy format
    final startDate = _formatDate(rentedRoom.startDate);
    final endDate = _formatDate(rentedRoom.endDate);
    
    // Get colors and status text based on room status
    final (color, icon, statusText) = _getRentedRoomStatusInfo(rentedRoom.status);
    
    final title = roomDetail?.title ?? 'Phòng ${rentedRoom.roomId}';
    final price = roomDetail?.price ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to room details or management
          if (roomDetail != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RentalBillingScreen(room: roomDetail),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room placeholder with gradient background
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.withOpacity(0.7),
                          Colors.indigo.withOpacity(0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Từ $startDate đến $endDate',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                price > 0 ? currencyFormat.format(price) : 'Chưa có giá',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.indigo[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                   child: SizedBox(),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  if (roomDetail != null)
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RentalBillingScreen(room: roomDetail),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt, size: 16),
                        label: const Text(
                          'Quản lý hóa đơn',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Helper function to get status info
  (Color, IconData, String) _getRentedRoomStatusInfo(RentedRoomStatus status) {
    switch (status) {
      case RentedRoomStatus.IN_USE:
        return (Colors.green, Icons.check_circle, 'Đang thuê');
      case RentedRoomStatus.PENDING:
        return (Colors.orange, Icons.pending, 'Đang chờ');
      case RentedRoomStatus.DEPOSIT_NOT_PAID:
        return (Colors.red, Icons.money_off, 'Chưa đặt cọc');
      case RentedRoomStatus.BILL_MISSING:
        return (Colors.blue, Icons.receipt_long, 'Chưa có hóa đơn');
      case RentedRoomStatus.DEBT:
        return (Colors.deepOrange, Icons.warning, 'Đang nợ');
      case RentedRoomStatus.CANCELLED:
        return (Colors.grey, Icons.cancel, 'Đã hủy');
      default:
        return (Colors.grey, Icons.help_outline, 'Không xác định');
    }
  }
} 