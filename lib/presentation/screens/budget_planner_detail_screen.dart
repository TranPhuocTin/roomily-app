import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'dart:math';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:roomily/core/utils/tag_category.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_cubit.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_state.dart';
import 'package:roomily/data/models/budget_plan_room_detail.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/presentation/screens/budget_planner_results_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:roomily/data/blocs/home/room_detail_cubit.dart';
import 'package:roomily/data/blocs/home/room_detail_state.dart';
import 'package:roomily/data/blocs/chat_room/direct_chat_room_cubit.dart';
import 'package:roomily/data/blocs/chat_room/direct_chat_room_state.dart';
import 'package:roomily/data/blocs/home/favorite_cubit.dart';
import 'package:roomily/data/blocs/home/favorite_state.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/data/repositories/chat_room_repository.dart';
import 'package:roomily/data/blocs/chat_room/chat_room_cubit.dart';

// Legend item data class for pie chart
class _LegendItem {
  final Color color;
  final String title;
  final String value;
  final String percentage;
  
  _LegendItem({
    required this.color,
    required this.title,
    required this.value,
    required this.percentage,
  });
}

class BudgetPlannerDetailScreen extends StatefulWidget {
  final String roomId;
  final String imageUrl;

  const BudgetPlannerDetailScreen({
    Key? key,
    required this.roomId,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<BudgetPlannerDetailScreen> createState() => _BudgetPlannerDetailScreenState();
}

class _BudgetPlannerDetailScreenState extends State<BudgetPlannerDetailScreen> with SingleTickerProviderStateMixin {
  // Default utility usage values from model
  double _electricityUsage = 0;
  double _waterUsage = 0;
  
  // Utility rates from the model
  double _electricityRate = 0;
  double _waterRate = 0;
  int _wifiCost = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isTagsExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Fetch budget plan detail from API
    context.read<BudgetPlanCubit>().fetchRoomBudgetPlanDetail(widget.roomId, 1);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Room Detail Provider
        BlocProvider<RoomDetailCubit>(
          create: (context) => RoomDetailCubit(GetIt.I<RoomRepository>())
            ..fetchRoomById(widget.roomId),
        ),
        // Favorite Provider
        BlocProvider<FavoriteCubit>(
          create: (context) => FavoriteCubit(GetIt.I<FavoriteRepository>())
            ..checkRoomIsFavorite(widget.roomId),
        ),
        // Chat Room Provider
        BlocProvider<ChatRoomCubit>(
          create: (context) => ChatRoomCubit(repository: GetIt.I<ChatRoomRepository>()),
        ),
        // Direct Chat Room Provider
        BlocProvider<DirectChatRoomCubit>(
          create: (context) {
            final roomDetailCubit = context.read<RoomDetailCubit>();
            final chatRoomCubit = context.read<ChatRoomCubit>();
            return DirectChatRoomCubit(
              repository: GetIt.I<ChatRoomRepository>(),
              chatRoomCubit: chatRoomCubit,
              roomDetailCubit: roomDetailCubit,
            );
          },
        ),
      ],
      child: Scaffold(
        body: BlocConsumer<BudgetPlanCubit, BudgetPlanState>(
          listener: (context, state) {
            if (!state.isLoadingRoomDetail && state.roomBudgetPlanDetail != null) {
              _initializeDataFromState(state);
              _animationController.forward();
            }
          },
          builder: (context, state) {
            if (state.isLoadingRoomDetail) {
              return _buildLoadingState();
            }
            
            if (state.roomBudgetPlanDetail == null) {
              return _buildErrorState();
            }
            
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(state.roomBudgetPlanDetail!),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRoomHeader(state.roomBudgetPlanDetail!),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              _buildTagsSection(state.roomBudgetPlanDetail!),
                              _buildInitialCostSection(state.roomBudgetPlanDetail!),
                              _buildMonthlyCostSection(state.roomBudgetPlanDetail!),
                              _buildAnalysisSection(state.roomBudgetPlanDetail!),
                              _buildActionButtons(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  void _initializeDataFromState(BudgetPlanState state) {
    if (state.roomBudgetPlanDetail != null) {
      setState(() {
        _electricityUsage = state.roomBudgetPlanDetail!.estimatedMonthlyElectricityUsage.toDouble();
        _waterUsage = state.roomBudgetPlanDetail!.estimatedMonthlyWaterUsage.toDouble();
        _electricityRate = state.roomBudgetPlanDetail!.averageElectricityCost.toDouble();
        _waterRate = state.roomBudgetPlanDetail!.averageWaterCost.toDouble();
        _wifiCost = state.roomBudgetPlanDetail!.wifiCost;
      });
    }
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải thông tin chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng thử lại sau',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<BudgetPlanCubit>().fetchRoomBudgetPlanDetail(widget.roomId, 1);
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BudgetPlanRoomDetail roomDetail) {
    final room = roomDetail.room;
    // Try to get an image URL from the room
    String? imageUrl = widget.imageUrl;
    
    return SliverAppBar(
      foregroundColor: Colors.black,
      expandedHeight: 200.0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            const Text(
              'Không có hình ảnh',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomHeader(BudgetPlanRoomDetail roomDetail) {
    final room = roomDetail.room;
    final matchPercentage = roomDetail.matchedTags.length / 
      (roomDetail.matchedTags.length + roomDetail.unmatchedTags.length);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${roomDetail.matchedTags.length}/${roomDetail.matchedTags.length + roomDetail.unmatchedTags.length}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'Phù hợp',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFeatureChip(
                room.type,
                Icons.home_outlined,
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildFeatureChip(
                '${room.squareMeters} m²',
                Icons.straighten,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialCostSection(BudgetPlanRoomDetail roomDetail) {
    final room = roomDetail.room;
    final upFrontCost = roomDetail.upFrontCost;
    final initialRent = room.price;
    final deposit = upFrontCost - initialRent;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Chi Phí Ban Đầu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCostRow(
                    'Tiền thuê tháng đầu',
                    FormatUtils.formatCurrency(initialRent.toInt()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            const Text(
                              'Tiền cọc',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Số tiền đặt cọc khi thuê phòng',
                              child: Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          FormatUtils.formatCurrency(deposit.toInt()),
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TỔNG BAN ĐẦU:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        FormatUtils.formatCurrency(upFrontCost),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
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
  
  Widget _buildMonthlyCostSection(BudgetPlanRoomDetail roomDetail) {
    final room = roomDetail.room;
    
    // Calculate costs based on the model data
    final rentCost = room.price.toInt();
    final electricityCost = (_electricityUsage * _electricityRate).toInt();
    final waterCost = (_waterUsage * _waterRate).toInt();
    
    // Wifi cost logic: if includeWifi is true, then additional cost is 0,
    // but if it's false, we should pay wifiCost.
    // Special case: If wifiCost is 0 but includeWifi is false, it likely means
    // the room doesn't have WiFi available at all
    final internetCost = roomDetail.includeWifi ? 0 : _wifiCost;
    final hasWifi = roomDetail.includeWifi || _wifiCost > 0;
    
    // Total monthly cost
    final totalMonthlyCost = rentCost + electricityCost + waterCost + 
                            internetCost;
    
    // Pie chart data
    final List<PieChartSectionData> pieChartData = [
      PieChartSectionData(
        value: rentCost.toDouble(),
        title: '',
        color: Colors.blue,
        radius: 50,
        showTitle: false,
      ),
      PieChartSectionData(
        value: electricityCost.toDouble(),
        title: '',
        color: Colors.orange,
        radius: 50,
        showTitle: false,
      ),
      PieChartSectionData(
        value: waterCost.toDouble(),
        title: '',
        color: Colors.lightBlue,
        radius: 50,
        showTitle: false,
      ),
    ];
    
    // Add Wifi to chart only if it's available and not included in rent
    if (!roomDetail.includeWifi && _wifiCost > 0) {
      pieChartData.add(
        PieChartSectionData(
          value: internetCost.toDouble(),
          title: '',
          color: Colors.purple,
          radius: 50,
          showTitle: false,
        ),
      );
    }
    
    // Legend items
    final List<_LegendItem> legendItems = [
      _LegendItem(
        color: Colors.blue,
        title: 'Thuê',
        value: FormatUtils.formatCurrency(rentCost),
        percentage: (rentCost / totalMonthlyCost * 100).toStringAsFixed(1) + '%',
      ),
      _LegendItem(
        color: Colors.orange,
        title: 'Điện',
        value: FormatUtils.formatCurrency(electricityCost),
        percentage: (electricityCost / totalMonthlyCost * 100).toStringAsFixed(1) + '%',
      ),
      _LegendItem(
        color: Colors.lightBlue,
        title: 'Nước',
        value: FormatUtils.formatCurrency(waterCost),
        percentage: (waterCost / totalMonthlyCost * 100).toStringAsFixed(1) + '%',
      ),
    ];
    
    // Add Wifi to legend only if it's available and not included in rent
    if (!roomDetail.includeWifi && _wifiCost > 0) {
      legendItems.add(
        _LegendItem(
          color: Colors.purple,
          title: 'Wifi',
          value: FormatUtils.formatCurrency(internetCost),
          percentage: (internetCost / totalMonthlyCost * 100).toStringAsFixed(1) + '%',
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              const Text(
                'Chi Phí Hàng Tháng (Dự Kiến)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Pie chart and legend
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pie Chart
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: pieChartData,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              
              // Legend
              Expanded(
                flex: 2,
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legendItems.map((item) => _buildLegendItem(item)).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Fixed rent
          _buildCostRow(
            'Tiền thuê cố định',
            FormatUtils.formatCurrency(rentCost),
          ),
          
          // Electricity
          const SizedBox(height: 12),
          _buildSliderCostRow(
            'Tiền điện (ước tính)',
            FormatUtils.formatCurrency(electricityCost),
            '@ ${FormatUtils.formatCurrency(_electricityRate.toInt())}/kWh',
            _electricityUsage,
            0,
            500,
            (value) {
              setState(() {
                _electricityUsage = value.roundToDouble();
              });
            },
            '${_electricityUsage.toInt()} kWh',
          ),
          
          // Water
          const SizedBox(height: 12),
          _buildSliderCostRow(
            'Tiền nước (ước tính)',
            FormatUtils.formatCurrency(waterCost),
            '@ ${FormatUtils.formatCurrency(_waterRate.toInt())}/m³',
            _waterUsage,
            0,
            20,
            (value) {
              setState(() {
                _waterUsage = value.roundToDouble();
              });
            },
            '${_waterUsage.toInt()} m³',
          ),
          
          // Internet/WiFi
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Internet/Wifi',
                      style: TextStyle(fontSize: 14),
                    ),
                    if (roomDetail.includeWifi)
                      Text(
                        'Đã bao gồm trong giá thuê',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (_wifiCost > 0)
                      Text(
                        '${FormatUtils.formatCurrency(_wifiCost)}/tháng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      )
                    else
                      Text(
                        'Không có sẵn',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                roomDetail.includeWifi 
                    ? 'Miễn phí' 
                    : (_wifiCost > 0 
                      ? FormatUtils.formatCurrency(_wifiCost)
                      : 'Không có'),
                style: TextStyle(
                  fontSize: 14,
                  color: roomDetail.includeWifi ? Colors.green : Colors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 16),
          
          // Total monthly cost
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG HÀNG THÁNG (Dự Kiến):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '~${FormatUtils.formatCurrency(totalMonthlyCost)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _electricityUsage = roomDetail.estimatedMonthlyElectricityUsage.toDouble();
                  _waterUsage = roomDetail.estimatedMonthlyWaterUsage.toDouble();
                });
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Đặt lại giá trị mặc định'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalysisSection(BudgetPlanRoomDetail roomDetail) {
    final room = roomDetail.room;
    
    // Calculate monthly costs
    final rentCost = room.price.toInt();
    final electricityCost = (_electricityUsage * _electricityRate).toInt();
    final waterCost = (_waterUsage * _waterRate).toInt();
    // Wifi cost logic: if wifi is included in rent (includeWifi=true), 
    // then additional cost is 0, otherwise we need to pay wifiCost
    final internetCost = roomDetail.includeWifi ? 0 : _wifiCost;
    
    // Total monthly cost
    final totalMonthlyCost = rentCost + electricityCost + waterCost + 
                            internetCost;
    
    // ---- ADVANCED CALCULATIONS ----
    
    // 1. Affordability Analysis
    double? incomePercentage;
    String affordabilityStatus = "Không có thông tin";
    Color affordabilityColor = Colors.grey;
    String affordabilityAdvice = "";
    
    if (roomDetail.hasUserMonthlySalary && roomDetail.monthlySalary > 0) {
      incomePercentage = totalMonthlyCost / roomDetail.monthlySalary * 100;
      
      if (incomePercentage <= 25) {
        affordabilityStatus = 'Rất hợp lý';
        affordabilityColor = Colors.green.shade700;
        affordabilityAdvice = "Chi phí thuê nhà chiếm tỉ lệ rất hợp lý trong thu nhập của bạn.";
      } else if (incomePercentage <= 30) {
        affordabilityStatus = 'Hợp lý';
        affordabilityColor = Colors.green;
        affordabilityAdvice = "Chi phí thuê nhà nằm trong mức khuyến nghị (dưới 30% thu nhập).";
      } else if (incomePercentage <= 40) {
        affordabilityStatus = 'Cần cân nhắc';
        affordabilityColor = Colors.orange;
        affordabilityAdvice = "Chi phí thuê nhà hơi cao so với thu nhập. Cân nhắc tìm phòng rẻ hơn hoặc tăng thu nhập.";
      } else if (incomePercentage <= 50) {
        affordabilityStatus = 'Khá cao';
        affordabilityColor = Colors.deepOrange;
        affordabilityAdvice = "Chi phí thuê nhà quá cao so với thu nhập. Khuyến nghị tìm phòng phù hợp hơn.";
      } else {
        affordabilityStatus = 'Không khả thi';
        affordabilityColor = Colors.red;
        affordabilityAdvice = "Chi phí thuê nhà chiếm quá nửa thu nhập. Không khuyến khích thuê nơi này về mặt tài chính.";
      }
    }
    
    // 2. Price Value Analysis
    final pricePerSqm = room.price / room.squareMeters;
    
    // 3. Market Position Analysis
    String marketComparison = "Không có dữ liệu so sánh";
    Color marketComparisonColor = Colors.blue;
    String marketAdvice = "";
    
    if (roomDetail.baseLineMedianRentalCost > 0) {
      final priceRatio = rentCost / roomDetail.baseLineMedianRentalCost;
      final percentDiff = ((rentCost - roomDetail.baseLineMedianRentalCost) / roomDetail.baseLineMedianRentalCost * 100).toInt();
      
      if (priceRatio < 0.8) {
        marketComparison = "Thấp hơn ${percentDiff.abs()}% so với mức trung bình khu vực";
        marketComparisonColor = Colors.green.shade700;
        marketAdvice = "Giá thuê rất tốt. Nên xem xét ngay trước khi có người thuê.";
      } else if (priceRatio < 0.95) {
        marketComparison = "Thấp hơn ${percentDiff.abs()}% so với mức trung bình khu vực";
        marketComparisonColor = Colors.green;
        marketAdvice = "Giá thuê hợp lý, thấp hơn mặt bằng chung.";
      } else if (priceRatio <= 1.05) {
        marketComparison = "Tương đương mức trung bình khu vực";
        marketComparisonColor = Colors.blue;
        marketAdvice = "Giá thuê phù hợp với mặt bằng chung của khu vực.";
      } else if (priceRatio <= 1.2) {
        marketComparison = "Cao hơn ${percentDiff}% so với mức trung bình khu vực";
        marketComparisonColor = Colors.orange;
        marketAdvice = "Giá thuê cao hơn mặt bằng chung. Cân nhắc thương lượng giảm giá.";
      } else {
        marketComparison = "Cao hơn ${percentDiff}% so với mức trung bình khu vực";
        marketComparisonColor = Colors.red;
        marketAdvice = "Giá thuê quá cao so với mặt bằng chung. Khuyến nghị thương lượng mạnh hoặc tìm phòng khác.";
      }
    }
    
    // 4. Utility Price Analysis
    String electricityComparison = "Không có dữ liệu so sánh";
    Color electricityColor = Colors.blue;
    String electricityAdvice = "";
    
    if (room.electricPrice > 0 && roomDetail.averageElectricityCost > 0) {
      final electricityRatio = room.electricPrice / roomDetail.averageElectricityCost;
      final electricityDiff = ((room.electricPrice - roomDetail.averageElectricityCost) / roomDetail.averageElectricityCost * 100).toInt();
      
      if (electricityRatio < 0.9) {
        electricityComparison = "Thấp hơn ${electricityDiff.abs()}% (${FormatUtils.formatCurrency(room.electricPrice.toInt())}/kWh)";
        electricityColor = Colors.green;
        electricityAdvice = "Giá điện tốt hơn mức trung bình.";
      } else if (electricityRatio <= 1.1) {
        electricityComparison = "Tương đương mức trung bình (${FormatUtils.formatCurrency(room.electricPrice.toInt())}/kWh)";
        electricityColor = Colors.blue;
        electricityAdvice = "Giá điện phù hợp mức trung bình.";
      } else {
        electricityComparison = "Cao hơn ${electricityDiff}% (${FormatUtils.formatCurrency(room.electricPrice.toInt())}/kWh)";
        electricityColor = Colors.orange;
        electricityAdvice = "Giá điện cao hơn mức trung bình. Cân nhắc tiết kiệm điện.";
      }
    }
    
    String waterComparison = "Không có dữ liệu so sánh";
    Color waterColor = Colors.blue;
    String waterAdvice = "";
    
    if (room.waterPrice > 0 && roomDetail.averageWaterCost > 0) {
      final waterRatio = room.waterPrice / roomDetail.averageWaterCost;
      final waterDiff = ((room.waterPrice - roomDetail.averageWaterCost) / roomDetail.averageWaterCost * 100).toInt();
      
      if (waterRatio < 0.9) {
        waterComparison = "Thấp hơn ${waterDiff.abs()}% (${FormatUtils.formatCurrency(room.waterPrice.toInt())}/m³)";
        waterColor = Colors.green;
        waterAdvice = "Giá nước tốt hơn mức trung bình.";
      } else if (waterRatio <= 1.1) {
        waterComparison = "Tương đương mức trung bình (${FormatUtils.formatCurrency(room.waterPrice.toInt())}/m³)";
        waterColor = Colors.blue;
        waterAdvice = "Giá nước phù hợp mức trung bình.";
      } else {
        waterComparison = "Cao hơn ${waterDiff}% (${FormatUtils.formatCurrency(room.waterPrice.toInt())}/m³)";
        waterColor = Colors.orange;
        waterAdvice = "Giá nước cao hơn mức trung bình. Cân nhắc tiết kiệm nước.";
      }
    }
    
    // 5. Amenity Match Quality
    final tagMatchPercentage = roomDetail.matchedTags.length * 100 / 
        (roomDetail.matchedTags.length + roomDetail.unmatchedTags.length);
    
    String matchQuality;
    Color matchColor;
    
    if (tagMatchPercentage >= 85) {
      matchQuality = "Tuyệt vời";
      matchColor = Colors.green.shade700;
    } else if (tagMatchPercentage >= 70) {
      matchQuality = "Tốt";
      matchColor = Colors.green;
    } else if (tagMatchPercentage >= 50) {
      matchQuality = "Trung bình";
      matchColor = Colors.orange;
    } else {
      matchQuality = "Thấp";
      matchColor = Colors.red;
    }
    
    // Build UI
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.purple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Phân Tích Chi Tiết',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Price per square meter
          _buildAnalysisRow(
            'Giá/m²:',
            '${FormatUtils.formatCurrency(pricePerSqm.toInt())}/m²',
            prefixIcon: Icons.straighten,
            color: Colors.blue,
          ),
          
          // Affordability analysis
          if (roomDetail.hasUserMonthlySalary && incomePercentage != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalysisRow(
                  'Khả năng chi trả:',
                  'Chiếm ~${incomePercentage.toStringAsFixed(1)}% thu nhập. Mức này $affordabilityStatus',
                  prefixIcon: Icons.monetization_on,
                  color: affordabilityColor,
                ),
                if (affordabilityAdvice.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 10, right: 8),
                    child: Text(
                      affordabilityAdvice,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          
          // Market price comparison
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisRow(
                'So sánh giá thuê:',
                marketComparison,
                prefixIcon: Icons.timeline,
                color: marketComparisonColor,
              ),
              if (marketAdvice.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 10, right: 8),
                  child: Text(
                    marketAdvice,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          
          // Electricity price comparison
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisRow(
                'Giá điện:',
                electricityComparison,
                prefixIcon: Icons.flash_on,
                color: electricityColor,
              ),
              if (electricityAdvice.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 10, right: 8),
                  child: Text(
                    electricityAdvice,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          
          // Water price comparison
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisRow(
                'Giá nước:',
                waterComparison,
                prefixIcon: Icons.water_drop,
                color: waterColor,
              ),
              if (waterAdvice.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 10, right: 8),
                  child: Text(
                    waterAdvice,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          
          // Match quality
          _buildAnalysisRow(
            'Độ phù hợp tiện ích:',
            '$matchQuality (${tagMatchPercentage.toStringAsFixed(0)}%)',
            prefixIcon: Icons.check_circle,
            color: matchColor,
          ),
          
          const SizedBox(height: 8),
          const Divider(height: 16),
          
          // Highlights and notes
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Điểm nổi bật & Lưu ý:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Dynamic highlights based on actual data
          if (roomDetail.includeWifi)
            _buildHighlightRow(
              'Điểm nổi bật: ',
              'Tiết kiệm: Wifi miễn phí (~${FormatUtils.formatCurrency(roomDetail.wifiCost)}/tháng)',
              Icons.savings_outlined,
              Colors.green,
            ),
          
          if (room.electricPrice > roomDetail.averageElectricityCost * 1.1)
            _buildHighlightRow(
              'Lưu ý: ',
              'Giá điện cao hơn trung bình',
              Icons.warning_amber_outlined,
              Colors.orange,
            ),
            
          if (incomePercentage != null && incomePercentage > 40)
            _buildHighlightRow(
              'Lưu ý: ',
              'Chi phí thuê chiếm tỉ lệ cao trong thu nhập',
              Icons.account_balance_wallet,
              Colors.orange,
            ),
            
          if (roomDetail.upFrontCost > roomDetail.monthlySalary * 1.5)
            _buildHighlightRow(
              'Lưu ý: ',
              'Chi phí ban đầu cao (${(roomDetail.upFrontCost / roomDetail.monthlySalary).toStringAsFixed(1)} lần thu nhập hàng tháng)',
              Icons.money_off,
              Colors.orange,
            ),
            
          if (tagMatchPercentage < 60)
            _buildHighlightRow(
              'Lưu ý: ',
              'Thiếu nhiều tiện ích bạn mong muốn',
              Icons.not_interested,
              Colors.orange,
            ),
          
          const SizedBox(height: 16),
          const Divider(height: 16),
          
          // Amenity match analysis
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.blue.shade700,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mức độ phù hợp tiện ích:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Enhanced amenities matching section
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Phù hợp',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (roomDetail.matchedTags.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Không có tiện ích phù hợp',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ...roomDetail.matchedTags.map((tag) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tag.displayName ?? tag.name,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade50,
                          Colors.red.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Còn thiếu',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (roomDetail.unmatchedTags.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Không có tiện ích nào thiếu',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ...roomDetail.unmatchedTags.map((tag) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.red,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tag.displayName ?? tag.name,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return BlocBuilder<RoomDetailCubit, RoomDetailState>(
      builder: (context, roomState) {
        // Check if room details are available
        final room = roomState is RoomDetailLoaded ? roomState.room : null;
        final roomId = room?.id;
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: BlocBuilder<DirectChatRoomCubit, DirectChatRoomState>(
                  builder: (context, directChatState) {
                    bool isLoading = directChatState is DirectChatRoomLoadingForRoom;
                    
                    return ElevatedButton(
                      onPressed: (roomId != null && !isLoading)
                        ? () {
                            // Call DirectChatRoomCubit to create a chat room and navigate to chat
                            context.read<DirectChatRoomCubit>().createDirectChatRoom(
                              roomId,
                              context: context,
                            );
                          }
                        : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: Colors.blue.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.message_outlined),
                          const SizedBox(width: 8),
                          Text(
                            isLoading ? 'Đang xử lý...' : 'Liên Hệ Chủ Nhà',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              BlocBuilder<FavoriteCubit, FavoriteState>(
                builder: (context, favoriteState) {
                  bool isFavorite = false;
                  if (favoriteState is FavoriteLoaded) {
                    isFavorite = favoriteState.isFavorite;
                  }
                  
                  return _buildActionButton(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    Colors.red,
                    roomId != null ? () {
                      context.read<FavoriteCubit>().toggleFavorite(roomId);
                    } : null,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: onPressed != null ? color : Colors.grey,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
  
  // Helper widgets
  Widget _buildCostRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
  
  Widget _buildSliderCostRow(
    String label,
    String value,
    String rateInfo,
    double sliderValue,
    double min,
    double max,
    Function(double) onChanged,
    String valueLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  rateInfo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            const Text('Mức sử dụng của bạn?', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: sliderValue,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                label: valueLabel,
                onChanged: onChanged,
              ),
            ),
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                valueLabel,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAnalysisRow(
    String label,
    String value, {
    IconData? prefixIcon,
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: prefixIcon != null 
                ? Icon(
                    prefixIcon,
                    size: 16,
                    color: color,
                  )
                : const SizedBox(width: 16),
          ),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHighlightRow(
      String title,
    String text,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(_LegendItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            item.value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            item.percentage,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Update the tag section to be simpler and expandable
  Widget _buildTagsSection(BudgetPlanRoomDetail roomDetail) {
    final allTags = [...roomDetail.room.tags];
    
    // We'll estimate about 5-6 tags per row depending on tag length
    final int tagsPerRow = 5;
    // Show 2 rows only when collapsed
    final int initialDisplayLimit = tagsPerRow * 2;
    
    // Determine which tags to display (all if expanded, limited if collapsed)
    final displayTags = _isTagsExpanded ? allTags : 
      (allTags.length > initialDisplayLimit 
        ? allTags.sublist(0, initialDisplayLimit) 
        : allTags);
    
    // Calculate remaining tags count
    final remainingCount = allTags.length - displayTags.length;
    
    return GestureDetector(
      onTap: () {
        // Toggle expanded state when tapped
        setState(() {
          _isTagsExpanded = !_isTagsExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiện ích',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isTagsExpanded && remainingCount > 0)
                  Text(
                    '+$remainingCount more',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag.displayName ?? tag.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
} 