import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/presentation/screens/gallery_detail_screen.dart';

import '../../../data/blocs/home/room_image_cubit.dart';
import '../../../data/blocs/home/room_image_state.dart';

class GallerySection extends StatelessWidget {
  const GallerySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomImageCubit, RoomImageState>(
      builder: (context, state) {
        if (state is RoomImageLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RoomImageLoaded) {
          final images = state.images;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gallery',
                      style: AppTextStyles.heading5,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GalleryDetailScreen(
                              images: images,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'See all',
                        style: AppTextStyles.bodyMediumSemiBold.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: images.length > 3 ? 3 : images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GalleryDetailScreen(
                              images: images,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'gallery_image_$index',
                              child: Image.network(
                                images[index].url,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (index == 2 && images.length > 3)
                              Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Center(
                                  child: Text(
                                    '+${images.length - 3}',
                                    style: AppTextStyles.heading4.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        } else if (state is RoomImageError) {
          return Text('Error: ${state.message}');
        }
        return const SizedBox.shrink();
      },
    );
  }
}