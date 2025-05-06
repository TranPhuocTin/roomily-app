import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:roomily/presentation/widgets/chat/room_action_area.dart';
import 'package:roomily/presentation/widgets/chat/pinned_property_card.dart';
import 'package:roomily/core/utils/format_utils.dart';

import '../../../data/blocs/home/room_detail_cubit.dart';
import '../../../data/blocs/home/room_detail_state.dart';

class RoomInfoCard extends StatelessWidget {
  final ChatRoomInfo chatRoomInfo;
  final bool isLandlord;
  final String? currentUserId;
  final VoidCallback onInfoRefreshed;

  const RoomInfoCard({
    Key? key,
    required this.chatRoomInfo,
    required this.isLandlord,
    this.currentUserId,
    required this.onInfoRefreshed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocBuilder<RoomDetailCubit, RoomDetailState>(
        buildWhen: (previous, current) {
          // Chỉ rebuild khi state thay đổi và là loại cần quan tâm
          if (previous is RoomDetailLoaded && current is RoomDetailLoaded) {
            final prevRoom = previous.room;
            final currentRoom = current.room;
            // Chỉ rebuild khi thông tin phòng thay đổi đáng kể
            return prevRoom.id != currentRoom.id || 
                   prevRoom.status != currentRoom.status ||
                   prevRoom.price != currentRoom.price;
          }
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          if (state is RoomDetailLoaded) {
            return _RoomInfoCardContent(
              chatRoomInfo: chatRoomInfo,
              isLandlord: isLandlord,
              currentUserId: currentUserId,
              onInfoRefreshed: onInfoRefreshed,
              roomState: state,
            );
          }
          
          if (state is RoomDetailLoading) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RoomInfoCardContent extends StatelessWidget {
  final ChatRoomInfo chatRoomInfo;
  final bool isLandlord;
  final String? currentUserId;
  final VoidCallback onInfoRefreshed;
  final RoomDetailLoaded roomState;

  const _RoomInfoCardContent({
    Key? key,
    required this.chatRoomInfo,
    required this.isLandlord,
    required this.currentUserId,
    required this.onInfoRefreshed,
    required this.roomState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product chat bubble
          ProductChatBubble(
            imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcThQrcN_jtpZLpMHVpgE_Z9jF4xrWeRXtBO0EkjgAvMF2gsmD-zvN7H3D9YHIo_I7D08vAjaw&s',
            roomName: roomState.room.title,
            price: FormatUtils.formatCurrency(roomState.room.price),
            address: roomState.room.address,
            onTap: () {
              if (chatRoomInfo.roomId != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View details of ${roomState.room.title}')),
                );
              }
            },
          ),
          
          // Room status indicator (if any)
          if (roomState.room.status.toString().contains('RENTED'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLandlord ? 'This room is currently rented' : 'You are renting this room',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Room action area - Đặt trong RepaintBoundary riêng để tránh rebuild
          RepaintBoundary(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: RoomActionArea(
                chatRoomInfo: chatRoomInfo,
                isLandlord: isLandlord,
                currentUserId: currentUserId,
                onInfoRefreshed: onInfoRefreshed,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 