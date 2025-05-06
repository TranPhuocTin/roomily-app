import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_cubit.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_state.dart';
import 'package:roomily/data/models/budget_plan_preference.dart';
import 'package:roomily/data/models/budget_plan_room.dart';
import 'package:roomily/presentation/screens/budget_planner_detail_screen.dart';
import 'package:roomily/presentation/screens/speech_budget_plan_screen.dart';
import 'package:roomily/presentation/widgets/common/featured_title.dart';
import 'package:roomily/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:glassmorphism/glassmorphism.dart';

import 'budget_plan_preference_screen.dart';

class BudgetPlannerResultsScreen extends StatefulWidget {
  final String title;
  final BudgetPlanPreference? preference;

  const BudgetPlannerResultsScreen({
    Key? key,
    required this.title,
    this.preference,
  }) : super(key: key);

  @override
  State<BudgetPlannerResultsScreen> createState() => _BudgetPlannerResultsScreenState();
}

class _BudgetPlannerResultsScreenState extends State<BudgetPlannerResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    // Fetch rooms when the screen loads
    context.read<BudgetPlanCubit>().fetchSearchedRooms();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade700,
                Colors.blue.shade500,
              ],
            ),
          ),
        ),
        actions: [
          // Nút điều chỉnh các tùy chọn tìm kiếm
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // builder: (context) => const BudgetPlanPreferenceScreen(),
                  builder: (context) => SpeechBudgetPlanScreen()
                ),
              ).then((_) async {
                // Refresh data when returning from preference screen
                if(!context.mounted) return;
                await context.read<BudgetPlanCubit>().fetchSearchedRooms();
              });
            },
            tooltip: 'Điều chỉnh tùy chọn',
          ),
        ],
      ),
      body: BlocBuilder<BudgetPlanCubit, BudgetPlanState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildResultsSummary(state),
              _buildRoomsList(state),
            ],
          );
        }
      ),
    );
  }

  Widget _buildResultsSummary(BudgetPlanState state) {
    if (state.isLoadingRooms || state.searchedRooms.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kết quả tìm kiếm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tìm thấy ${state.searchedRooms.length} phòng phù hợp với tiêu chí của bạn',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.location_on,
                  '${state.searchedRooms.first.city}',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.meeting_room,
                  '${state.searchedRooms.first.roomType}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(BudgetPlanState state) {
    if (state.isLoadingRooms) {
      return _buildLoadingList();
    }
    if (state.searchedRooms.isEmpty) {
      return _buildEmptyState();
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: AnimationLimiter(
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: BudgetRoomCard(
                      data: _mapApiRoomToBudgetRoomCardData(state.searchedRooms[index]),
                      onTap: () => _navigateToDetail(_mapApiRoomToBudgetRoomCardData(state.searchedRooms[index])),
                    ),
                  ),
                ),
              );
            },
            childCount: state.searchedRooms.length,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ShimmerLoading(
                height: 220,
                width: double.infinity,
                borderRadius: 12,
              ),
            );
          },
          childCount: 4,
        ),
      ),
    );
  }

  // Helper method to map API room data to the UI model
  BudgetRoomCardData _mapApiRoomToBudgetRoomCardData(BudgetPlanRoom room) {
    // Calculate a mock price based on square meters - in a real app, the API would provide this
    final estimatedBasePrice = (room.squareMeters * 100000).toInt();
    final estimatedTotalCost = estimatedBasePrice + 750000; // Add estimated utilities
    
    // Create default utilities list
    final utilities = <String>['Wifi'];
    if (room.numberOfTagsMatched > 0) {
      utilities.add('Chỗ để xe máy');
    }
    if (room.numberOfTagsMatched > 2) {
      utilities.add('Máy giặt');
    }
    if (room.numberOfTagsMatched > 4) {
      utilities.add('Bảo vệ 24/7');
    }
    
    // Determine room type label
    String roomTypeLabel = 'PHÒNG TRỌ';
    if (room.roomType == 'APARTMENT') {
      roomTypeLabel = 'CHUNG CƯ';
    } else if (room.roomType == 'HOUSE') {
      roomTypeLabel = 'NHÀ NGUYÊN CĂN';
    }
    
    return BudgetRoomCardData(
      id: room.roomId,
      imageUrls: room.imageUrl != null ? [room.imageUrl!] : [
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTC52HaCsGrmoVIF2e4PfWrFH7WT5KvZuWE3w&s',
      ],
      roomName: room.roomTitle,
      address: room.roomAddress.isNotEmpty 
          ? room.roomAddress 
          : '${room.ward}, ${room.district}, ${room.city}',
      price: estimatedBasePrice,
      squareMeters: room.squareMeters.toInt(),
      roomType: roomTypeLabel,
      estimatedTotalCost: estimatedTotalCost,
      matchScore: room.numberOfTagsMatched,
      totalCriteria: room.numberOfTags > 0 ? room.numberOfTags : 7, // Default to 7 if no tags
      utilitiesIncluded: utilities,
    );
  }

  void _navigateToDetail(BudgetRoomCardData room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetPlannerDetailScreen(roomId: room.id, imageUrl: room.imageUrls[0],),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy phòng phù hợp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thử thay đổi bộ lọc hoặc điều kiện tìm kiếm',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetRoomCardData {
  final String id;
  final List<String> imageUrls;
  final String roomName;
  final String address;
  final int price;
  final int squareMeters;
  final String roomType;
  final int estimatedTotalCost;
  final int matchScore;
  final int totalCriteria;
  final List<String> utilitiesIncluded;

  BudgetRoomCardData({
    required this.id,
    required this.imageUrls,
    required this.roomName,
    required this.address,
    required this.price,
    required this.squareMeters,
    required this.roomType,
    required this.estimatedTotalCost,
    required this.matchScore,
    required this.totalCriteria,
    required this.utilitiesIncluded,
  });
}

class BudgetRoomCard extends StatefulWidget {
  final BudgetRoomCardData data;
  final VoidCallback onTap;

  const BudgetRoomCard({
    Key? key,
    required this.data,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BudgetRoomCard> createState() => _BudgetRoomCardState();
}

class _BudgetRoomCardState extends State<BudgetRoomCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 420, // Increased height to accommodate content
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Carousel
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: widget.data.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            widget.data.imageUrls[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                    if (widget.data.imageUrls.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.data.imageUrls.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room name and type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.data.roomName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.data.roomType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Address
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.data.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Area and utilities
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.straighten,
                                  size: 12,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.data.squareMeters} m²',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 16),

                      // Prices
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Giá thuê cơ bản',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${FormatUtils.formatCurrency(widget.data.price)} / tháng',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Expanded(
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Row(
                          //         children: [
                          //           const Text(
                          //             'Tổng chi phí ước tính',
                          //             style: TextStyle(
                          //               fontSize: 12,
                          //               color: Colors.grey,
                          //             ),
                          //           ),
                          //           const SizedBox(width: 4),
                          //           Tooltip(
                          //             message: 'Bao gồm tiền điện, nước và các dịch vụ khác',
                          //             child: Icon(
                          //               Icons.info_outline,
                          //               size: 14,
                          //               color: Colors.grey.shade400,
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //       Text(
                          //         '~${FormatUtils.formatCurrency(widget.data.estimatedTotalCost)} / tháng',
                          //         style: const TextStyle(
                          //           fontSize: 16,
                          //           fontWeight: FontWeight.bold,
                          //           color: Colors.red,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),

                      const Spacer(),

                      // Match score and button
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '✅ ${widget.data.matchScore}/${widget.data.totalCriteria} Tiện ích phù hợp',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: widget.data.matchScore / widget.data.totalCriteria,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: widget.onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text('Phân Tích Chi Phí'),
                          ),
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
    );
  }
}