import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/core/utils/room_status.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:roomily/core/services/notification_service.dart';
import 'package:roomily/presentation/screens/notification_screen.dart';
import 'package:roomily/presentation/screens/contract_management_screen.dart';
import 'package:roomily/data/models/bill_log.dart';
import 'package:roomily/core/utils/bill_status.dart';
import 'package:roomily/presentation/screens/rental_billing_screen.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/presentation/screens/contract_viewer_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomily/presentation/screens/add_room_screen_v2.dart';

import '../../data/blocs/auth/auth_cubit.dart';
import '../../data/blocs/home/room_image_cubit.dart';
import '../../data/blocs/home/room_image_state.dart';
import '../../data/blocs/landlord/landlord_rooms_cubit.dart';
import '../../data/blocs/landlord/landlord_rooms_state.dart';
import '../../data/blocs/rented_room/rented_room_cubit.dart';
import '../../data/blocs/rented_room/rented_room_state.dart';
import '../../data/blocs/notification/notification_cubit.dart';
import '../../data/blocs/notification/notification_state.dart';

class LandlordRoomManagementScreen extends StatefulWidget {
  const LandlordRoomManagementScreen({Key? key}) : super(key: key);

  @override
  State<LandlordRoomManagementScreen> createState() => _LandlordRoomManagementScreenState();
}

class _LandlordRoomManagementScreenState extends State<LandlordRoomManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFilterActive = false;
  String _selectedStatusFilter = 'Tất cả';
  bool _isGridView = true;
  
  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color backgroundColor = const Color(0xFFF8FAFF);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Get real landlord ID from auth
    _loadLandlordRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LandlordRoomsCubit, LandlordRoomsState>(
      listener: (context, state) {
        if (state is LandlordRoomsSuccess) {
          // Hiển thị Snackbar khi thành công
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is LandlordRoomsError) {
          // Hiển thị Snackbar khi có lỗi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is LandlordRoomsLoaded) {
          // When rooms are loaded, fetch all room images
          final rooms = state.rooms;
          final roomIds = rooms.map((room) => room.id!).toList();
          
          if (roomIds.isNotEmpty) {
            debugPrint('🖼️ Refreshing images for ${roomIds.length} rooms');
            context.read<RoomImageCubit>().fetchAllRoomImages(roomIds);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllRoomsTab(),
                  _buildAvailableRoomsTab(),
                  _buildRentedRoomsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddRoomScreenV2(),
              ),
            ).then((value) {
              if(value == true) {
                // Reload rooms list when returning from add room screen
                _loadLandlordRooms();
              }
            });
          },
          backgroundColor: primaryColor,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
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
      title: const Text(
        'Quản lý phòng trọ',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Nút thông báo
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            Builder(
              builder: (context) {
                try {
                  // Thử lấy NotificationService từ GetIt
                  final notificationService = GetIt.I<NotificationService>();
                  
                  return BlocProvider.value(
                    value: notificationService.notificationCubit,
                    child: BlocBuilder<NotificationCubit, NotificationState>(
                      builder: (context, state) {
                        if (state.unreadCount > 0) {
                          return Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  );
                } catch (e) {
                  // Fallback khi NotificationService chưa được đăng ký hoặc khởi tạo
                  debugPrint('Không thể lấy NotificationService: $e');
                  return const SizedBox.shrink();
                }
              },
            )
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _loadLandlordRooms();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đang tải lại dữ liệu...'))
            );
          },
          color: Colors.white,
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          color: Colors.white,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            setState(() {
              _isFilterActive = !_isFilterActive;
            });
          },
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm phòng trọ...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    if (!_isFilterActive) return const SizedBox.shrink();

    final List<String> statusOptions = ['Tất cả', 'Còn trống', 'Đã thuê'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statusOptions.length,
        itemBuilder: (context, index) {
          final status = statusOptions[index];
          final isSelected = status == _selectedStatusFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatusFilter = status;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: primaryColor.withOpacity(0.2),
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: primaryColor,
        tabs: const [
          Tab(text: 'Tất cả phòng'),
          Tab(text: 'Còn trống'),
          Tab(text: 'Đã thuê'),
        ],
      ),
    );
  }

  Widget _buildAllRoomsTab() {
    return BlocBuilder<LandlordRoomsCubit, LandlordRoomsState>(
      builder: (context, state) {
        if (state is LandlordRoomsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is LandlordRoomsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Đã xảy ra lỗi khi tải dữ liệu',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _loadLandlordRooms();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        } else if (state is LandlordRoomsLoaded) {
          final rooms = state.rooms;
          
          // Filter rooms based on search query and status filter
          final filteredRooms = rooms.where((room) {
            final matchesSearch = _searchQuery.isEmpty ||
                room.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                room.description.toLowerCase().contains(_searchQuery.toLowerCase());
            
            final matchesStatus = _selectedStatusFilter == 'Tất cả' || 
                               (_selectedStatusFilter == 'Còn trống' && room.status == RoomStatus.AVAILABLE) ||
                               (_selectedStatusFilter == 'Đã thuê' && room.status == RoomStatus.RENTED);
            
            return matchesSearch && matchesStatus;
          }).toList();

          if (filteredRooms.isEmpty) {
            return _buildEmptyState();
          }

          return _isGridView ? _buildGridView(filteredRooms) : _buildListView(filteredRooms);
        } else {
          return const Center(child: Text('Không có dữ liệu'));
        }
      }
    );
  }

  Widget _buildAvailableRoomsTab() {
    return BlocBuilder<LandlordRoomsCubit, LandlordRoomsState>(
      builder: (context, state) {
        if (state is LandlordRoomsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is LandlordRoomsError) {
          return Center(child: Text('Lỗi: ${state.message}'));
        } else if (state is LandlordRoomsLoaded) {
          final availableRooms = state.rooms.where((room) => room.status == RoomStatus.AVAILABLE).toList();
          
          if (availableRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có phòng còn trống',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to add room page
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm phòng trọ mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return _isGridView ? _buildGridView(availableRooms) : _buildListView(availableRooms);
        } else {
          return const Center(child: Text('Không có dữ liệu'));
        }
      }
    );
  }

  Widget _buildRentedRoomsTab() {
    return BlocBuilder<LandlordRoomsCubit, LandlordRoomsState>(
      builder: (context, state) {
        if (state is LandlordRoomsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is LandlordRoomsError) {
          return Center(child: Text('Lỗi: ${state.message}'));
        } else if (state is LandlordRoomsLoaded) {
          final rentedRooms = state.rooms.where((room) => room.status == RoomStatus.RENTED).toList();
          
          if (rentedRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có phòng đã cho thuê',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }
          
          return _isGridView ? _buildGridView(rentedRooms) : _buildListView(rentedRooms);
        } else {
          return const Center(child: Text('Không có dữ liệu'));
        }
      }
    );
  }

  Widget _buildGridView(List<Room> rooms) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildRoomGridCard(room);
        },
        // Add physics and caching for better scroll performance
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 500, // Cache more items ahead to prepare for loading
      ),
    );
  }

  Widget _buildListView(List<Room> rooms) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _buildRoomListCard(room);
      },
      // Add physics and caching for better scroll performance
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 500, // Cache more items ahead to prepare for loading
    );
  }

  Widget _buildRoomGridCard(Room room) {
    final bool isRented = room.status == RoomStatus.RENTED;
    final bool isDeleted = room.status == RoomStatus.DELETED;
    final String statusText = _getStatusText(room.status!);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Container(
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _buildRoomImage(room.id!),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildStatusBadge(statusText),
                  ),
                  if (isRented && !isDeleted)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: _buildBillLogBadge(room.id!),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      room.address ?? 'Địa chỉ không có sẵn',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${room.price.toStringAsFixed(0)} đ/Tháng',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0075FF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isDeleted)
                      Row(
                        children: [
                          Icon(Icons.do_not_disturb, size: 12, color: Colors.red[400]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              'Đã xóa',
                              style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else if (isRented)
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.blue[400]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              'Xem hợp đồng',
                              style: TextStyle(
                                color: Colors.blue[400],
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.person_off, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              'Chưa thuê',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    
                    Spacer(),
                    Container(
                      height: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: !isDeleted ? [
                          if (!isRented) ...[
                            _buildSmallActionButton(
                              icon: Icons.edit,
                              iconColor: const Color(0xFF5C6BC0),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddRoomScreenV2(room: room),
                                  ),
                                ).then((_) {
                                  _loadLandlordRooms();
                                });
                              },
                            ),
                            _buildSmallActionButton(
                              icon: Icons.description,
                              iconColor: const Color(0xFF26A69A),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContractManagementScreen(room: room),
                                  ),
                                );
                              },
                            ),
                            _buildSmallActionButton(
                              icon: Icons.delete,
                              iconColor: const Color(0xFFE57373),
                              onTap: () {
                                _showDeleteConfirmationDialog(room);
                              },
                            ),
                          ] else ...[
                            _buildSmallActionButton(
                              icon: Icons.people,
                              iconColor: Colors.blue,
                              onTap: () {
                                // Navigate to tenant management
                                if (room.id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ContractViewerScreen(roomId: room.id!),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Không thể xem hợp đồng, ID phòng không hợp lệ')),
                                  );
                                }
                              },
                            ),
                            _buildSmallActionButton(
                              icon: Icons.receipt_long,
                              iconColor: Colors.orange,
                              onTap: () {
                                _navigateToRentalBilling(room);
                              },
                            ),
                            _buildSmallActionButton(
                              icon: Icons.notifications,
                              iconColor: Colors.purple,
                              onTap: () {
                                // Send notification to tenant
                              },
                            ),
                          ]
                        ] : [
                          Text(
                            'Không có thao tác',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomListCard(Room room) {
    final bool isRented = room.status == RoomStatus.RENTED;
    final bool isDeleted = room.status == RoomStatus.DELETED;
    final String statusText = _getStatusText(room.status!);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to room detail screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.home, color: primaryColor),
              ),
              title: Text(
                room.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                room.address ?? 'Địa chỉ không có sẵn',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              trailing: _buildStatusBadge(statusText),
            ),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    _buildRoomImage(room.id!),
                    if (isRented && !isDeleted)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: _buildBillLogBadge(room.id!),
                      ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${room.price.toStringAsFixed(0)} đ/Tháng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isDeleted)
                          Row(
                            children: [
                              Icon(Icons.do_not_disturb, size: 16, color: Colors.red[400]),
                              const SizedBox(width: 4),
                              Text(
                                'Đã xóa',
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        else if (isRented)
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.blue[400]),
                              const SizedBox(width: 4),
                              Text(
                                'Xem hợp đồng thuê',
                                style: TextStyle(
                                  color: Colors.blue[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(Icons.person_off, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                'Chưa có người thuê',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (!isDeleted)
                    Row(
                      children: [
                        if (!isRented) ...[
                          _buildIconButton(
                            icon: Icons.edit,
                            iconColor: const Color(0xFF5C6BC0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddRoomScreenV2(room: room),
                                ),
                              ).then((_) {
                                _loadLandlordRooms();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            icon: Icons.description,
                            iconColor: const Color(0xFF26A69A),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContractManagementScreen(room: room),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            icon: Icons.delete,
                            iconColor: const Color(0xFFE57373),
                            onTap: () {
                              _showDeleteConfirmationDialog(room);
                            },
                          ),
                        ] else ...[
                          _buildIconButton(
                            icon: Icons.people,
                            iconColor: Colors.blue,
                            onTap: () {
                              // Navigate to tenant management
                              if (room.id != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContractViewerScreen(roomId: room.id!),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Không thể xem hợp đồng, ID phòng không hợp lệ')),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            icon: Icons.receipt_long,
                            iconColor: Colors.orange,
                            onTap: () {
                              _navigateToRentalBilling(room);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildIconButton(
                          icon: Icons.more_vert,
                          onTap: () {
                            _showRoomOptionsBottomSheet(room);
                          },
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

  Widget _buildStatusBadge(String status) {
    late Color color;
    
    switch (status) {
      case 'Còn trống':
        color = Colors.green;
        break;
      case 'Đã thuê':
        color = Colors.blue;
        break;
      case 'Đang sửa chữa':
        color = Colors.orange;
        break;
      case 'Chờ duyệt':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? Colors.grey[700]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy phòng trọ nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm phòng trọ mới hoặc thay đổi bộ lọc',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add room page
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm phòng trọ mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa phòng ${room.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              // Đóng dialog xác nhận
              Navigator.pop(context);
              
              // Sử dụng BlocListener thay vì trực tiếp hiển thị loading dialog
              _deleteRoom(room);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  // Tách hàm xóa phòng riêng để dễ quản lý
  Future<void> _deleteRoom(Room room) async {
    // Sử dụng Overlay để hiển thị loading indicator
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
    
    // Hiển thị loading indicator
    overlay.insert(overlayEntry);
    
    try {
      // Lấy landlordId từ Auth hoặc Storage
      String? landlordId;
      final authCubit = context.read<AuthCubit>();
      landlordId = authCubit.state.userId;
      
      if (landlordId == null || landlordId.isEmpty) {
        final secureStorage = GetIt.I<SecureStorageService>();
        landlordId = await secureStorage.getUserId();
      }
      
      if (landlordId != null && landlordId.isNotEmpty) {
        // Gọi cubit để xóa phòng
        await context.read<LandlordRoomsCubit>().deleteRoom(room.id!, landlordId);
        
        // Xóa loading indicator khi xong
        overlayEntry.remove();
      } else {
        // Xóa loading indicator khi xong
        overlayEntry.remove();
        
        // Hiển thị lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xác định ID chủ nhà. Vui lòng đăng nhập lại.'))
        );
      }
    } catch (e) {
      // Xóa loading indicator khi xong
      overlayEntry.remove();
      
      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa phòng: ${e.toString()}'))
      );
    }
  }

  void _showRoomOptionsBottomSheet(Room room) {
    final bool isRented = room.status == RoomStatus.RENTED;
    final bool isDeleted = room.status == RoomStatus.DELETED;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Xem chi tiết'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to room detail
                  },
                ),
                if (!isDeleted) ...[
                  if (!isRented)
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Chỉnh sửa phòng'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddRoomScreenV2(room: room),
                          ),
                        ).then((_) {
                          _loadLandlordRooms();
                        });
                      },
                    ),
                  if (isRented)
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Xem hợp đồng thuê'),
                      onTap: () {
                        Navigator.pop(context);
                        if (room.id != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContractViewerScreen(roomId: room.id!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Không thể xem hợp đồng, ID phòng không hợp lệ')),
                          );
                        }
                      },
                    ),
                  if (isRented)
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Quản lý thanh toán'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToRentalBilling(room);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Hóa đơn & thanh toán'),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to billing management
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: Text(
                      room.status == RoomStatus.AVAILABLE
                          ? 'Đánh dấu đã cho thuê'
                          : 'Đánh dấu còn trống',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Change room status
                    },
                  ),
                  if (!isRented)
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text(
                        'Xóa phòng',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteConfirmationDialog(room);
                      },
                    ),
                ] else
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.grey),
                    title: const Text(
                      'Không có thao tác khả dụng cho phòng đã xóa',
                      style: TextStyle(color: Colors.grey),
                    ),
                    enabled: false,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.AVAILABLE:
        return 'Còn trống';
      case RoomStatus.RENTED:
        return 'Đã thuê';
      case RoomStatus.DELETED:
        return 'Đã xóa';
      case RoomStatus.BANNED:
        return 'Bị khóa';
      default:
        return 'Không xác định';
    }
  }

  Widget _buildRoomImage(String roomId) {
    return BlocBuilder<RoomImageCubit, RoomImageState>(
      builder: (context, state) {
        if (state is AllRoomImagesState) {
          // Check if we have images for this room
          if (state.roomImagesMap.containsKey(roomId) && 
              state.roomImagesMap[roomId]!.isNotEmpty) {
            // Use the first image
            final imageUrl = state.roomImagesMap[roomId]![0].url;
            return _buildCachedImage(imageUrl);
          }
          
          // Room exists in map but has no images (empty list)
          if (state.roomImagesMap.containsKey(roomId) && 
              state.roomImagesMap[roomId]!.isEmpty) {
            return Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey[200],
              child: Center(
                child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
              ),
            );
          }
        }
        
        // Room is not in the map yet or state is not AllRoomImagesState
        return Container(
          height: 120,
          width: double.infinity,
          color: Colors.grey[200],
          child: Center(
            child: const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0075FF)),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method for cached images with loading indicators
  Widget _buildCachedImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[200],
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
      ),
    );
  }

  Future<void> _loadLandlordRooms() async {
    try {
      // Get current user ID from Auth state
      final authCubit = context.read<AuthCubit>();
      final userId = authCubit.state.userId;
      
      if (userId != null && userId.isNotEmpty) {
        debugPrint('🏠 Loading rooms for landlord ID: $userId');
        final landlordRoomsCubit = context.read<LandlordRoomsCubit>();
        await landlordRoomsCubit.getLandlordRooms(userId);
        
        // After rooms are loaded, fetch all room images at once
        if (landlordRoomsCubit.state is LandlordRoomsLoaded) {
          final rooms = (landlordRoomsCubit.state as LandlordRoomsLoaded).rooms;
          final roomIds = rooms.map((room) => room.id!).toList();
          
          // Load all room images in bulk
          if (roomIds.isNotEmpty) {
            debugPrint('🖼️ Loading images for ${roomIds.length} rooms');
            context.read<RoomImageCubit>().fetchAllRoomImages(roomIds);
          }
        }
      } else {
        // Fallback to secure storage if AuthCubit doesn't have the userId
        final secureStorage = GetIt.I<SecureStorageService>();
        final storageUserId = await secureStorage.getUserId();
        
        if (storageUserId != null && storageUserId.isNotEmpty) {
          debugPrint('🏠 Loading rooms for landlord ID from storage: $storageUserId');
          final landlordRoomsCubit = context.read<LandlordRoomsCubit>();
          await landlordRoomsCubit.getLandlordRooms(storageUserId);
          
          // After rooms are loaded, fetch all room images at once
          if (landlordRoomsCubit.state is LandlordRoomsLoaded) {
            final rooms = (landlordRoomsCubit.state as LandlordRoomsLoaded).rooms;
            final roomIds = rooms.map((room) => room.id!).toList();
            
            // Load all room images in bulk
            if (roomIds.isNotEmpty) {
              debugPrint('🖼️ Loading images for ${roomIds.length} rooms');
              context.read<RoomImageCubit>().fetchAllRoomImages(roomIds);
            }
          }
        } else {
          debugPrint('❌ Unable to get landlord ID, cannot load rooms');
          // Show error message or use a default ID for testing
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể lấy ID chủ nhà. Vui lòng đăng nhập lại.'))
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading landlord rooms: $e');
    }
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? primaryColor,
        ),
      ),
    );
  }

  Widget _buildBillLogBadge(String roomId) {
    return BlocProvider(
      create: (context) => RentedRoomCubit(
        rentedRoomRepository: RentedRoomRepositoryImpl(),
      )..getActiveBillLogByRoomId(roomId),
      child: BlocBuilder<RentedRoomCubit, RentedRoomState>(
        builder: (context, state) {
          if (state is BillLogSuccess) {
            // Debug logging
            debugPrint('💰 BillLog status: ${state.billLog.billStatus}');
            debugPrint('💰 BillLog roomId: ${state.billLog.roomId}');
            debugPrint('💰 BillLog id: ${state.billLog.id}');
            
            // Check for empty bill log
            if (state.billLog.id.startsWith('empty-') || 
                state.billLog.roomId == 'empty') {
              debugPrint('❌ Empty bill log detected');
              return const SizedBox.shrink();
            }
            
            return _buildBillBadge(state.billLog);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBillBadge(BillLog billLog) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;
    
    switch (billLog.billStatus) {
      case BillStatus.PENDING:
        badgeColor = const Color(0xFFFF9800); // Màu cam ấm áp
        statusText = 'Chờ thanh toán';
        statusIcon = Icons.pending_actions;
        break;
        
      case BillStatus.PAID:
        badgeColor = const Color(0xFF4CAF50); // Màu xanh lá
        statusText = 'Đã thanh toán';
        statusIcon = Icons.check_circle;
        break;
        
      case BillStatus.MISSING:
        badgeColor = const Color(0xFF42A5F5); // Màu xanh dương
        statusText = 'Chưa có chỉ số';
        statusIcon = Icons.info_outline;
        break;
        
      case BillStatus.CHECKING:
        badgeColor = const Color(0xFF7E57C2); // Màu tím nhẹ
        statusText = 'Cần xác nhận';
        statusIcon = Icons.fact_check;
        break;
        
      case BillStatus.WATER_RE_ENTER:
        badgeColor = const Color(0xFF26C6DA); // Màu xanh nước biển
        statusText = 'Nhập lại nước';
        statusIcon = Icons.water_drop;
        break;
        
      case BillStatus.ELECTRICITY_RE_ENTER:
        badgeColor = const Color(0xFFFFB300); // Màu vàng đậm
        statusText = 'Nhập lại điện';
        statusIcon = Icons.electric_bolt;
        break;
        
      case BillStatus.RE_ENTER:
        badgeColor = const Color(0xFFFF7043); // Màu cam đỏ
        statusText = 'Yêu cầu nhập lại';
        statusIcon = Icons.refresh;
        break;
        
      case BillStatus.CANCELLED:
        badgeColor = const Color(0xFFEF5350); // Màu đỏ nhạt
        statusText = 'Đã hủy';
        statusIcon = Icons.cancel;
        break;
        
      case BillStatus.LATE:
        badgeColor = const Color(0xFFE53935); // Màu đỏ đậm
        statusText = 'Trễ hạn';
        statusIcon = Icons.warning;
        break;
        
      case BillStatus.LATE_PAID:
        badgeColor = const Color(0xFFFF5252); // Màu đỏ tươi
        statusText = 'Trễ hạn thanh toán';
        statusIcon = Icons.warning;
        break;
        
      case BillStatus.UNPAID:
        badgeColor = const Color(0xFFD32F2F); // Màu đỏ sẫm
        statusText = 'Chưa thanh toán';
        statusIcon = Icons.error;
        break;
        
      default:
        badgeColor = const Color(0xFF9E9E9E); // Màu xám
        statusText = 'Không xác định';
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: badgeColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRentalBilling(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalBillingScreen(room: room),
      ),
    );
  }
} 