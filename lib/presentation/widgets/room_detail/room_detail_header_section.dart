import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:roomily/presentation/widgets/common/cached_image.dart';

import '../../../data/blocs/home/room_image_cubit.dart';
import '../../../data/blocs/home/room_image_state.dart';

class RoomDetailHeaderSection extends StatefulWidget {
  const RoomDetailHeaderSection({super.key});

  @override
  _RoomDetailHeaderSectionState createState() => _RoomDetailHeaderSectionState();
}

class _RoomDetailHeaderSectionState extends State<RoomDetailHeaderSection> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(1); // Trang bắt đầu từ 1

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 300,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomImageCubit, RoomImageState>(
      builder: (context, state) {
        if (state is RoomImageInitial || state is RoomImageLoading) {
          return _buildShimmer();
        } else if (state is RoomImageLoaded) {
          final roomImages = state.images.take(5).toList(); // Giới hạn 5 ảnh
          final totalImages = roomImages.length;

          return SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: totalImages,
                  onPageChanged: (index) {
                    _currentPage.value = index + 1; // Cập nhật trang
                  },
                  itemBuilder: (context, index) {
                    return CachedImage(
                      imageUrl: roomImages[index].url,
                      type: ImageType.room,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: _buildShimmer(),
                    );
                  },
                ),
                Positioned(
                  bottom: 16, // Đẩy lên một chút
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _currentPage,
                      builder: (context, page, _) {
                        return Text(
                          '$page / $totalImages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Mũi tên trái
                Positioned(
                  left: 16,
                  top: 150, // Điều chỉnh vị trí theo nhu cầu
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_left,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      if (_pageController.page! > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
                // Mũi tên phải
                Positioned(
                  right: 16,
                  top: 150, // Điều chỉnh vị trí theo nhu cầu
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_right,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      if (_pageController.page! < totalImages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          return SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CachedImage(
                  imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
                  type: ImageType.room,
                  fit: BoxFit.cover,
                  placeholder: _buildShimmer(),
                ),
                const Positioned(
                  bottom: 16,
                  child: Text(
                    'No images available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
