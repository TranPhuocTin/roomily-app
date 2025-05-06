import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import color scheme
import 'package:roomily/presentation/screens/add_room_screen_v2.dart';

import '../../../data/blocs/tag/tag_cubit.dart';
import '../../../data/blocs/tag/tag_state.dart';
import '../../../core/utils/tag_category.dart';
import '../../../data/models/room.dart';
import '../../../data/models/recommended_tag.dart';

class AmenitiesStep extends StatefulWidget {
  final List<String> selectedTagIds;
  final Function(bool, String) onTagToggle;

  // UI Constants
  static const Color primaryColor = RoomColorScheme.amenities;
  static const Color textColor = RoomColorScheme.text;
  static const Color surfaceColor = RoomColorScheme.surface;
  static const Color errorColor = RoomColorScheme.error;
  static const Color recommendedColor = RoomColorScheme.amenities;

  const AmenitiesStep({
    Key? key,
    required this.selectedTagIds,
    required this.onTagToggle,
  }) : super(key: key);

  @override
  State<AmenitiesStep> createState() => _AmenitiesStepState();
}

class _AmenitiesStepState extends State<AmenitiesStep> {
  bool _hasAutoSelectedRecommendedTags = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmenitiesInfo(),
          
          const SizedBox(height: 24),
          
          BlocBuilder<TagCubit, TagState>(
            builder: (context, state) {
              if (state.status == TagStatus.loading) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AmenitiesStep.primaryColor,
                    ),
                  ),
                );
              } else if (state.status == TagStatus.loaded) {
                if (state.tags.isEmpty) {
                  return _buildEmptyTags();
                }
                
                // Schedule auto-selection for after the frame is built
                if (!_hasAutoSelectedRecommendedTags && state.recommendedTags.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _autoSelectRecommendedTags(state.tags, state.recommendedTags);
                  });
                }
                
                // Organize tags by category
                final Map<TagCategory, List<RoomTag>> tagsByCategory = {
                  for (var category in TagCategory.values) 
                    category: state.tags.where((tag) => tag.category == category).toList()
                };
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nearby points of interest - đưa lên đầu tiên
                    if (tagsByCategory[TagCategory.NEARBY_POI]!.isNotEmpty)
                      _buildTagExpansionPanel(
                        title: 'Tiện ích xung quanh',
                        icon: Icons.location_on,
                        tags: tagsByCategory[TagCategory.NEARBY_POI]!,
                        recommendedTags: state.recommendedTags,
                        initiallyExpanded: true,
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Room features section
                    if (tagsByCategory[TagCategory.IN_ROOM_FEATURE]!.isNotEmpty)
                      _buildTagExpansionPanel(
                        title: 'Tiện ích trong phòng',
                        icon: Icons.hotel,
                        tags: tagsByCategory[TagCategory.IN_ROOM_FEATURE]!,
                        recommendedTags: state.recommendedTags,
                        initiallyExpanded: false,
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Building features section
                    if (tagsByCategory[TagCategory.BUILDING_FEATURE]!.isNotEmpty)
                      _buildTagExpansionPanel(
                        title: 'Tiện ích tòa nhà',
                        icon: Icons.apartment,
                        tags: tagsByCategory[TagCategory.BUILDING_FEATURE]!,
                        recommendedTags: state.recommendedTags,
                        initiallyExpanded: false,
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Policies
                    if (tagsByCategory[TagCategory.POLICY]!.isNotEmpty)
                      _buildTagExpansionPanel(
                        title: 'Chính sách',
                        icon: Icons.gavel,
                        tags: tagsByCategory[TagCategory.POLICY]!,
                        recommendedTags: state.recommendedTags,
                        initiallyExpanded: false,
                      ),
                  ],
                );
              } else if (state.status == TagStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AmenitiesStep.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể tải danh sách tiện ích: ${state.errorMessage}',
                        style: TextStyle(color: AmenitiesStep.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<TagCubit>().getAllTags();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AmenitiesStep.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              // Default case - no tags available
              return _buildEmptyTags();
            },
          ),

          const SizedBox(height: 24),
          if (widget.selectedTagIds.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AmenitiesStep.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AmenitiesStep.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đã chọn ${widget.selectedTagIds.length} tiện ích',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AmenitiesStep.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _autoSelectRecommendedTags(List<RoomTag> allTags, List<RecommendedTag> recommendedTags) {
    // For each recommended tag, find the corresponding tag and select it if not already selected
    for (var recTag in recommendedTags) {
      final matchingTag = allTags.firstWhere(
        (tag) => tag.name == recTag.tagName,
        orElse: () => RoomTag(id: '', name: '', category: TagCategory.IN_ROOM_FEATURE),
      );
      
      if (matchingTag.id.isNotEmpty && !widget.selectedTagIds.contains(matchingTag.id)) {
        // Select the tag
        widget.onTagToggle(true, matchingTag.id);
      }
    }
    
    // Mark as processed so we don't auto-select again
    setState(() {
      _hasAutoSelectedRecommendedTags = true;
    });
  }

  Widget _buildAmenitiesInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AmenitiesStep.primaryColor.withOpacity(0.7),
            AmenitiesStep.primaryColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AmenitiesStep.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tips_and_updates,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Chọn tiện ích cho phòng của bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhà có nhiều tiện ích sẽ thu hút người thuê hơn. Các tiện ích được đề xuất đã được tự động chọn, bạn có thể bỏ chọn nếu không có.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyTags() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không có tiện ích nào',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build expansion panel for tag categories
  Widget _buildTagExpansionPanel({
    required String title,
    required IconData icon,
    required List<RoomTag> tags,
    required List<RecommendedTag> recommendedTags,
    bool initiallyExpanded = false,
  }) {
    // Tạo map giữa tagName và distance để dễ dàng truy cập
    final Map<String, double> distanceMap = {};
    for (var recTag in recommendedTags) {
      distanceMap[recTag.tagName] = recTag.distance;
    }
    
    // Tạo danh sách tags mới đã được sắp xếp
    final List<RoomTag> sortedTags = List.from(tags);
    
    // Sắp xếp tags: 
    // 1. Recommended tags trước (theo khoảng cách tăng dần)
    // 2. Các tags khác sau
    sortedTags.sort((a, b) {
      final bool aIsRecommended = distanceMap.containsKey(a.name);
      final bool bIsRecommended = distanceMap.containsKey(b.name);
      
      if (aIsRecommended && bIsRecommended) {
        // Cả hai đều được đề xuất, sắp xếp theo khoảng cách
        return distanceMap[a.name]!.compareTo(distanceMap[b.name]!);
      } else if (aIsRecommended) {
        // Chỉ a được đề xuất
        return -1;
      } else if (bIsRecommended) {
        // Chỉ b được đề xuất
        return 1;
      } else {
        // Không tag nào được đề xuất, giữ nguyên thứ tự
        return 0;
      }
    });
    
    // Tìm khoảng cách gần nhất nếu có
    String distanceInfo = '';
    final recommendedTagsInCategory = sortedTags.where((tag) => distanceMap.containsKey(tag.name)).toList();
    if (recommendedTagsInCategory.isNotEmpty) {
      final closestDistance = distanceMap[recommendedTagsInCategory.first.name]!;
      if (closestDistance > 0) {
        distanceInfo = ' • Từ ${closestDistance.toStringAsFixed(1)}km';
      }
    }
    
    return Container(
        decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(icon, color: AmenitiesStep.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AmenitiesStep.primaryColor,
                      ),
                    ),
                    if (distanceInfo.isNotEmpty)
                      Text(
                        distanceInfo,
                  style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.selectedTagIds.any((id) => tags.any((tag) => tag.id == id)))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AmenitiesStep.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.selectedTagIds.where((id) => tags.any((tag) => tag.id == id)).length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AmenitiesStep.primaryColor,
                ),
              ),
            ),
                  // Add count of recommended tags in this category
                  if (tags.any((tag) => recommendedTags.any((rt) => rt.tagName == tag.name)))
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                        color: AmenitiesStep.recommendedColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: AmenitiesStep.recommendedColor, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${tags.where((tag) => recommendedTags.any((rt) => rt.tagName == tag.name)).length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AmenitiesStep.recommendedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          initiallyExpanded: initiallyExpanded,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.grey.shade50,
          iconColor: AmenitiesStep.primaryColor,
          collapsedIconColor: Colors.grey.shade600,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: sortedTags.map((tag) {
                // Check if this tag is in recommended tags
                final isRecommended = recommendedTags.any((rt) => rt.tagName == tag.name);
                
                if (isRecommended) {
                  // Find the matching recommended tag to get distance
                  final recTag = recommendedTags.firstWhere(
                    (rt) => rt.tagName == tag.name,
                    orElse: () => RecommendedTag(tagName: '', distance: 0, name: ''),
                  );
                  
                  return _buildRecommendedTagItem(tag, recTag);
                } else {
                  return _buildTagItem(tag);
                }
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTagItem(RoomTag tag) {
    final bool isSelected = widget.selectedTagIds.contains(tag.id);
    final Color tagColor = _getColorForTag(tag);
    
    return ChoiceChip(
      avatar: Icon(
        _getIconForTag(tag),
        size: 18,
        color: isSelected ? Colors.white : tagColor,
      ),
      label: Text(
        tag.displayName ?? tag.name,
        style: TextStyle(
          color: isSelected ? Colors.white : AmenitiesStep.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => widget.onTagToggle(selected, tag.id),
      backgroundColor: Colors.white,
      selectedColor: tagColor,
      showCheckmark: false,
      elevation: isSelected ? 2 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? tagColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      pressElevation: 4,
    );
  }

  Widget _buildRecommendedTagItem(RoomTag tag, RecommendedTag recTag) {
    final bool isSelected = widget.selectedTagIds.contains(tag.id);
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AmenitiesStep.recommendedColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: ChoiceChip(
            avatar: Icon(
              _getIconForTag(tag),
              size: 18,
              color: isSelected ? Colors.white : AmenitiesStep.recommendedColor,
            ),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag.displayName != null && tag.displayName!.length > 4
                          ? tag.displayName!.substring(4)[0].toUpperCase() + tag.displayName!.substring(5)
                          : '',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AmenitiesStep.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),

                  ],
                ),
                if (recTag.distance > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.place,
                        size: 10,
                        color: isSelected ? Colors.white70 : Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${recTag.distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) => widget.onTagToggle(selected, tag.id),
            backgroundColor: Colors.white,
            selectedColor: AmenitiesStep.recommendedColor,
            showCheckmark: false,
            elevation: isSelected ? 3 : 1,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AmenitiesStep.recommendedColor : AmenitiesStep.recommendedColor.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            pressElevation: 4,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AmenitiesStep.recommendedColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars,
              color: Colors.white,
              size: 10,
            ),
          ),
        ),
      ],
    );
  }

  // Get appropriate icon for a tag
  IconData _getIconForTag(RoomTag tag) {
    // Map common tags to icons
    final Map<String, IconData> tagIcons = {
      // Room features
      'Air Conditioning': Icons.ac_unit,
      'Wifi': Icons.wifi,
      'TV': Icons.tv,
      'Bed': Icons.bed,
      'Kitchen': Icons.kitchen,
      'Fridge': Icons.kitchen,
      'Washing Machine': Icons.local_laundry_service,
      'Balcony': Icons.balcony,
      'Window': Icons.window,
      'Private Bathroom': Icons.bathroom,
      
      // Building features
      'Elevator': Icons.elevator,
      'Parking': Icons.local_parking,
      'Security': Icons.security,
      'CCTV': Icons.videocam,
      'Swimming Pool': Icons.pool,
      'Gym': Icons.fitness_center,
      
      // Nearby POI
      'Hospital': Icons.local_hospital,
      'School': Icons.school,
      'University': Icons.school,
      'Park': Icons.park,
      'Supermarket': Icons.shopping_cart,
      'Bus Stop': Icons.directions_bus,
      'Market': Icons.shopping_basket,
      
      // Policies
      'Pet Friendly': Icons.pets,
      'No Smoking': Icons.smoke_free,
      'No Alcohol': Icons.no_drinks,
      'Curfew': Icons.nightlight_round,
    };
    
    // Check if the tag name exists in the map
    for (var entry in tagIcons.entries) {
      if (tag.name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Default icon based on category
    switch (tag.category) {
      case TagCategory.IN_ROOM_FEATURE:
        return Icons.hotel;
      case TagCategory.BUILDING_FEATURE:
        return Icons.apartment;
      case TagCategory.NEARBY_POI:
        return Icons.location_on;
      case TagCategory.POLICY:
        return Icons.gavel;
      default:
        return Icons.star;
    }
  }

  // Get color for a tag
  Color _getColorForTag(RoomTag tag) {
    // Use variations of the accent color for different categories
    final Map<TagCategory, Color> categoryColors = {
      TagCategory.IN_ROOM_FEATURE: AmenitiesStep.primaryColor,  // Sử dụng màu chính (amenities)
      TagCategory.BUILDING_FEATURE: AmenitiesStep.primaryColor, // Sử dụng màu chính (amenities)
      TagCategory.NEARBY_POI: AmenitiesStep.primaryColor,       // Sử dụng màu chính (amenities)
      TagCategory.POLICY: AmenitiesStep.primaryColor,           // Sử dụng màu chính (amenities)
    };
    
    // Return the color for the tag's category
    return categoryColors[tag.category] ?? AmenitiesStep.primaryColor;
  }
} 