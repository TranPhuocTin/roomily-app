import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/presentation/widgets/home/room_card.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:get_it/get_it.dart';

import '../../../data/blocs/home/room_image_cubit.dart';
import '../../../data/blocs/home/room_image_state.dart';

class RoomCardWithImage extends StatefulWidget {
  final Room room;
  final RoomType roomType;
  final VoidCallback? onTap;

  const RoomCardWithImage({
    Key? key,
    required this.room,
    this.roomType = RoomType.vip,
    this.onTap,
  }) : super(key: key);

  @override
  State<RoomCardWithImage> createState() => _RoomCardWithImageState();
}

class _RoomCardWithImageState extends State<RoomCardWithImage> {
  late RoomImageCubit _roomImageCubit;
  
  @override
  void initState() {
    super.initState();
    // Khởi tạo RoomImageCubit
    _roomImageCubit = RoomImageCubit(GetIt.instance<RoomImageRepository>());
    // Tải hình ảnh của phòng
    _loadRoomImages();
  }
  
  @override
  void dispose() {
    _roomImageCubit.close();
    super.dispose();
  }
  
  void _loadRoomImages() {
    if (widget.room.id != null) {
      _roomImageCubit.fetchRoomImages(widget.room.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chuyển đổi giá thành chuỗi định dạng tiền tệ
    final formattedPrice = FormatUtils.formatCurrency(widget.room.price);
    
    return BlocProvider.value(
      value: _roomImageCubit,
      child: BlocBuilder<RoomImageCubit, RoomImageState>(
        builder: (context, state) {
          // Xác định URL hình ảnh dựa trên trạng thái
          String? imageUrl;
          
          if (state is RoomImageLoaded && state.images.isNotEmpty) {
            // Nếu đã tải được hình ảnh, sử dụng hình ảnh đầu tiên
            imageUrl = state.images.first.url;
          }
          
          return RoomCard(
            imageUrl: imageUrl ?? '', // Truyền chuỗi rỗng nếu không có URL
            roomName: widget.room.title,
            price: formattedPrice,
            address: widget.room.address,
            squareMeters: widget.room.squareMeters.toInt(),
            onTap: widget.onTap ?? () {
              print('Tapped on room: ${widget.room.title}');
            },
          );
        },
      ),
    );
  }
} 