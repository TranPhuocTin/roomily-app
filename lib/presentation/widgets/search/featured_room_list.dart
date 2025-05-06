import 'package:flutter/material.dart';

import 'featured_room_card.dart';

class FeaturedRoomsList extends StatelessWidget {
  final List<Map<String, dynamic>> rooms;

  const FeaturedRoomsList({
    super.key,
    required this.rooms,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: Row(
          children: [
            SizedBox(width: 20),
            ...rooms.map(
                  (room) => Padding(
                padding: EdgeInsets.only(right: 20, bottom: 45),
                child: FeaturedRoomCard(roomData: room),
              ),
            ),
          ],
        ),
      ),
    );
  }
}