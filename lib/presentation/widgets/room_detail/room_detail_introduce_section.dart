import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/core/extensions/room_type_extension.dart';
import 'package:roomily/core/utils/tag_category.dart';
import 'package:roomily/presentation/widgets/common/shimmer_loading.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'dart:ui';

import '../../../data/blocs/home/room_detail_cubit.dart';
import '../../../data/blocs/home/room_detail_state.dart';
import '../../../data/models/room.dart';

class RoomDetailIntroduceSection extends StatelessWidget {
  const RoomDetailIntroduceSection({super.key});

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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  style: AppTextStyles.heading4.copyWith(
                    fontSize: 20,
                    color: const Color(0xFF212E88),
                  ),
                  softWrap: true,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE0E5FB), Color(0xFF0BDDDD)],
                        ),
                      ),
                      child: Text(
                        room.type.toDisplayText,
                        style: AppTextStyles.bodyMediumSemiBold.copyWith(
                          color: const Color(0xFF005A81),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10,),
                    // Row(
                    //   children: [
                    //     const Icon(Icons.star, color: Colors.yellow, size: 20),
                    //     Text(
                    //       '4.5',
                    //       style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    //         color: const Color(0xFF005A81),
                    //         fontSize: 15,
                    //       ),
                    //     ),
                    //     Text(
                    //       ' (100 đánh giá)',
                    //       style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    //         color: Colors.grey,
                    //         fontSize: 15,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                if (room.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _RoomTagsSection(tags: room.tags),
                ],
                const SizedBox(height: 10),
                Text(
                  '${FormatUtils.formatCurrency(room.price)}/tháng',
                  style: AppTextStyles.heading5.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mô tả',
                  style: AppTextStyles.heading5.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _ExpandableDescription(description: room.description),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    Expanded(
                      child: Text(
                        '  ${room.address}, ${room.ward}, ${room.district}, ${room.city}',
                        style: AppTextStyles.bodyMediumMedium.copyWith(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.update, color: Colors.grey),
                    Expanded(
                      child: Text(
                        '  Đăng ngày: ${DateFormat('dd/MM/yyyy').format(room.createdAt)}',
                        style: AppTextStyles.bodyMediumMedium.copyWith(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        
        return const SizedBox();
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const ShimmerContainer(
              width: double.infinity,
              height: 24,
            ),
            const SizedBox(height: 10),
            // Type and Rating
            Row(
              children: [
                const ShimmerContainer(
                  width: 80,
                  height: 24,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.grey, size: 20),
                    const SizedBox(width: 4),
                    const ShimmerContainer(
                      width: 100,
                      height: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tags
            Row(
              children: List.generate(3, (index) => 
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ShimmerContainer(
                    width: 80,
                    height: 24,
                    borderRadius: 5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Price
            const ShimmerContainer(
              width: 150,
              height: 24,
            ),
            const SizedBox(height: 10),
            // Description title
            const ShimmerContainer(
              width: 100,
              height: 24,
            ),
            const SizedBox(height: 8),
            // Description content
            Column(
              children: List.generate(3, (index) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ShimmerContainer(
                  width: double.infinity,
                  height: 16,
                ),
              )),
            ),
            const SizedBox(height: 16),
            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 8),
                const Expanded(
                  child: ShimmerContainer(
                    width: double.infinity,
                    height: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.update, color: Colors.grey),
                const SizedBox(width: 8),
                const ShimmerContainer(
                  width: 150,
                  height: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomTagsSection extends StatefulWidget {
  final List<RoomTag> tags;
  final int initialTagsToShow;

  const _RoomTagsSection({
    required this.tags,
    this.initialTagsToShow = 5,
  });

  @override
  State<_RoomTagsSection> createState() => _RoomTagsSectionState();
}

class _RoomTagsSectionState extends State<_RoomTagsSection> {
  bool _expanded = false;
  // Maximum number of tags to show in a row
  final int _maxTagsInRow = 3;

  List<RoomTag> get filteredTags => widget.tags
      .where((tag) => tag.category != TagCategory.NEARBY_POI)
      .toList();

  @override
  Widget build(BuildContext context) {
    if (filteredTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMoreTags = filteredTags.length > _maxTagsInRow;
    final remainingCount = filteredTags.length - _maxTagsInRow;

    // If expanded, show all tags in a Wrap layout
    if (_expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...filteredTags.map((tag) => _buildTagItem(tag)),
              // Add collapse button at the end
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expanded = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFE0E5FB),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.remove_circle_outline,
                        size: 16,
                        color: const Color(0xFF005A81),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Thu gọn",
                        style: AppTextStyles.bodyMediumSemiBold.copyWith(
                          color: const Color(0xFF005A81),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    // If collapsed, show only first few tags in a single row
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...filteredTags.take(_maxTagsInRow).map((tag) => _buildTagItem(tag)),
          // Show "+X more" badge if there are more tags
          if (hasMoreTags)
            GestureDetector(
              onTap: () {
                setState(() {
                  _expanded = true;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFE0E5FB),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: const Color(0xFF005A81),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "+$remainingCount",
                      style: AppTextStyles.bodyMediumSemiBold.copyWith(
                        color: const Color(0xFF005A81),
                        fontSize: 12,
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

  Widget _buildTagItem(RoomTag tag) {
    final IconData tagIcon = _getIconForTag(tag);
    
    return Container(
      margin: _expanded ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFE0E5FB),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tagIcon,
            size: 16,
            color: const Color(0xFF005A81),
          ),
          const SizedBox(width: 4),
          Text(
            tag.displayName ?? tag.name,
            style: AppTextStyles.bodyMediumSemiBold.copyWith(
              color: const Color(0xFF005A81),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTagsGrid(List<RoomTag> tags) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final IconData tagIcon = _getIconForTag(tag);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFE0E5FB),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tagIcon,
                size: 16,
                color: const Color(0xFF005A81),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tag.displayName ?? tag.name,
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    color: const Color(0xFF005A81),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  IconData _getIconForTag(RoomTag tag) {
    // Map tag categories to appropriate icons
    switch (tag.category) {
      case TagCategory.IN_ROOM_FEATURE:
        if (tag.name.contains('WIFI')) return Icons.wifi;
        if (tag.name.contains('AIR_CONDITIONER')) return Icons.ac_unit;
        if (tag.name.contains('KITCHEN')) return Icons.kitchen;
        if (tag.name.contains('PRIVATE_BATHROOM')) return Icons.bathroom;
        if (tag.name.contains('TV')) return Icons.tv;
        if (tag.name.contains('WASHING_MACHINE')) return Icons.local_laundry_service;
        if (tag.name.contains('FRIDGE')) return Icons.kitchen;
        return Icons.check_circle_outline;
      
      case TagCategory.BUILDING_FEATURE:
        if (tag.name.contains('PARKING')) return Icons.local_parking;
        if (tag.name.contains('SECURITY')) return Icons.security;
        if (tag.name.contains('ELEVATOR')) return Icons.elevator;
        return Icons.apartment;
        
      case TagCategory.POLICY:
        if (tag.name.contains('PET')) return Icons.pets;
        if (tag.name.contains('SMOKE')) return Icons.smoke_free;
        if (tag.name.contains('FEMALE')) return Icons.female;
        if (tag.name.contains('MALE')) return Icons.male;
        return Icons.policy;
        
      default:
        return Icons.check_circle_outline;
    }
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String description;

  const _ExpandableDescription({
    required this.description,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Check if description is likely to exceed 3 lines (rough estimation based on character count)
    final bool isLongText = widget.description.length > 150;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          style: AppTextStyles.bodyMediumRegular.copyWith(
            color: Colors.black54,
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (isLongText)
          TextButton(
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded ? 'Thu gọn' : 'Xem thêm',
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    color: const Color(0xFF212E88),
                    fontSize: 14,
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: const Color(0xFF212E88),
                ),
              ],
            ),
          ),
      ],
    );
  }
}