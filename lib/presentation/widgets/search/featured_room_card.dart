import 'package:flutter/material.dart';

import '../../../core/config/text_styles.dart';
import '../common/room_amenity.dart';
class FeaturedRoomCard extends StatelessWidget {
  final Map<String, dynamic> roomData;

  const FeaturedRoomCard({
    Key? key,
    required this.roomData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: MediaQuery.of(context).size.width * 0.65,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ảnh phòng
          Container(
            height: 150,
            width: MediaQuery.of(context).size.width * 0.75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                roomData['image'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Card thông tin
          Positioned(
            left: 10,
            right: 10,
            bottom: -45,
            child: Container(
              height: 95,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFFFF0000),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              roomData['title'],
                              style: AppTextStyles.bodySmallBold.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              roomData['address'],
                              style: AppTextStyles.bodyMediumMedium.copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RoomAmenity(
                                  icon: Icons.square_foot,
                                  value: roomData['area'],
                                  unit: 'm²',
                                  color: Color(0xFF0BDDDD),
                                ),
                                RoomAmenity(
                                  icon: Icons.bed,
                                  color: Color(0xFF0BDDDD),
                                ),
                                RoomAmenity(
                                  icon: Icons.people_alt_outlined,
                                  value: roomData['capacity'],
                                  color: Color(0xFF0BDDDD),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              roomData['price'],
                              style: AppTextStyles.bodySmallBold
                                  .copyWith(color: const Color(0xFF4A43EC)),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: VerticalDivider(
                          color: const Color(0xFFFAB0B0),
                        ),
                      ),
                      if (roomData['isVip'])
                        Container(
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.orange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: EdgeInsets.all(2),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Text(
                                'VIP',
                                style: AppTextStyles.heading5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}