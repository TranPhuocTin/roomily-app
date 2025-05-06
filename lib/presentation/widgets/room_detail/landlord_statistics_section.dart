import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/models/landlord_statistics.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/user.dart';

import '../../../data/blocs/landlord/landlord_statistics_cubit.dart';
import '../../../data/blocs/landlord/landlord_statistics_state.dart';
import '../../../data/blocs/user/user_cubit.dart';
import '../../../data/blocs/user/user_state.dart';

class LandlordStatisticsSection extends StatefulWidget {
  final Room room;

  const LandlordStatisticsSection({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  State<LandlordStatisticsSection> createState() => _LandlordStatisticsSectionState();
}

class _LandlordStatisticsSectionState extends State<LandlordStatisticsSection> {
  late LandlordStatisticsCubit _landlordStatisticsCubit;
  late UserCubit _userCubit;

  @override
  void initState() {
    super.initState();
    _landlordStatisticsCubit = GetIt.I<LandlordStatisticsCubit>();
    _userCubit = GetIt.I<UserCubit>();
    _fetchLandlordData();
  }

  void _fetchLandlordData() {
    if (widget.room.landlordId != null) {
      _landlordStatisticsCubit.fetchLandlordStatistics(widget.room.landlordId!);
      _userCubit.getUserInfoById(widget.room.landlordId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _landlordStatisticsCubit),
        BlocProvider.value(value: _userCubit),
      ],
      child: BlocBuilder<UserCubit, UserInfoState>(
        builder: (context, userState) {
          return BlocBuilder<LandlordStatisticsCubit, LandlordStatisticsState>(
            builder: (context, statsState) {
              if (statsState is LandlordStatisticsLoading || userState is UserInfoLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (statsState is LandlordStatisticsLoaded && userState is UserInfoByIdLoaded) {
                return _buildContent(context, statsState.statistics, userState.user);
              } else if (statsState is LandlordStatisticsError || userState is UserInfoError) {
                final errorMessage = (statsState is LandlordStatisticsError)
                    ? statsState.message
                    : (userState is UserInfoError) ? userState.message : 'Unknown error';
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Không thể tải thông tin: $errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, LandlordStatistics statistics, User landlord) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với avatar và thông tin cơ bản
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!),
                  image: landlord.profilePicture != null
                      ? DecorationImage(
                          image: NetworkImage(landlord.profilePicture!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: landlord.profilePicture == null
                    ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          landlord.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (landlord.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.blue[600],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Đánh giá kiểu Shopee
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.orange[500]),
                        const SizedBox(width: 2),
                        Text(
                          landlord.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Container(
                        //   width: 1,
                        //   height: 12,
                        //   color: Colors.grey[300],
                        // ),
                        // const SizedBox(width: 8),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        //   decoration: BoxDecoration(
                        //     color: Colors.orange[50],
                        //     borderRadius: BorderRadius.circular(4),
                        //   ),
                        //   child: Text(
                        //     '${statistics.totalRentedRooms} phòng',
                        //     style: TextStyle(
                        //       fontSize: 12,
                        //       color: Colors.orange[900],
                        //       fontWeight: FontWeight.w500,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Divider mỏng kiểu Shopee
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              height: 1,
              color: Colors.grey[100],
            ),
          ),

          // Stats row kiểu Shopee
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.orange[50]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildShopeeStyleStat(
                      label: 'Tỉ lệ phản hồi',
                      value: '${(statistics.responseRate * 100).toStringAsFixed(0)}%',
                      icon: Icons.speed,
                      color: Colors.green[700]!,
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Colors.orange[100],
                  ),
                  Expanded(
                    child: _buildShopeeStyleStat(
                      label: 'T.gian phản hồi',
                      value: '${statistics.averageResponseTimeInMinutes}p',
                      icon: Icons.timer,
                      color: Colors.blue[700]!,
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Colors.orange[100],
                  ),
                  Expanded(
                    child: _buildShopeeStyleStat(
                      label: 'Đã cho thuê',
                      value: '${statistics.respondedChatRooms}',
                      icon: Icons.home,
                      color: Colors.orange[700]!,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopeeStyleStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}