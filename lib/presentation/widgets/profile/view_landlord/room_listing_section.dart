import 'package:flutter/material.dart';
import 'package:roomily/presentation/widgets/home/room_card.dart';

class RoomListingSection extends StatelessWidget {
  const RoomListingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          RoomCard(
            imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2000&q=80',
            roomName: 'PHÒNG HÒA VANG',
            price: '3.000.000đ/Tháng',
            address: '09 Phạm Công Trứ, Hòa Vang, Đà Nẵng',
            squareMeters: 30,
            onTap: () {},
          ),
          RoomCard(
            imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2000&q=80',
            roomName: 'PHÒNG Tam Kỳ',
            price: '3.000.000đ/Tháng',
            address: '09 Phạm Công Trứ, Hòa Vang, Đà Nẵng',
            squareMeters: 30,
            onTap: () {},
          ),
          RoomCard(
            imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2000&q=80',
            roomName: 'PHÒNG HÒA VANG',
            price: '3.000.000đ/Tháng',
            address: '09 Phạm Công Trứ, Hòa Vang, Đà Nẵng',
            squareMeters: 30,
            onTap: () {},
          ),
          RoomCard(
            imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2000&q=80',
            roomName: 'PHÒNG Tam Kỳ',
            price: '3.000.000đ/Tháng',
            address: '09 Phạm Công Trứ, Hòa Vang, Đà Nẵng',
            squareMeters: 30,
            onTap: () {},
          ),
        ],
      ),
    );
  }
} 