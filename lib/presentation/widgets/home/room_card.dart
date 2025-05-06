import 'package:flutter/material.dart';
import 'package:roomily/core/utils/format_utils.dart';

enum RoomType {
  normal,
  vip,
  nearby,
  new_listing,
}

class RoomCard extends StatelessWidget {
  final String imageUrl;
  final String roomName;
  final String price;
  final String address;
  final bool isPromoted;
  final int squareMeters;
  final VoidCallback? onTap;

  const RoomCard({
    Key? key,
    required this.imageUrl,
    required this.roomName,
    required this.price,
    required this.address,
    this.isPromoted = false,
    required this.squareMeters,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      // Sử dụng SizedBox thay vì Stack để đảm bảo kích thước phù hợp với GridView
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(2), // Giảm margin để tối đa hóa kích thước
        elevation: 3, // Tăng elevation cho VIP
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phần ảnh - chiếm đủ 2/3 chiều cao của card
                Stack(
                  children: [
                    // Ảnh phòng
                    AspectRatio(
                      aspectRatio: 1/1, // Thay đổi từ 4/3 thành 1/1 để ảnh cao hơn và lấp đầy khoảng trống
                      child: _buildImage(),
                    ),
                    // Nút "VIP" nếu là phòng VIP
                    if (isPromoted)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Ads',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Phần thông tin
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên phòng - giới hạn 1 dòng
                      Text(
                        roomName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Khoảng cách
                      const SizedBox(height: 4),

                      // Giá phòng - với màu nổi bật
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Khoảng cách
                      const SizedBox(height: 4),
                      
                      // Địa chỉ - thu nhỏ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 11,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tạo widget hiển thị ảnh phòng
  Widget _buildImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Ảnh chính
        if (imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 30,
              ),
            ),
          )
        else
          Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 30,
            ),
          ),
          
        // Diện tích phòng (overlay ở góc dưới bên phải của ảnh)
        Positioned(
          bottom: 5,
          right: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.straighten,
                  size: 10,
                  color: Colors.white,
                ),
                const SizedBox(width: 2),
                Text(
                  '$squareMeters m²',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}