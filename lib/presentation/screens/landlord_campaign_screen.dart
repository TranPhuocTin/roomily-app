import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/data/models/campaign_model.dart';
import 'package:roomily/data/models/promoted_room_model.dart';
import 'package:roomily/data/blocs/landlord/landlord_rooms_cubit.dart';
import 'package:roomily/data/blocs/landlord/landlord_rooms_state.dart';
import 'package:roomily/data/repositories/ad_repository.dart';
import 'package:roomily/data/blocs/campaigns/campaigns_cubit.dart';
import 'package:roomily/data/blocs/campaigns/campaigns_state.dart';
import 'package:roomily/data/blocs/promoted_rooms/promoted_rooms_state.dart';
import 'package:roomily/presentation/screens/add_campaign_screen.dart';
import 'package:roomily/presentation/screens/campaign_detail_screen.dart';
import 'package:roomily/presentation/screens/edit_campaign_screen.dart';
import 'package:roomily/presentation/widgets/promoted_rooms/promoted_room_list.dart';
import 'dart:async';

import '../../data/blocs/promoted_rooms/promoted_rooms_cubit.dart';

class LandlordCampaignScreen extends StatelessWidget {
  const LandlordCampaignScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CampaignsCubit(adRepository: GetIt.instance<AdRepository>())..fetchCampaigns(),
      child: const _LandlordCampaignView(),
    );
  }
}

class _LandlordCampaignView extends StatefulWidget {
  const _LandlordCampaignView({Key? key}) : super(key: key);

  @override
  State<_LandlordCampaignView> createState() => _LandlordCampaignViewState();
}

class _LandlordCampaignViewState extends State<_LandlordCampaignView> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  // Tạo một GlobalKey thông thường thay vì typed key
  final promotedRoomListKey = GlobalKey();
  
  // Stream controller để thông báo cập nhật dữ liệu
  final StreamController<String> _refreshController = StreamController<String>.broadcast();
  
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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildGradientAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<CampaignsCubit>().fetchCampaigns();
        },
        child: BlocListener<CampaignsCubit, CampaignsState>(
          listener: (context, state) {
            if (state is PauseCampaignSuccess) {
              _showSuccessSnackBar(context, 'Đã tạm dừng chiến dịch thành công');
            } else if (state is PauseCampaignError) {
              _showErrorSnackBar(context, 'Không thể tạm dừng chiến dịch: ${state.message}');
            } else if (state is ResumeCampaignSuccess) {
              _showSuccessSnackBar(context, 'Đã kích hoạt chiến dịch thành công');
            } else if (state is ResumeCampaignError) {
              _showErrorSnackBar(context, 'Không thể kích hoạt chiến dịch: ${state.message}');
            } else if (state is DeleteCampaignSuccess) {
              _showSuccessSnackBar(context, 'Đã xóa chiến dịch thành công');
            } else if (state is DeleteCampaignError) {
              _showErrorSnackBar(context, 'Không thể xóa chiến dịch: ${state.message}');
            } else if (state is UpdateCampaignSuccess) {
              _showSuccessSnackBar(context, 'Đã cập nhật chiến dịch thành công');
            } else if (state is UpdateCampaignError) {
              _showErrorSnackBar(context, 'Không thể cập nhật chiến dịch: ${state.message}');
            }
          },
          child: Column(
        children: [
          _buildTabBar(),
              BlocBuilder<CampaignsCubit, CampaignsState>(
                builder: (context, state) {
                  if (state is CampaignsLoading && state is! CampaignsLoaded) {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (state is CampaignsError) {
                    return Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Đã xảy ra lỗi',
                              style: TextStyle(
                                fontSize: 18,
                                color: textPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<CampaignsCubit>().fetchCampaigns();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // CampaignsLoaded or initial state with empty list
                    final campaigns = state is CampaignsLoaded ? state.campaigns : <CampaignModel>[];
                    return Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                          _buildCampaignList(campaigns),
                          _buildCampaignList(
                            campaigns.where((c) => c.status == "ACTIVE").toList(),
                          ),
                          _buildCampaignList(
                            campaigns.where((c) => c.status == "DRAFT").toList(),
                          ),
                          _buildCampaignList(
                            campaigns.where((c) => c.status == "COMPLETED").toList(),
                          ),
                          _buildCampaignList(
                            campaigns.where((c) => 
                                c.status == "OUT_OF_BUDGET" || 
                                c.status == "DAILY_BUDGET_EXCEEDED").toList(),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AddCampaignScreen()),
          ).then((_) {
            // Refresh campaigns when returning from add screen
            context.read<CampaignsCubit>().fetchCampaigns();
          });
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
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
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  BackButton(color: Colors.white, onPressed: () {
                    Navigator.pop(context, true);
                  },),
                  const SizedBox(width: 8),
                  const Text(
                    'Chiến dịch quảng cáo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // const Spacer(),
                  // Container(
                  //   padding: const EdgeInsets.all(8),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white.withOpacity(0.2),
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: const Icon(
                  //     Icons.filter_list,
                  //     color: Colors.white,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textSecondaryColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: const [
          Tab(text: 'Tất cả'),
          Tab(text: 'Đang chạy'),
          Tab(text: 'Bản nháp'),
          Tab(text: 'Đã hoàn thành'),
          Tab(text: 'Hết ngân sách'),
        ],
      ),
    );
  }

  Widget _buildCampaignList(List<CampaignModel> campaigns) {
    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, secondaryColor],
                ).createShader(bounds);
              },
              child: Icon(
                Icons.campaign_outlined,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có chiến dịch nào',
              style: TextStyle(
                fontSize: 18,
                color: textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const AddCampaignScreen()),
                ).then((_) {
                  context.read<CampaignsCubit>().fetchCampaigns();
                });
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                backgroundColor: primaryColor,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text(
                    'Tạo chiến dịch mới',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final campaign = campaigns[index];
        final statusColor = _getStatusColor(campaign.status);
        final startDate = DateFormat('dd/MM/yyyy').format(campaign.startDate);
        final endDate = DateFormat('dd/MM/yyyy').format(campaign.endDate);
        
        // Chuyển đổi model statistics thành Map để dễ sử dụng
        final stats = campaign.statistics != null 
            ? {...campaign.statistics!.toJson(), 'pricingModel': campaign.pricingModel} 
            : <String, dynamic>{'pricingModel': campaign.pricingModel};
        final progress = campaign.budget > 0 
            ? (campaign.spentAmount / campaign.budget * 100).clamp(0.0, 100.0) 
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCampaignHeader(campaign, statusColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRow(startDate, endDate),
                    const SizedBox(height: 16),
                    _buildBudgetInfo(campaign, progress),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildPerformanceSection(stats, campaign),
                    const SizedBox(height: 16),
                    _buildActionButtons(campaign),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignHeader(CampaignModel campaign, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            campaign.status == "ACTIVE" ? const Color(0xFF0062CC) : 
              campaign.status == "PAUSED" ? const Color(0xFFE67E22) :
              campaign.status == "COMPLETED" ? const Color(0xFF6B7280) : 
              campaign.status == "OUT_OF_BUDGET" ? const Color(0xFFD32F2F) :
              campaign.status == "DAILY_BUDGET_EXCEEDED" ? const Color(0xFFE53935) : 
              const Color(0xFF3498DB),
            campaign.status == "ACTIVE" ? primaryColor : 
              campaign.status == "PAUSED" ? const Color(0xFFF39C12) :
              campaign.status == "COMPLETED" ? const Color(0xFF9CA3AF) : 
              campaign.status == "OUT_OF_BUDGET" ? const Color(0xFFFF5252) :
              campaign.status == "DAILY_BUDGET_EXCEEDED" ? const Color(0xFFFF8A80) : 
              secondaryColor,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    campaign.pricingModel == 'CPC' ? 'Tính phí theo click' : 'Tính phí theo hiển thị',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ), 
          ),
          Row(
            children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                      campaign.status == "ACTIVE" ? Icons.play_arrow : 
                        campaign.status == "PAUSED" ? Icons.pause :
                        campaign.status == "COMPLETED" ? Icons.check_circle_outline : 
                        campaign.status == "OUT_OF_BUDGET" ? Icons.money_off : 
                        campaign.status == "DAILY_BUDGET_EXCEEDED" ? Icons.warning_amber : 
                        Icons.edit_document,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                      _getStatusText(campaign.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showCampaignOptions(campaign),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String startDate, String endDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 16, color: Color(0xFF5E6F88)),
          const SizedBox(width: 8),
          Text(
            '$startDate - $endDate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInfo(CampaignModel campaign, double progress) {
    // Customize display based on pricing model
    final bool isCPC = campaign.pricingModel == 'CPC';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đã chi tiêu',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(campaign.spentAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng ngân sách',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(campaign.budget),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sử dụng ngân sách',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (campaign.dailyBudget > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF7FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, size: 12, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${currencyFormatter.format(campaign.dailyBudget)}/ngày',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: const Color(0xFFE5EFFF),
                      color: _getProgressColor(progress),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getProgressColor(progress).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${progress.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _getProgressColor(progress),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        
        // Hiển thị thông tin bổ sung dựa trên loại chiến dịch
        if (campaign.statistics != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isCPC ? const Color(0xFFE3ECFF) : const Color(0xFFE3FFEC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCPC ? Icons.touch_app_outlined : Icons.visibility_outlined,
                      size: 14,
                      color: isCPC ? primaryColor : const Color(0xFF00C897),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCPC ? 'Chi phí trung bình mỗi lần nhấp' : 'Chi phí trung bình mỗi 1000 lượt hiển thị',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCPC 
                              ? (campaign.statistics?.costPerClick != null 
                                  ? currencyFormatter.format(campaign.statistics!.costPerClick) 
                                  : 'Chưa có dữ liệu')
                              : (campaign.statistics?.costPerMille != null 
                                  ? currencyFormatter.format(campaign.statistics!.costPerMille) 
                                  : 'Chưa có dữ liệu'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCPC ? const Color(0xFFEFF7FF) : const Color(0xFFEBFFF7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCPC ? 'CPC' : 'CPM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCPC ? primaryColor : const Color(0xFF00C897),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFEEF2FA),
    );
  }

  // helper method được thêm vào để xử lý null/NaN safely
  String _formatMetricValue(dynamic value, {bool isPercentage = false}) {
    if (value == null || value == 0 || (value is double && value.isNaN)) {
      return '0${isPercentage ? '%' : ''}';
    }
    
    if (isPercentage) {
      // Format percentage values with 2 decimal places (e.g., 2.63%)
      if (value is double) {
        return '${(value * 100).toStringAsFixed(2)}%';
      } else {
        return '$value%';
      }
    }
    
    return value.toString();
  }

  Widget _buildPerformanceSection(Map<String, dynamic> stats, CampaignModel campaign) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hiệu suất',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textPrimaryColor,
              ),
            ),
            InkWell(
              onTap: () => _showDetailedStatistics(stats),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Chi tiết',
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
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: campaign.pricingModel == 'CPC'
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(
                    value: _formatMetricValue(stats["totalImpressions"] ?? 0),
                    label: 'Hiển thị',
                    icon: Icons.visibility_outlined,
                    color: primaryColor,
                  ),
                  _buildVerticalDivider(),
                  _buildMetricItem(
                    value: _formatMetricValue(stats["totalClicks"] ?? 0),
                    label: 'Nhấp chuột',
                    icon: Icons.touch_app_outlined,
                    color: const Color(0xFF00C897),
                  ),
                  _buildVerticalDivider(),
                  _buildMetricItem(
                    value: _formatMetricValue(stats["clickThroughRate"] ?? 0.0, isPercentage: true),
                    label: 'CTR',
                    icon: Icons.timeline_outlined,
                    color: const Color(0xFFFF9500),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(
                    value: _formatMetricValue(stats["totalImpressions"] ?? 0),
                    label: 'Hiển thị',
                    icon: Icons.visibility_outlined,
                    color: primaryColor,
                  ),
                  _buildVerticalDivider(),
                  _buildMetricItem(
                    value: _formatCurrency(stats["costPerMille"] ?? 0.0),
                    label: 'CPM',
                    icon: Icons.money,
                    color: const Color(0xFF6236FF),
                  ),
                  _buildVerticalDivider(),
                  _buildMetricItem(
                    value: _formatMetricValue(stats["totalConversions"] ?? 0),
                    label: 'Chuyển đổi',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF4CAF50),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  void _showDetailedStatistics(Map<String, dynamic> stats) {
    // Determine the pricing model from the available stats
    final pricingModel = stats["pricingModel"] ?? "CPC"; // Default to CPC if not available
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insights, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Thống kê chi tiết',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              
              // Hiển thị loại chiến dịch
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      pricingModel == 'CPC' ? Icons.touch_app_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pricingModel == 'CPC' 
                            ? 'Chiến dịch tính phí theo click (CPC)'
                            : 'Chiến dịch tính phí theo hiển thị (CPM)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Hiển thị các thống kê cơ bản có trong model
              _buildDetailedStatItem(Icons.touch_app_outlined, 'Tổng lượt nhấp chuột', stats["totalClicks"]?.toString() ?? '0', const Color(0xFF00C897)),
              if (stats["totalImpressions"] != null)
                _buildDetailedStatItem(Icons.visibility_outlined, 'Tổng lượt hiển thị', stats["totalImpressions"]?.toString() ?? '0', primaryColor),
              _buildDetailedStatItem(Icons.check_circle_outline, 'Tổng lượt chuyển đổi', stats["totalConversions"]?.toString() ?? '0', const Color(0xFF4CAF50)),
              
              // Hiển thị chi phí
              _buildDetailedStatItem(Icons.monetization_on, 'Tổng chi tiêu', _formatCurrency(stats["totalSpent"] ?? 0.0), const Color(0xFFFF5722)),
              
              // Hiển thị tỷ lệ
              _buildDetailedStatItem(Icons.speed, 'Tỷ lệ chuyển đổi', _formatMetricValue(stats["conversionRate"] ?? 0.0, isPercentage: true), const Color(0xFF673AB7)),
              if (stats["clickThroughRate"] != null)
                _buildDetailedStatItem(Icons.timeline_outlined, 'Tỷ lệ nhấp chuột (CTR)', _formatMetricValue(stats["clickThroughRate"] ?? 0.0, isPercentage: true), const Color(0xFFFF9500)),
                
              // Thống kê đặc thù cho từng loại chiến dịch
              if (pricingModel == 'CPC')
                _buildDetailedStatItem(Icons.money, 'Chi phí mỗi lần nhấp (CPC)', _formatCurrency(stats["costPerClick"] ?? 0.0), const Color(0xFF6236FF)),
              if (pricingModel == 'CPM' && stats["costPerMille"] != null)
                _buildDetailedStatItem(Icons.bar_chart, 'Chi phí mỗi ngàn lượt hiển thị (CPM)', _formatCurrency(stats["costPerMille"] ?? 0.0), const Color(0xFF00D1FF)),
              
              // Thông tin phụ
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dữ liệu được cập nhật hàng ngày. Một số chỉ số có thể có độ trễ tối đa 24 giờ.',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDetailedStatItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value == 0 || value.isNaN) return '0đ';
    return currencyFormatter.format(value);
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: const Color(0xFFDFE6F0),
    );
  }

  Widget _buildMetricItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CampaignModel campaign) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          label: 'Phòng QC',
          icon: Icons.home_outlined,
          backgroundColor: const Color(0xFFF5F8FF),
          iconColor: primaryColor,
          textColor: textPrimaryColor,
          onTap: () {
            _showPromotedRoomsDialog(campaign);
          },
        ),
        if (campaign.status != "COMPLETED")
          BlocBuilder<CampaignsCubit, CampaignsState>(
            builder: (context, state) {
              // Kiểm tra nếu đang pause campaign này
              final bool isPausing = state is PausingCampaign && 
                  state.campaignId == campaign.id;
                  
              // Kiểm tra nếu đang kích hoạt (resume) campaign này
              final bool isResuming = state is ResumingCampaign && 
                  state.campaignId == campaign.id;

              // Tên nút và icon dựa trên trạng thái
              String buttonLabel;
              IconData buttonIcon;
              Color bgColor;
              Color iconColor;

              if (campaign.status == "ACTIVE") {
                buttonLabel = 'Tạm dừng';
                buttonIcon = Icons.pause;
                bgColor = const Color(0xFFFFF0E4);
                iconColor = const Color(0xFFFF9500);
              } else if (campaign.status == "OUT_OF_BUDGET") {
                buttonLabel = 'Nạp thêm';
                buttonIcon = Icons.account_balance_wallet;
                bgColor = const Color(0xFFFFE0E0);
                iconColor = const Color(0xFFD32F2F);
              } else if (campaign.status == "DAILY_BUDGET_EXCEEDED") {
                buttonLabel = 'Kích hoạt';
                buttonIcon = Icons.play_arrow;
                bgColor = const Color(0xFFFFECB3);
                iconColor = const Color(0xFFFFA000);
              } else {
                buttonLabel = 'Kích hoạt';
                buttonIcon = Icons.play_arrow;
                bgColor = const Color(0xFFEBFFF7);
                iconColor = const Color(0xFF00C897);
              }
                  
              return _buildActionButton(
                label: buttonLabel,
                icon: buttonIcon,
                backgroundColor: bgColor,
                iconColor: iconColor,
                textColor: textPrimaryColor,
                isLoading: isPausing || isResuming, // Hiển thị loading indicator khi đang xử lý
                onTap: () {
                  if (campaign.status == "ACTIVE") {
                    // Tạm dừng chiến dịch
                    context.read<CampaignsCubit>().pauseCampaign(campaign.id);
                  } else if (campaign.status == "OUT_OF_BUDGET") {
                    // Tính năng nạp thêm ngân sách
                    _showSnackBar(context, 'Tính năng nạp thêm ngân sách đang được phát triển');
                  } else if (campaign.status == "PAUSED" || campaign.status == "DAILY_BUDGET_EXCEEDED") {
                    // Kích hoạt lại chiến dịch
                    context.read<CampaignsCubit>().resumeCampaign(campaign.id);
                  } else {
                    // Các trạng thái khác (như DRAFT)
                    _showSnackBar(context, 'Tính năng đang được phát triển');
                  }
                },
            );
          },
        ),
        if (campaign.status == "COMPLETED" || 
            campaign.status == "OUT_OF_BUDGET" || 
            campaign.status == "DAILY_BUDGET_EXCEEDED")
        _buildActionButton(
            label: 'Báo cáo',
            icon: Icons.assessment_outlined,
            backgroundColor: const Color(0xFFECF4FF),
            iconColor: primaryColor,
          textColor: textPrimaryColor,
          onTap: () {
              _showSnackBar(context, 'Tính năng báo cáo đang được phát triển');
          },
        ),
        _buildActionButton(
          label: (campaign.status == "COMPLETED" || 
                 campaign.status == "OUT_OF_BUDGET" || 
                 campaign.status == "DAILY_BUDGET_EXCEEDED") 
                ? 'Xem lại' : 'Chỉnh sửa',
          icon: (campaign.status == "COMPLETED" || 
                campaign.status == "OUT_OF_BUDGET" || 
                campaign.status == "DAILY_BUDGET_EXCEEDED") 
               ? Icons.visibility_outlined : Icons.edit_outlined,
          backgroundColor: primaryColor,
          iconColor: Colors.white,
          textColor: Colors.white,
          onTap: () {
            if (campaign.status == "COMPLETED" || 
                campaign.status == "OUT_OF_BUDGET" || 
                campaign.status == "DAILY_BUDGET_EXCEEDED") {
              // Xem lại chiến dịch
              _showSnackBar(context, 'Tính năng đang được phát triển');
            } else {
              // Chỉnh sửa chiến dịch
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditCampaignScreen(campaign: campaign),
                ),
              ).then((result) {
                // Chỉ refresh campaigns khi đã cập nhật thành công
                if (result == true) {
                  context.read<CampaignsCubit>().fetchCampaigns();
                }
              });
            }
          },
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: iconColor,
                  strokeWidth: 2,
                ),
              )
            else
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF00C897);
      case 'PAUSED':
        return const Color(0xFFFF9500);
      case 'DRAFT':
        return primaryColor;
      case 'COMPLETED':
        return const Color(0xFF9CA3AF);
      case 'OUT_OF_BUDGET':
        return const Color(0xFFD32F2F);
      case 'DAILY_BUDGET_EXCEEDED':
        return const Color(0xFFFFA000);
      default:
        return textSecondaryColor;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Đang chạy';
      case 'PAUSED':
        return 'Tạm dừng';
      case 'DRAFT':
        return 'Bản nháp';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'OUT_OF_BUDGET':
        return 'Hết ngân sách';
      case 'DAILY_BUDGET_EXCEEDED':
        return 'Vượt ngân sách hàng ngày';
      default:
        return 'Không xác định';
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 30) {
      return const Color(0xFF00C897);
    } else if (progress < 70) {
      return const Color(0xFFFF9500);
    } else {
      return const Color(0xFFFF456C);
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    final Color accentGreen = const Color(0xFF00C897);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: accentGreen, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: accentGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    const Color errorColor = Color(0xFFFF456C);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: errorColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  void _showCampaignOptions(CampaignModel campaign) {
    // Lấy CampaignsCubit từ context gốc
    final campaignsCubit = context.read<CampaignsCubit>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => BlocProvider.value(
        value: campaignsCubit, // Truyền lại cubit vào BottomSheet
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'Tùy chọn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildOptionItem(
                icon: Icons.info_outline,
                title: 'Xem chi tiết',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showPromotedRoomsDialog(campaign);
                },
              ),
              if (campaign.status == "DRAFT" || campaign.status == "PAUSED")
                _buildOptionItem(
                  icon: Icons.edit_outlined,
                  title: 'Chỉnh sửa',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditCampaignScreen(campaign: campaign),
                      ),
                    ).then((result) {
                      // Chỉ refresh campaigns khi đã cập nhật thành công
                      if (result == true) {
                        context.read<CampaignsCubit>().fetchCampaigns();
                      }
                    });
                  },
                ),
              if (campaign.status == "ACTIVE")
                _buildOptionItem(
                  icon: Icons.pause,
                  title: 'Tạm dừng',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    campaignsCubit.pauseCampaign(campaign.id);
                  },
                ),
              if (campaign.status == "PAUSED" || 
                  campaign.status == "OUT_OF_BUDGET" || 
                  campaign.status == "DAILY_BUDGET_EXCEEDED")
                _buildOptionItem(
                  icon: Icons.play_arrow,
                  title: 'Kích hoạt',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    campaignsCubit.resumeCampaign(campaign.id);
                  },
                ),
              if (campaign.status == "OUT_OF_BUDGET")
                _buildOptionItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Nạp thêm ngân sách',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showSnackBar(context, 'Tính năng đang được phát triển');
                  },
                ),
              if (campaign.status == "COMPLETED" || 
                  campaign.status == "OUT_OF_BUDGET" || 
                  campaign.status == "DAILY_BUDGET_EXCEEDED")
                _buildOptionItem(
                  icon: Icons.assessment_outlined,
                  title: 'Xem báo cáo',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showSnackBar(context, 'Tính năng đang được phát triển');
                  },
                ),
              _buildOptionItem(
                icon: Icons.delete_outline,
                title: 'Xóa chiến dịch',
                color: const Color(0xFFFF456C),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showDeleteConfirmation(campaign);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? textPrimaryColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: color ?? textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(CampaignModel campaign) {
    final textTheme = Theme.of(context).textTheme;
    // Lấy CampaignsCubit từ context gốc
    final campaignsCubit = context.read<CampaignsCubit>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: campaignsCubit, // Truyền lại cubit vào AlertDialog
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Xác nhận xóa',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn xóa chiến dịch "${campaign.name}"?',
                style: textTheme.bodyLarge?.copyWith(
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hành động này không thể hoàn tác.',
                style: textTheme.bodyMedium?.copyWith(
                  color: textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: textSecondaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Hủy bỏ'),
            ),
            BlocBuilder<CampaignsCubit, CampaignsState>(
              builder: (context, state) {
                final isDeleting = state is DeletingCampaign && state.campaignId == campaign.id;
                
                return TextButton(
                  onPressed: isDeleting ? null : () {
                    Navigator.pop(dialogContext);
                    context.read<CampaignsCubit>().deleteCampaign(campaign.id);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFFF456C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Xóa chiến dịch'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotedRoomsDialog(CampaignModel campaign) {
    // Lấy instance PromotedRoomsCubit từ GetIt thay vì tạo mới
    final promotedRoomsCubit = GetIt.instance<PromotedRoomsCubit>();
    
    // Fetch dữ liệu cho campaign hiện tại
    promotedRoomsCubit.fetchPromotedRooms(campaign.id);
    
    // Mở dialog mà không duy trì reference đến cubit
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: promotedRoomsCubit,
          child: Builder(
            builder: (innerContext) {
              // Sử dụng StreamBuilder để lắng nghe các sự kiện cập nhật
              return StreamBuilder<String>(
                stream: _refreshController.stream,
                builder: (context, snapshot) {
                  // Nếu snapshot có data và data là campaignId hiện tại, thì reload dữ liệu
                  if (snapshot.hasData && snapshot.data == campaign.id) {
                    // Delay một chút để tránh quá nhiều lần gọi API liên tiếp
                    Future.microtask(() {
                      promotedRoomsCubit.fetchPromotedRooms(campaign.id);
                    });
                  }
                  
                  return DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (_, controller) {
                      return Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header đẹp với gradient màu
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [primaryColor, secondaryColor],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                              child: Column(
                                children: [
                                  // Drag handle
                                  Center(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Phòng trong "${campaign.name}"',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Thêm nút refresh thủ công để cập nhật dữ liệu
                                      IconButton(
                                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                                        onPressed: () {
                                          promotedRoomsCubit.fetchPromotedRooms(campaign.id);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () => Navigator.pop(innerContext),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Thêm phòng button
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Danh sách phòng QC',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimaryColor,
                                      overflow: TextOverflow.ellipsis
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showAddRoomDialog(campaign.id, campaign.pricingModel);
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Thêm phòng'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: primaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Thông tin hữu ích
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F8FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: primaryColor),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Phòng bạn quảng cáo sẽ được hiển thị ưu tiên trong kết quả tìm kiếm, tăng khả năng tiếp cận với người thuê tiềm năng.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Danh sách phòng quảng cáo - sử dụng PromotedRoomList
                            Expanded(
                              child: PromotedRoomList(
                                campaignId: campaign.id,
                                pricingModel: campaign.pricingModel,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
  
  void _showAddRoomDialog(String campaignId, String pricingModel, [BuildContext? parentContext]) {
    // Get the current user's landlord ID from AuthService
    final authService = GetIt.instance<AuthService>();
    final String landlordId = authService.userId ?? "";
    
    // Create a TextEditingController for the bid input
    final bidController = TextEditingController(text: "1000");
    // Currently selected room ID
    String? selectedRoomId;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // Get PromotedRoomsCubit to fetch current promoted rooms
    final promotedRoomsCubit = GetIt.instance<PromotedRoomsCubit>();
    
    // Show loading dialog while fetching rooms
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Fetch the current promoted rooms first
    promotedRoomsCubit.fetchPromotedRooms(campaignId).then((_) {
      // Get the list of already promoted roomIds
      final promotedRoomsState = promotedRoomsCubit.state;
      final List<String> promotedRoomIds = [];
      
      if (promotedRoomsState is PromotedRoomsLoaded) {
        for (var room in promotedRoomsState.promotedRooms) {
          promotedRoomIds.add(room.roomId);
        }
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Now show the room selection dialog
      showDialog(
        context: context,
        builder: (dialogContext) => BlocProvider(
          create: (_) => GetIt.instance<LandlordRoomsCubit>()..getLandlordRooms(landlordId),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: StatefulBuilder(
              builder: (statefulContext, setState) {
                return Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 600, minHeight: 300),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [primaryColor, secondaryColor],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.home_work_outlined, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Chọn phòng để quảng cáo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Hiển thị thông tin loại chiến dịch
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBFFF7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              pricingModel == 'CPC' 
                                  ? Icons.monetization_on_outlined 
                                  : Icons.campaign_outlined,
                              size: 16, 
                              color: const Color(0xFF00C897)
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pricingModel == 'CPC'
                                    ? 'Chiến dịch tính phí theo click (CPC)'
                                    : 'Chiến dịch tính phí theo hiển thị (CPM)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF00C897),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Giá thầu input - chỉ hiển thị nếu là CPC
                      if (pricingModel == 'CPC')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BID (VND)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: bidController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Ví dụ: 1000 VNĐ',
                                prefixIcon: Icon(Icons.monetization_on_outlined, color: textSecondaryColor),
                                suffixText: 'VND',
                                suffixStyle: TextStyle(
                                  color: textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F8FF),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: const Color(0xFFEFF3FA), width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      
                      // Room list
                      Expanded(
                        child: BlocBuilder<LandlordRoomsCubit, LandlordRoomsState>(
                          builder: (context, state) {
                            if (state is LandlordRoomsLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (state is LandlordRoomsError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Không thể tải danh sách phòng',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        context.read<LandlordRoomsCubit>().getLandlordRooms(landlordId);
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (state is LandlordRoomsLoaded) {
                              var rooms = state.rooms;
                              
                              // Filter out rooms that are already promoted
                              rooms = rooms.where((room) => !promotedRoomIds.contains(room.id)).toList();
                              
                              if (rooms.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.home_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Tất cả phòng đã được thêm vào chiến dịch',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              return ListView.builder(
                                itemCount: rooms.length,
                                itemBuilder: (context, index) {
                                  final room = rooms[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: selectedRoomId == room.id ? primaryColor : Colors.transparent,
                                        width: selectedRoomId == room.id ? 2 : 0,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          // Toggle selection
                                          if (selectedRoomId == room.id) {
                                            selectedRoomId = null;
                                          } else {
                                            selectedRoomId = room.id;
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Room image or placeholder
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.home_outlined, color: Colors.grey[400]),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    room.title,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: textPrimaryColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    room.address,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondaryColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    currencyFormatter.format(room.price),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: primaryColor,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: selectedRoomId == room.id ? primaryColor : const Color(0xFFEFF3FA),
                                                border: Border.all(
                                                  color: selectedRoomId == room.id ? Colors.transparent : const Color(0xFFDFE6F0),
                                                ),
                                              ),
                                              child: selectedRoomId == room.id
                                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            
                            return const SizedBox();
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Submit button
                      Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedRoomId != null) {
                              // Lấy bid value nếu là CPC
                              double? bid;
                              if (pricingModel == 'CPC') {
                                try {
                                  bid = double.parse(bidController.text);
                                } catch (e) {
                                  _showErrorSnackBar(context, 'BID không hợp lệ');
                                  return;
                                }
                              }
                              else {
                                bid = 0;
                              }
                              
                              // Đóng dialog thêm phòng
                              Navigator.pop(dialogContext);
                              
                              // Gọi thêm phòng và cập nhật dữ liệu
                              _addPromotedRoom(campaignId, selectedRoomId!, pricingModel, bid, parentContext);
                            } else {
                              _showErrorSnackBar(context, 'Vui lòng chọn một phòng');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Thêm phòng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }
  
  void _addPromotedRoom(String campaignId, String roomId, String pricingModel, double? bid, [BuildContext? parentContext]) {
    // Lấy PromotedRoomsCubit từ GetIt thay vì tạo instance mới
    final promotedRoomsCubit = GetIt.instance<PromotedRoomsCubit>();
    
    // Show loading indicator with margin to avoid bottom nav bar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Đang thêm phòng...'),
          ],
        ),
        duration: const Duration(seconds: 60),
        behavior: SnackBarBehavior.fixed,
      ),
    );
    
    // Add the promoted room using provided cubit - bid sẽ là null nếu là CPM
    promotedRoomsCubit.addPromotedRoom(campaignId, roomId, bid).then((_) {
      // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFF00C897), size: 16),
              ),
              const SizedBox(width: 12),
              const Text('Đã thêm phòng thành công'),
            ],
          ),
          backgroundColor: const Color(0xFF00C897),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
      
      // Trigger refresh by adding to stream controller
      _refreshController.add(campaignId);
      
    }).catchError((error) {
      // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: Color(0xFFFF456C), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Không thể thêm phòng: ${error.toString()}')),
            ],
          ),
          backgroundColor: const Color(0xFFFF456C),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    });
  }
} 