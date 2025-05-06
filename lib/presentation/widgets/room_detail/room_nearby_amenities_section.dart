import 'package:flutter/material.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/core/models/nearby_amenity_model.dart';
import 'package:roomily/data/models/room.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyAmenitiesSection extends StatelessWidget {
  final Room room;
  final int maxDisplayItems;

  const NearbyAmenitiesSection({
    super.key,
    required this.room,
    this.maxDisplayItems = 8,
  });

  List<NearbyAmenityModel> _parseNearbyAmenities() {
    if (room.nearbyAmenities == null || room.nearbyAmenities!.isEmpty) {
      return [];
    }

    final List<NearbyAmenityModel> amenities = [];
    final amenityStrings = room.nearbyAmenities!.split(',');

    for (final amenityString in amenityStrings) {
      if (amenityString.isEmpty) continue;

      final amenity = NearbyAmenityModel.fromString(amenityString);
      if (amenity != null) {
        amenities.add(amenity);
      }
    }

    // Sort by distance
    amenities.sort((a, b) => a.distance.compareTo(b.distance));
    
    // Limit to maxDisplayItems
    if (amenities.length > maxDisplayItems) {
      return amenities.sublist(0, maxDisplayItems);
    }
    
    return amenities;
  }

  @override
  Widget build(BuildContext context) {
    final amenities = _parseNearbyAmenities();
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tiện ích lân cận',
            style: AppTextStyles.heading5.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          if (amenities.isEmpty)
            _buildEmptyState()
          else
            GridView.count(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
              children: amenities.map((amenity) => _buildAmenityItem(context, amenity)).toList(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có thông tin về tiện ích lân cận',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityItem(BuildContext context, NearbyAmenityModel amenity) {
    return InkWell(
      onTap: () => _openInMaps(context, amenity),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              amenity.icon,
              color: Colors.blue,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              amenity.displayName,
              style: AppTextStyles.bodySmallMedium.copyWith(
                color: Colors.black87,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amenity.formattedDistance,
            style: AppTextStyles.bodySmallMedium.copyWith(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Future<void> _openInMaps(BuildContext context, NearbyAmenityModel amenity) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${amenity.latitude},${amenity.longitude}';
    
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở bản đồ cho ${amenity.displayName}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}

class AmenityItem {
  final IconData icon;
  final String label;

  const AmenityItem({
    required this.icon,
    required this.label,
  });

  static List<AmenityItem> getDefaultAmenities() {
    return [
      const AmenityItem(
        icon: Icons.local_parking,
        label: 'Car Parking',
      ),
      const AmenityItem(
        icon: Icons.pool,
        label: 'Swimming Pool',
      ),
      const AmenityItem(
        icon: Icons.fitness_center,
        label: 'Gym & Fitness',
      ),
      const AmenityItem(
        icon: Icons.restaurant,
        label: 'Restaurant',
      ),
      const AmenityItem(
        icon: Icons.wifi,
        label: 'Wi-fi & Network',
      ),
      const AmenityItem(
        icon: Icons.pets,
        label: 'Pet Center',
      ),
      const AmenityItem(
        icon: Icons.sports,
        label: 'Sport Center',
      ),
      const AmenityItem(
        icon: Icons.local_laundry_service,
        label: 'Laundry',
      ),
    ];
  }
} 