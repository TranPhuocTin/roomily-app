import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/models/find_partner_post_detail.dart';
import 'package:roomily/data/repositories/find_partner_repository_impl.dart';
import 'package:roomily/data/repositories/room_image_repository_impl.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/data/repositories/user_repository_impl.dart';
import 'package:roomily/data/models/user.dart';
import 'package:roomily/data/models/room.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/blocs/find_partner/find_partner_cubit.dart';
import '../../data/blocs/find_partner/find_partner_post_detail_cubit.dart';
import '../../data/blocs/find_partner/find_partner_state.dart';
import '../../data/blocs/home/room_detail_cubit.dart';
import '../../data/blocs/home/room_detail_state.dart';
import '../../data/blocs/home/room_image_cubit.dart';
import '../../data/blocs/home/room_image_state.dart';
import '../../data/blocs/user/user_cubit.dart';

class FindPartnerDetailScreen extends StatefulWidget {
  final String postId;
  final FindPartnerCubit? findPartnerCubit;

  const FindPartnerDetailScreen({
    Key? key,
    required this.postId,
    this.findPartnerCubit,
  }) : super(key: key);

  @override
  State<FindPartnerDetailScreen> createState() => _FindPartnerDetailScreenState();
}

class _FindPartnerDetailScreenState extends State<FindPartnerDetailScreen> {
  late FindPartnerPostDetailCubit _findPartnerPostDetailCubit;
  late FindPartnerCubit _findPartnerCubit;
  late RoomDetailCubit _roomDetailCubit;
  late UserCubit _userCubit;
  String? _currentUserId;
  bool _isPostOwner = false;
  Room? _room;
  User? _poster;

  @override
  void initState() {
    super.initState();
    _findPartnerPostDetailCubit = FindPartnerPostDetailCubit(
      findPartnerRepository: FindPartnerRepositoryImpl(dio: DioConfig.createDio()),
    );
    
    // Sử dụng FindPartnerCubit được truyền vào nếu có, nếu không thì tạo mới
    _findPartnerCubit = widget.findPartnerCubit ?? FindPartnerCubit(
      FindPartnerRepositoryImpl(dio: DioConfig.createDio()),
    );

    // Initialize RoomDetailCubit
    _roomDetailCubit = RoomDetailCubit(
      RoomRepositoryImpl(dio: DioConfig.createDio()),
    );

    // Initialize UserCubit
    _userCubit = UserCubit(
      userRepository: UserRepositoryImpl(),
    );

    // Lấy thông tin userId hiện tại
    _getCurrentUserId();

    // Load find partner post details
    _loadPostDetails();
  }

  void _getCurrentUserId() {
    try {
      final authService = GetIt.I<AuthService>();
      setState(() {
        _currentUserId = authService.userId;
      });
      print('Current user ID: $_currentUserId');
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  void _loadPostDetails() {
    _findPartnerPostDetailCubit.getFindPartnerPostDetail(widget.postId);
  }

  @override
  void dispose() {
    _findPartnerPostDetailCubit.close();
    _roomDetailCubit.close();
    _userCubit.close();
    // Chỉ đóng FindPartnerCubit nếu nó được tạo mới trong màn hình này
    if (widget.findPartnerCubit == null) {
      _findPartnerCubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: _findPartnerPostDetailCubit,
        ),
        BlocProvider.value(
          value: _findPartnerCubit,
        ),
        BlocProvider.value(
          value: _roomDetailCubit,
        ),
        BlocProvider.value(
          value: _userCubit,
        ),
        BlocProvider(
          create: (context) => RoomImageCubit(
            RoomImageRepositoryImpl(dio: DioConfig.createDio()),
          ),
        ),
      ],
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<FindPartnerPostDetailCubit, FindPartnerPostDetailState>(
              listener: (context, state) {
                if (state is FindPartnerPostDetailLoaded) {
                  // Kiểm tra quyền sở hữu khi tải dữ liệu thành công
                  setState(() {
                    _isPostOwner = _currentUserId != null && _currentUserId == state.postDetail.posterUserId;
                  });
                  print('User is post owner: $_isPostOwner');
                  
                  // Fetch room details when post details are loaded
                  _roomDetailCubit.fetchRoomById(state.postDetail.roomId);
                  
                  // Fetch room image when post details are loaded
                  context.read<RoomImageCubit>().fetchRoomImages(state.postDetail.roomId);
                }
              },
            ),
            BlocListener<RoomDetailCubit, RoomDetailState>(
              listener: (context, state) {
                if (state is RoomDetailLoaded) {
                  setState(() {
                    _room = state.room;
                  });
                }
              },
            ),
            BlocListener<FindPartnerCubit, FindPartnerState>(
              listener: (context, state) {
                if (state is FindPartnerParticipantRemoved) {
                  // Hiển thị thông báo khi xóa thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa thành viên thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Tải lại chi tiết bài đăng
                  _loadPostDetails();
                } else if (state is FindPartnerExiting) {
                  // Hiển thị loading khi đang rời nhóm
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang xử lý...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else if (state is FindPartnerExited) {
                  // Hiển thị thông báo khi rời nhóm thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã rời khỏi nhóm thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Quay lại màn hình trước
                  Navigator.of(context).pop();
                } else if (state is FindPartnerDeleting) {
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
                  
                  // Quay lại màn hình trước
                  Navigator.of(context).pop();
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
          child: BlocBuilder<FindPartnerPostDetailCubit, FindPartnerPostDetailState>(
            builder: (context, state) {
              if (state is FindPartnerPostDetailLoading) {
                return _buildLoadingState();
              }

              if (state is FindPartnerPostDetailError) {
                return _buildErrorState(context, state);
              }

              if (state is FindPartnerPostDetailLoaded) {
                return _buildPostDetailContent(context, state.postDetail);
              }

              return const Center(
                child: Text('Không tìm thấy dữ liệu'),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 200,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 300,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 20,
                    width: 150,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FindPartnerPostDetailError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Lỗi: ${state.message}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadPostDetails();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostDetailContent(BuildContext context, FindPartnerPostDetail post) {
    // Format dates
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String createdDate = formatter.format(post.createdAt);
    
    // Lọc danh sách thành viên để tránh hiển thị trùng với người đăng
    final nonPosterParticipants = post.participants
        .where((user) => user.userId != post.posterUserId)
        .toList();
    
    return CustomScrollView(
      slivers: [
        // Sliver app bar with room details and image
        SliverAppBar(
          expandedHeight: 250.0,
          pinned: true,
          actions: [
            if (_isPostOwner)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmationDialog(post.id);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Xóa bài đăng'),
                    ),
                  ),
                ],
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Room image from RoomImageCubit
                BlocBuilder<RoomImageCubit, RoomImageState>(
                  builder: (context, state) {
                    if (state is RoomImageLoaded && state.images.isNotEmpty) {
                      return Image.network(
                        state.images.first.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildGradientBackground(context);
                        },
                      );
                    }
                    return _buildGradientBackground(context);
                  },
                ),
                // Gradient overlay for better text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                // Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BlocBuilder<RoomDetailCubit, RoomDetailState>(
                          builder: (context, state) {
                            if (state is RoomDetailLoaded) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.room.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          state.room.address,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusChip(post),
                            const SizedBox(width: 8),
                            _buildTypeChip(post),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick info
                _buildQuickInfoCard(post),
                
                const SizedBox(height: 24),
                
                // Room details
                _buildSectionTitle('Thông tin phòng'),
                BlocBuilder<RoomDetailCubit, RoomDetailState>(
                  builder: (context, state) {
                    if (state is RoomDetailLoaded) {
                      return _buildRoomDetails(state.room);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Post description
                if (post.description != null && post.description!.isNotEmpty) ...[
                  _buildSectionTitle('Mô tả'),
                  _buildDescriptionCard(post.description!),
                  const SizedBox(height: 24),
                ],
                
                // Hiển thị tiêu đề thành viên
                _buildSectionTitle('Thành viên (${nonPosterParticipants.length + 1}/${post.maxPeople})'),
                
                // Hiển thị danh sách thành viên hoặc thông báo
                nonPosterParticipants.isNotEmpty
                    ? Column(
                        children: nonPosterParticipants
                            .map((participant) => _buildParticipantInfo(
                                  participant,
                                  showRemoveButton: _isPostOwner,
                                  onRemove: () => _showRemoveParticipantDialog(post.id, participant.userId),
                                ))
                            .toList(),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'Chưa có thành viên khác tham gia',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                
                const SizedBox(height: 24),
                
                // Nút "Rời nhóm" - chỉ hiển thị khi người dùng không phải chủ bài đăng
                if (!_isPostOwner && _currentUserId != null && post.participants.any((p) => p.userId == _currentUserId)) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => _showExitConfirmationDialog(post.id),
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      label: const Text(
                        'Rời nhóm',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGradientBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(FindPartnerPostDetail post) {
    final bool isActive = post.status == 'ACTIVE';
    final bool isFull = post.currentPeople >= post.maxPeople;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? isFull ? Colors.orange.withOpacity(0.9) : Colors.green.withOpacity(0.9)
            : Colors.grey.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive
            ? isFull ? 'Đủ thành viên' : 'Đang hoạt động'
            : 'Đã đóng',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildTypeChip(FindPartnerPostDetail post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        post.type == 'NEW_RENTAL' ? 'Tìm bạn thuê mới' : 'Tìm thêm người ở ghép',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildQuickInfoCard(FindPartnerPostDetail post) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoColumn(
              icon: Icons.people,
              value: '${post.currentPeople}/${post.maxPeople}',
              label: 'Thành viên',
              color: Colors.blue,
            ),
            BlocBuilder<RoomDetailCubit, RoomDetailState>(
              builder: (context, state) {
                if (state is RoomDetailLoaded) {
                  return _buildInfoColumn(
                    icon: Icons.monetization_on,
                    value: _formatCurrency(state.room.price),
                    label: 'Giá phòng',
                    color: Colors.green,
                  );
                }
                return _buildInfoColumn(
                  icon: Icons.monetization_on,
                  value: '...',
                  label: 'Giá phòng',
                  color: Colors.green,
                );
              },
            ),
            _buildInfoColumn(
              icon: Icons.calendar_today,
              value: DateFormat('dd/MM/yyyy').format(post.createdAt),
              label: 'Ngày tạo',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildRoomDetails(room) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRoomDetailRow(
              icon: Icons.attach_money,
              iconColor: Colors.green,
              label: 'Giá thuê',
              value: formatter.format(room.price),
            ),
            const Divider(height: 24),
            _buildRoomDetailRow(
              icon: Icons.square_foot,
              iconColor: Colors.orange,
              label: 'Diện tích',
              value: '${room.squareMeters} m²',
            ),
            const Divider(height: 24),
            _buildRoomDetailRow(
              icon: Icons.people,
              iconColor: Colors.blue,
              label: 'Số người tối đa',
              value: '${room.maxPeople} người',
            ),
            const Divider(height: 24),
            _buildRoomDetailRow(
              icon: Icons.category,
              iconColor: Colors.purple,
              label: 'Loại phòng',
              value: room.type,
            ),
            const Divider(height: 24),
            _buildRoomDetailRow(
              icon: Icons.location_on,
              iconColor: Colors.red,
              label: 'Địa chỉ',
              value: '${room.address}, ${room.ward}, ${room.district}, ${room.city}',
            ),
            if (room.tags.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_offer, color: Colors.teal, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tiện ích',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: room.tags.map<Widget>((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.teal.withOpacity(0.3)),
                              ),
                              child: Text(
                                tag.name,
                                style: TextStyle(
                                  color: Colors.teal[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRoomDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDescriptionCard(String description) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin thêm từ người đăng',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParticipantInfo(Participant participant, {bool showRemoveButton = false, VoidCallback? onRemove}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, size: 30, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        participant.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (showRemoveButton && onRemove != null)
                        IconButton(
                          icon: const Icon(Icons.person_remove, color: Colors.red),
                          tooltip: 'Xóa thành viên',
                          onPressed: onRemove,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          iconSize: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          participant.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (participant.gender != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          participant.gender!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog xác nhận xóa thành viên
  void _showRemoveParticipantDialog(String findPartnerPostId, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa thành viên'),
        content: const Text('Bạn có chắc chắn muốn xóa thành viên này khỏi nhóm tìm bạn ở ghép không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Gọi cubit để xóa thành viên - sử dụng _findPartnerCubit trực tiếp thay vì context.read
              _findPartnerCubit.removeParticipant(
                findPartnerPostId: findPartnerPostId,
                userId: userId,
              );
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

  // Dialog xác nhận rời nhóm
  void _showExitConfirmationDialog(String findPartnerPostId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận rời nhóm'),
        content: const Text('Bạn có chắc chắn muốn rời khỏi nhóm tìm bạn ở ghép này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _findPartnerCubit.exitFindPartnerPost(findPartnerPostId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
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