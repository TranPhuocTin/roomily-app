import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/models/find_partner_post.dart';
import 'package:roomily/data/models/find_partner_post_create.dart';
import 'package:roomily/data/repositories/find_partner_repository.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/blocs/chat_room/direct_chat_room_cubit.dart';
import 'package:dio/dio.dart';
import 'package:roomily/data/repositories/find_partner_repository_impl.dart';
import 'package:roomily/data/repositories/user_repository.dart';
import 'package:roomily/data/blocs/user/user_cubit.dart';
import 'package:roomily/data/blocs/user/user_state.dart';

import '../../../data/blocs/chat_room/direct_chat_room_state.dart';
import '../../../data/blocs/find_partner/find_partner_cubit.dart';
import '../../../data/blocs/find_partner/find_partner_state.dart';
import '../../../data/blocs/home/room_detail_cubit.dart';
import '../../../data/blocs/home/room_detail_state.dart';

class RoommateFinder extends StatefulWidget {
  final Room room;
  
  const RoommateFinder({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  State<RoommateFinder> createState() => _RoommateFinderState();
}

class _RoommateFinderState extends State<RoommateFinder> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconTurns;
  bool _isExpanded = false;
  late FindPartnerCubit _findPartnerCubit;
  late UserCubit _userCubit;
  StreamSubscription? _roomDetailSubscription;
  bool _showAllPosts = false;
  final int _maxPostsToShow = 3;
  
  // Thêm biến theo dõi tình trạng tải dữ liệu ban đầu
  bool _initialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(_animationController);
    
    // Sử dụng FindPartnerRepository từ GetIt để đảm bảo nó đã được khởi tạo với Dio mới nhất
    _findPartnerCubit = FindPartnerCubit(GetIt.I<FindPartnerRepository>());
    _userCubit = UserCubit(userRepository: GetIt.I<UserRepository>());
    
    // We'll listen for room details in didChangeDependencies instead of here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Cancel any existing subscription
    _roomDetailSubscription?.cancel();
    
    // Check if room data is available and load find partner data
    final roomDetailState = context.read<RoomDetailCubit>().state;
    if (roomDetailState is RoomDetailLoaded && !_initialDataLoaded) {
      // Chỉ tải dữ liệu ban đầu một lần
      _loadFindPartnerData();
      _initialDataLoaded = true;
    }
    
    // Setup a listener for room detail state changes
    _roomDetailSubscription = context.read<RoomDetailCubit>().stream.listen((state) {
      if (state is RoomDetailLoaded) {
        _loadFindPartnerData();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _findPartnerCubit.close();
    _userCubit.close();
    _roomDetailSubscription?.cancel();
    super.dispose();
  }

  // Tạo phương thức mới để mở expansion panel
  void _expandPanel() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
        _animationController.forward();
      });
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        // Still refresh data when expanding to ensure we have the latest data
        _loadFindPartnerData();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _loadFindPartnerData() {
    // Sử dụng roomId từ widget mà không cần kiểm tra RoomDetailCubit
    final roomId = widget.room.id ?? '';
    if (roomId.isNotEmpty) {
      _findPartnerCubit.getFindPartnersForRoom(roomId);
    }
  }

  void _navigateToAllPostsScreen() {
    // Set state to show all posts
    setState(() {
      _showAllPosts = true;
    });
    
    // Or navigate to a dedicated screen with all posts
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => AllRoommatePostsScreen(
    //       roomId: widget.room.id ?? '',
    //       findPartnerCubit: _findPartnerCubit,
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _findPartnerCubit),
        BlocProvider.value(value: _userCubit),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Custom header
            InkWell(
              onTap: _toggleExpansion,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tìm bạn ở trọ chung',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<FindPartnerCubit, FindPartnerState>(
                      builder: (context, state) {
                        int count = 0;
                        if (state is FindPartnerLoaded) {
                          count = state.posts.length;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    RotationTransition(
                      turns: _iconTurns,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
              ),
            ),
            
            // Animated content
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                height: _isExpanded ? null : 0,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
                child: BlocBuilder<FindPartnerCubit, FindPartnerState>(
                  builder: (context, state) {
                    if (state is FindPartnerLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is FindPartnerLoaded) {
                      final posts = state.posts;
                      if (posts.isEmpty) {
                        return _buildEmptyState(context);
                      } else {
                        // Determine how many posts to show
                        final displayPosts = _showAllPosts 
                          ? posts 
                          : posts.take(_maxPostsToShow).toList();
                        final hasMorePosts = posts.length > _maxPostsToShow;
                        
                        return Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: displayPosts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildRoommatePostCard(context, displayPosts[index]);
                              },
                            ),
                            
                            // Show "View more" button if not showing all posts and there are more posts
                            if (hasMorePosts && !_showAllPosts)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: TextButton(
                                  onPressed: _navigateToAllPostsScreen,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    backgroundColor: Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Xem thêm ${posts.length - _maxPostsToShow} bài đăng',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            _buildCreatePostButton(context),
                            const SizedBox(height: 8),
                          ],
                        );
                      }
                    } else if (state is FindPartnerError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Column(
                            children: [
                              Text(
                                'Có lỗi xảy ra: ${state.message}',
                                style: TextStyle(color: Colors.red.shade700),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadFindPartnerData,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có ai đăng tìm bạn ở ghép',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildCreatePostButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _checkAndShowRoommateRequestForm(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Đăng tìm bạn ở ghép',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // Phương thức mới để kiểm tra người dùng trước khi hiển thị form
  void _checkAndShowRoommateRequestForm(BuildContext context) async {
    // Sử dụng roomId từ widget mà không cần kiểm tra RoomDetailCubit
    final roomId = widget.room.id ?? '';
    if (roomId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo yêu cầu tìm bạn ở ghép vào lúc này. ID phòng không hợp lệ.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Hiển thị trạng thái đang kiểm tra
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang kiểm tra thông tin...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    // Sử dụng cubit hiện có thay vì tạo cubit mới
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => BlocProvider.value(
          value: _findPartnerCubit,
          child: BlocConsumer<FindPartnerCubit, FindPartnerState>(
            listener: (context, state) {
              if (state is FindPartnerUserCheckResult) {
                Navigator.of(dialogContext).pop(); // Đóng dialog loading
                
                if (state.isUserInPost) {
                  // Người dùng đã tham gia vào một nhóm tìm bạn ở ghép
                  if (mounted) {
                    _showAlreadyInPostDialog(context);
                  }
                } else {
                  // Người dùng chưa tham gia, hiển thị form đăng bài
                  if (mounted) {
                    _showRoommateRequestForm(context);
                  }
                }
              } else if (state is FindPartnerError) {
                Navigator.of(dialogContext).pop(); // Đóng dialog loading
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi kiểm tra: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              // Kích hoạt kiểm tra khi dialog hiển thị
              if (state is! FindPartnerChecking && state is! FindPartnerUserCheckResult) {
                // Đảm bảo không gọi checkUserInFindPartnerPost nếu đã đang kiểm tra
                _findPartnerCubit.checkUserInFindPartnerPost(roomId);
              }
              
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    const Text('Đang kiểm tra...'),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }
  
  // Dialog hiển thị khi người dùng đã tham gia vào một nhóm
  void _showAlreadyInPostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon phía trên
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  size: 40,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 16),
              
              // Tiêu đề
              const Text(
                'Bạn đã tham gia nhóm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Nội dung
              Text(
                'Bạn đã tham gia vào một nhóm tìm bạn ở ghép. Bạn không thể đăng bài mới cho đến khi rời khỏi nhóm hiện tại.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Nút xem nhóm của tôi
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       // Có thể thêm điều hướng đến trang để xem nhóm hiện tại
              //       Navigator.of(context).pop();
              //
              //       // Mở rộng expansion title để xem nhóm hiện tại
              //       _expandPanel();
              //
              //       _findPartnerCubit.getActiveFindPartnerPosts();
              //       // TODO: Điều hướng đến trang quản lý nhóm bạn ở ghép
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Theme.of(context).primaryColor,
              //       foregroundColor: Colors.white,
              //       padding: const EdgeInsets.symmetric(vertical: 14),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //       elevation: 0,
              //     ),
              //     child: const Text(
              //       'Xem nhóm của tôi',
              //       style: TextStyle(fontWeight: FontWeight.w600),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 12),
              
              // Nút đóng
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Đóng',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoommateRequestForm(BuildContext context) {
    int currentPeople = 1;
    int maxPeople = 4;
    String? description;

    // Sử dụng roomId từ widget
    final roomId = widget.room.id ?? '';
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tạo yêu cầu tìm bạn ở ghép vào lúc này. ID phòng không hợp lệ.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Lấy số người tối đa của phòng từ Room object
    final roomMaxPeople = widget.room.maxPeople;
    
    // Đảm bảo maxPeople mặc định không vượt quá số người tối đa của phòng
    maxPeople = maxPeople > roomMaxPeople ? roomMaxPeople : maxPeople;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: _findPartnerCubit,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đăng tìm bạn ở ghép',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Mô tả ngắn
                  Text(
                    'Tạo nhóm tìm bạn ở ghép để thuê phòng này cùng nhau',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Type Selection
                  
                  // Thông báo về số người tối đa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Phòng này có thể chứa tối đa ${widget.room.maxPeople} người.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Number of people
                  Text(
                    'Số lượng người',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hiện có',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: StatefulBuilder(
                                builder: (context, setState) {
                                  return DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: currentPeople,
                                      isExpanded: true,
                                      icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
                                      items: List.generate(
                                        roomMaxPeople,
                                        (index) => DropdownMenuItem(
                                          value: index + 1,
                                          child: Text('${index + 1}'),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => currentPeople = value);
                                          
                                          // Đảm bảo maxPeople luôn lớn hơn hoặc bằng currentPeople
                                          if (maxPeople < currentPeople) {
                                            maxPeople = currentPeople;
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tối đa',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: StatefulBuilder(
                                builder: (context, setState) {
                                  return DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: maxPeople,
                                      isExpanded: true,
                                      icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
                                      items: List.generate(
                                        roomMaxPeople, // Giới hạn số người tối đa bằng maxPeople của phòng
                                        (index) => DropdownMenuItem(
                                          value: index + 1,
                                          child: Text('${index + 1}'),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => maxPeople = value);
                                          
                                          // Đảm bảo currentPeople không lớn hơn maxPeople
                                          if (currentPeople > maxPeople) {
                                            currentPeople = maxPeople;
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Mô tả yêu cầu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Mô tả chi tiết yêu cầu của bạn...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    style: const TextStyle(fontSize: 15),
                    onChanged: (value) {
                      description = value;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: BlocConsumer<FindPartnerCubit, FindPartnerState>(
                      listener: (context, state) {
                        if (state is FindPartnerSubmitted) {
                          Navigator.pop(context);
                          
                          // Mở rộng expansion title sau khi đăng bài thành công
                          _expandPanel();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Đăng tìm bạn ở ghép thành công!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        } else if (state is FindPartnerError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: ${state.message}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is FindPartnerSubmitting
                              ? null
                              : () {
                                  final findPartnerPostCreate = FindPartnerPostCreate.create(
                                    description: description,
                                    maxPeople: maxPeople,
                                    roomId: roomId,
                                    currentParticipantPrivateIds: [],
                                  );
                                  context.read<FindPartnerCubit>().createFindPartner(findPartnerPostCreate);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: state is FindPartnerSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Đăng bài',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoommatePostCard(BuildContext context, FindPartnerPost post) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge and time indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    post.type ?? 'Tìm bạn ở ghép',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Text(
                  post.createdAt != null ? _getTimeAgo(post.createdAt!) : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post description
            Text(
              post.description ?? 'Không có mô tả',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // People count with current/max
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Hiện có ${post.currentPeople}/${post.maxPeople} người',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Participant avatars in a row
            Row(
              children: [
                ...post.participants.map((participant) => _buildLocalParticipantAvatar(
                  LocalParticipant(
                    userId: participant.userId,
                    fullName: participant.fullName,
                    gender: participant.gender ?? 'Không xác định',
                  ),
                  isCreator: participant.userId == post.posterId,
                )),
                // Add empty slots
                for (int i = 0; i < post.maxPeople - post.currentPeople; i++)
                  _buildEmptySlotAvatar(),
              ],
            ),
            const SizedBox(height: 16),

            // Add chat button
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<FindPartnerCubit, FindPartnerState>(
                    builder: (context, state) {
                      final authService = GetIt.instance<AuthService>();
                      final currentUserId = authService.userId;

                      // Check if current user is a find partner post owner in any post
                      bool isAnyPostOwner = false;
                      if (state is FindPartnerLoaded) {
                        isAnyPostOwner = state.posts.any((p) => p.posterId == currentUserId);
                      }

                      // Hide chat button if:
                      // 1. Current user is the post owner of this post
                      // 2. Current user is a find partner post owner in any post
                      final bool shouldHideButton = 
                        post.posterId == currentUserId || 
                        isAnyPostOwner;

                      if (shouldHideButton) {
                        return const SizedBox.shrink(); // Hide button completely
                      }

                      return OutlinedButton.icon(
                        icon: BlocBuilder<DirectChatRoomCubit, DirectChatRoomState>(
                          builder: (context, directChatState) {
                            bool isLoading = directChatState is DirectChatRoomLoadingForUser;

                            return isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  )
                                : const Icon(Icons.chat_bubble_outline, size: 18);
                          },
                        ),
                        label: BlocBuilder<DirectChatRoomCubit, DirectChatRoomState>(
                          builder: (context, directChatState) {
                            bool isLoading = directChatState is DirectChatRoomLoadingForUser;
                            return Text(isLoading ? 'Đang xử lý...' : 'Nhắn tin');
                          },
                        ),
                        onPressed: () => _openDirectChat(context, post),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalParticipantAvatar(LocalParticipant participant, {bool isCreator = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Stack(
            children: [
              BlocProvider.value(
                value: _userCubit..getUserInfoById(participant.userId),
                child: BlocBuilder<UserCubit, UserInfoState>(
                  builder: (context, state) {
                    if (state is UserInfoByIdLoaded && state.user.profilePicture != null && state.user.profilePicture!.isNotEmpty) {
                      // Chỉ hiển thị avatar khi đã load thành công và có profile picture
                      return CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(state.user.profilePicture!),
                      );
                    } else {
                      // Hiển thị shimmer trong mọi trường hợp khác
                      return _buildShimmerAvatar();
                    }
                  },
                ),
              ),
              if (isCreator)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hideMiddleAndLastName(participant.fullName),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerAvatar() {
    return SizedBox(
      width: 40,
      height: 40,
      child: ClipOval(
        child: ShimmerEffect(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 40,
            height: 40,
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlotAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Còn trống',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final difference = DateTime.now().difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _openDirectChat(BuildContext context, FindPartnerPost post) {
    // Không hiển thị dialog loading riêng
    final directChatRoomCubit = context.read<DirectChatRoomCubit>();
    
    // Để cubit quản lý trạng thái loading riêng
    directChatRoomCubit.createDirectChatRoomToUser(
      post.posterId,
      findPartnerPostId: post.findPartnerPostId,
      context: context, // Context sẽ được sử dụng cho điều hướng
    ).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${error.toString()}'), backgroundColor: Colors.red)
      );
    });
  }
}

// Model classes for roommatePost and participant based on the provided JSON
class RoommatePost {
  final String id;
  final int currentPeople;
  final int maxPeople;
  final String status;
  final String posterId;
  final String roomId;
  final String rentedRoomId;
  final List<Participant> participants;
  final String type;
  final String description;
  final DateTime createdAt;

  RoommatePost({
    required this.id,
    required this.currentPeople,
    required this.maxPeople,
    required this.status,
    required this.posterId,
    required this.roomId,
    required this.rentedRoomId,
    required this.participants,
    required this.type,
    required this.description,
    required this.createdAt,
  });
}

class Participant {
  final String userId;
  final String fullName;
  final String address;
  final String gender;
  final String avatarUrl;

  Participant({
    required this.userId,
    required this.fullName,
    required this.address,
    required this.gender,
    required this.avatarUrl,
  });
}

class LocalParticipant {
  final String userId;
  final String fullName;
  final String gender;

  LocalParticipant({
    required this.userId,
    required this.fullName,
    required this.gender,
  });
}

String hideMiddleAndLastName(String fullName) {
  fullName = fullName.trim();
  List<String> parts = fullName.split(RegExp(r'\s+'));

  if (parts.length > 1) {
    // Có khoảng trắng, hiển thị họ + "*****"
    return '${parts.first} *****';
  } else {
    // Không có khoảng trắng, là tên liền, ví dụ "MinhAnh"
    if (fullName.length <= 2) {
      return fullName[0] + '*' * (fullName.length - 1);
    } else {
      int visibleLength = (fullName.length / 2).ceil(); // Lấy khoảng nửa đầu
      String visiblePart = fullName.substring(0, visibleLength);
      String hiddenPart = '*' * (fullName.length - visibleLength);
      return visiblePart + hiddenPart;
    }
  }
}

// Add ShimmerEffect widget at the end of the file
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerEffect({
    Key? key,
    required this.child,
    this.baseColor = Colors.grey,
    this.highlightColor = Colors.white,
  }) : super(key: key);

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(
                _animation.value * -1,
                _animation.value,
              ),
              end: Alignment(
                _animation.value,
                _animation.value * -1,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
