import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/presentation/widgets/common/shimmer_loading.dart';
import 'package:roomily/core/extensions/room_type_extension.dart';
import 'package:roomily/core/utils/format_utils.dart';

import '../../../data/blocs/home/room_detail_cubit.dart';
import '../../../data/blocs/home/room_detail_state.dart';

class PropertyDetailsSection extends StatelessWidget {
  const PropertyDetailsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomDetailCubit, RoomDetailState>(
      builder: (context, state) {
        if (state is RoomDetailLoading) {
          return _buildShimmerLoading();
        }

        if (state is RoomDetailError) {
          return Center(child: Text(state.message));
        }

        if (state is RoomDetailLoaded) {
          final room = state.room;
          final details = [
            PropertyDetailItem(
              icon: Icons.apartment,
              label: 'Loại hình',
              value: room.type.toDisplayText,
              color: Colors.blue,
            ),
            PropertyDetailItem(
              icon: Icons.square_foot,
              label: 'Diện tích',
              value: '${room.squareMeters} m²',
              color: Colors.green,
            ),
            PropertyDetailItem(
              icon: Icons.people,
              label: 'Số người tối đa',
              value: '${room.maxPeople} người',
              color: Colors.orange,
            ),
            PropertyDetailItem(
              icon: Icons.electric_bolt,
              label: 'Giá điện',
              value: '${FormatUtils.formatCurrency(room.electricPrice)}/số',
              color: Colors.purple,
            ),
            PropertyDetailItem(
              icon: Icons.water_drop,
              label: 'Giá nước',
              value: '${FormatUtils.formatCurrency(room.waterPrice)}/m³',
              color: Colors.blue,
            ),
            if (room.deposit != null)
              PropertyDetailItem(
                icon: Icons.account_balance_wallet,
                label: 'Tiền cọc',
                value: FormatUtils.formatCurrency(room.deposit!),
                color: Colors.red,
              ),
          ];

          return Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: Text(
                    'Đặc điểm bất động sản',
                    style: AppTextStyles.heading5.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...details.map((detail) => _buildDetailRow(detail)),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildDetailRow(PropertyDetailItem detail) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            detail.icon,
            color: detail.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    detail.label,
                    style: AppTextStyles.bodyMediumRegular.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    detail.value,
                    style: AppTextStyles.bodyMediumMedium.copyWith(
                      color: Colors.black,
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

  Widget _buildShimmerLoading() {
    return Container(
      color: Colors.white,
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const ShimmerContainer(
              width: 200,
              height: 24,
            ),
            const SizedBox(height: 16),
            // Property details
            ...List.generate(6, (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const ShimmerContainer(
                    width: 20,
                    height: 20,
                    borderRadius: 4,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: ShimmerContainer(
                            width: double.infinity,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          flex: 2,
                          child: ShimmerContainer(
                            width: double.infinity,
                            height: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class PropertyDetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const PropertyDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

// Example Usage remains the same as in the previous version