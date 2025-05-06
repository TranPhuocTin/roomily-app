import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/models/find_partner_post.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/find_partner_repository_impl.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:roomily/presentation/screens/find_partner_detail_screen.dart';
import 'package:roomily/presentation/screens/qr_scanner_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:roomily/presentation/screens/qr_image_scanner_screen.dart';

import '../../data/blocs/find_partner/find_partner_cubit.dart';
import '../../data/blocs/find_partner/find_partner_state.dart';

class FindPartnerManagementScreen extends StatefulWidget {
  const FindPartnerManagementScreen({Key? key}) : super(key: key);

  @override
  State<FindPartnerManagementScreen> createState() => _FindPartnerManagementScreenState();
}

class _FindPartnerManagementScreenState extends State<FindPartnerManagementScreen> {
  late FindPartnerCubit _findPartnerCubit;
  late RoomRepository _roomRepository;
  String? _currentUserId;
  
  // Lưu trữ thông tin phòng đã fetch được
  final Map<String, Room> _roomCache = {};
  
  @override
  void initState() {
    super.initState();
    _findPartnerCubit = FindPartnerCubit(
      FindPartnerRepositoryImpl(dio: DioConfig.createDio()),
    );
    
    _roomRepository = RoomRepositoryImpl(dio: DioConfig.createDio());
    
    // Lấy userId hiện tại
    _getCurrentUserId();
    
    // Load active find partner posts
    _findPartnerCubit.getActiveFindPartnerPosts();
  }
  
  // Lấy thông tin userId hiện tại từ AuthService
  void _getCurrentUserId() {
    try {
      final authService = GetIt.I<AuthService>();
      _currentUserId = authService.userId;
      print('Current user ID: $_currentUserId');
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }
  
  // Hàm để lấy thông tin chi tiết của phòng
  Future<Room?> _getRoomInfo(String roomId) async {
    // Kiểm tra cache trước
    if (_roomCache.containsKey(roomId)) {
      return _roomCache[roomId];
    }
    
    // Nếu chưa có trong cache, gọi API
    final result = await _roomRepository.getRoom(roomId);
    
    return result.when(
      success: (room) {
        // Lưu vào cache
        _roomCache[roomId] = room;
        return room;
      },
      failure: (message) {
        print('Error fetching room details: $message');
        return null;
      },
    );
  }
  
  @override
  void dispose() {
    _findPartnerCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _findPartnerCubit,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Tìm bạn ở ghép'),
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<FindPartnerCubit, FindPartnerState>(
              listener: (context, state) {
                if (state is FindPartnerDeleting) {
                  // Hiển thị loading khi đang xóa bài đăng
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang xóa bài đăng...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else if (state is FindPartnerDeleted) {
                  // Hiển thị thông báo khi xóa thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa bài đăng thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Tải lại danh sách bài đăng
                  _findPartnerCubit.getActiveFindPartnerPosts();
                } else if (state is FindPartnerError) {
                  // Hiển thị thông báo lỗi
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<FindPartnerCubit, FindPartnerState>(
            builder: (context, state) {
              if (state is FindPartnerLoading) {
                return _buildLoadingShimmer();
              }
              
              if (state is FindPartnerError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: ${state.message}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _findPartnerCubit.getActiveFindPartnerPosts();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              
              if (state is FindPartnerActivePosts || state is FindPartnerUpdated) {
                final posts = state is FindPartnerActivePosts 
                    ? (state as FindPartnerActivePosts).posts 
                    : [];
                
                if (posts.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildFindPartnerCard(post);
                  },
                );
              }
              
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
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
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa có bài đăng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiện tại bạn chưa tham gia nhóm tìm bạn ở ghép nào',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFindPartnerCard(FindPartnerPost post) {
    final bool isActive = post.status == 'ACTIVE';
    final bool isFull = post.currentPeople >= post.maxPeople;
    final bool isPostOwner = _currentUserId != null && _currentUserId == post.posterId;
    
    // Date formatter
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String createdDate = post.createdAt != null
        ? formatter.format(DateTime.parse(post.createdAt!))
        : 'N/A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to find partner post detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FindPartnerDetailScreen(
                  postId: post.findPartnerPostId,
                  findPartnerCubit: _findPartnerCubit,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? isFull
                                ? Colors.orange.withOpacity(0.9)
                                : Colors.green.withOpacity(0.9)
                            : Colors.grey.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive
                            ? isFull
                                ? 'Đủ thành viên'
                                : 'Đang hoạt động'
                            : 'Đã đóng',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Menu thao tác cho chủ bài đăng
                    if (isPostOwner)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditDialog(post);
                              break;
                            case 'delete':
                              _showDeleteConfirmationDialog(post.findPartnerPostId);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Chỉnh sửa'),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Xóa bài đăng', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phòng',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<Room?>(
                            future: _getRoomInfo(post.roomId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Row(
                                  children: [
                                    // Hiển thị shimmer loading khi đang fetch
                                    Expanded(
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          height: 16,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              
                              // Nếu có thông tin phòng, hiển thị tên phòng
                              if (snapshot.hasData && snapshot.data != null) {
                                final room = snapshot.data!;
                                return Text(
                                  room.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              } 
                              
                              // Nếu không có thông tin, hiển thị roomId
                              return Text(
                                'Phòng ${post.roomId.substring(0, 8)}...',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.people,
                      Colors.blue,
                      'Thành viên',
                      '${post.currentPeople}/${post.maxPeople}',
                    ),
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      Icons.calendar_today,
                      Colors.purple,
                      'Ngày tạo',
                      createdDate,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (post.description != null && post.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mô tả:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.description!,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút thêm thành viên - chỉ hiển thị cho chủ bài đăng
                    if (isPostOwner && isActive && !isFull)
                      TextButton.icon(
                        onPressed: () => _showAddParticipantOptions(context, post.findPartnerPostId),
                        icon: const Icon(Icons.person_add, size: 16, color: Colors.green),
                        label: const Text('Thêm người'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    
                    // Nút xem chi tiết luôn hiển thị
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FindPartnerDetailScreen(
                                postId: post.findPartnerPostId,
                                findPartnerCubit: _findPartnerCubit,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Chi tiết'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showEditDialog(FindPartnerPost post) {
    final TextEditingController descriptionController = TextEditingController(text: post.description ?? '');
    final TextEditingController maxPeopleController = TextEditingController(text: post.maxPeople.toString());
    final _formKey = GlobalKey<FormState>();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chỉnh sửa bài đăng'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trạng thái và thông tin hiện tại
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Thông tin hiện tại',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Số người hiện tại: ${post.currentPeople}'),
                            Text('Trạng thái: ${post.status}'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Trường mô tả
                      Text(
                        'Mô tả',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Mô tả về bài đăng tìm bạn ở ghép của bạn',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả cho bài đăng';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Trường số người tối đa
                      Text(
                        'Số người tối đa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: maxPeopleController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Nhập số người tối đa',
                          prefixIcon: const Icon(Icons.people),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số người tối đa';
                          }
                          
                          final maxPeople = int.tryParse(value);
                          if (maxPeople == null) {
                            return 'Vui lòng nhập một số hợp lệ';
                          }
                          
                          if (maxPeople <= 0) {
                            return 'Số người tối đa phải lớn hơn 0';
                          }
                          
                          if (maxPeople < post.currentPeople) {
                            return 'Số người tối đa phải ≥ số người hiện tại (${post.currentPeople})';
                          }
                          
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                            });

                            final description = descriptionController.text.trim();
                            final maxPeople = int.parse(maxPeopleController.text.trim());

                            Navigator.pop(context);
                            
                            // Gọi API cập nhật
                            await _findPartnerCubit.updateFindPartnerPost(
                              findPartnerPostId: post.findPartnerPostId,
                              description: description,
                              maxPeople: maxPeople,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Lưu thay đổi'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  Widget _buildInfoItem(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Hiển thị bottom sheet với các tùy chọn thêm thành viên
  void _showAddParticipantOptions(BuildContext context, String findPartnerPostId) {
    // Hiển thị bottom sheet với các tùy chọn
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thêm thành viên',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                ),
                title: const Text('Quét mã QR'),
                subtitle: const Text('Quét QR code trực tiếp từ camera'),
                onTap: () {
                  Navigator.pop(context);
                  _scanQRCode(context, findPartnerPostId);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image, color: Colors.green),
                ),
                title: const Text('Tải ảnh QR'),
                subtitle: const Text('Chọn ảnh QR code từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickQRImage(context, findPartnerPostId);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.text_fields, color: Colors.purple),
                ),
                title: const Text('Nhập mã thủ công'),
                subtitle: const Text('Nhập Private ID của thành viên'),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivateIdDialog(context, findPartnerPostId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Phương thức này sẽ triển khai quét QR code
  void _scanQRCode(BuildContext context, String findPartnerPostId) async {
    try {
      // Mở màn hình quét QR
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );
      
      // Nếu có kết quả trả về (privateId)
      if (result != null && result is String && result.isNotEmpty) {
        // Gọi cubit để thêm thành viên
        _findPartnerCubit.addParticipant(
          findPartnerPostId: findPartnerPostId,
          privateId: result,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi quét mã QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Phương thức này sẽ triển khai chọn ảnh QR
  void _pickQRImage(BuildContext context, String findPartnerPostId) async {
    try {
      // Mở picker để chọn ảnh
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      
      if (pickedFile != null) {
        // Mở màn hình xử lý ảnh QR
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRImageScannerScreen(
              imageFile: File(pickedFile.path),
            ),
          ),
        );
        
        // Nếu có kết quả trả về (privateId)
        if (result != null && result is String && result.isNotEmpty) {
          // Gọi cubit để thêm thành viên
          _findPartnerCubit.addParticipant(
            findPartnerPostId: findPartnerPostId,
            privateId: result,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xử lý ảnh QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Hiển thị dialog nhập private ID
  void _showPrivateIdDialog(BuildContext context, String findPartnerPostId, {String? title}) {
    final TextEditingController privateIdController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title ?? 'Nhập mã thành viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: privateIdController,
                decoration: const InputDecoration(
                  labelText: 'Private ID',
                  hintText: 'Nhập mã định danh thành viên',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Private ID là mã định danh duy nhất của người dùng.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final privateId = privateIdController.text.trim();
                if (privateId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập Private ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(dialogContext);
                
                // Gọi cubit để thêm thành viên
                _findPartnerCubit.addParticipant(
                  findPartnerPostId: findPartnerPostId,
                  privateId: privateId,
                );
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String findPartnerPostId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa bài đăng'),
        content: const Text('Bạn có chắc chắn muốn xóa bài đăng tìm bạn ở ghép này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _findPartnerCubit.deleteFindPartnerPost(findPartnerPostId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
} 