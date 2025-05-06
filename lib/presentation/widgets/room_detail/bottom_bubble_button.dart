import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/data/blocs/chat_room/direct_chat_room_cubit.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:roomily/data/models/ad_click_response_model.dart';

import '../../../data/blocs/chat_room/direct_chat_room_state.dart';
import '../../../data/blocs/home/favorite_cubit.dart';
import '../../../data/blocs/home/favorite_state.dart';
import '../../../data/blocs/home/room_detail_cubit.dart';
import '../../../data/blocs/home/room_detail_state.dart';

class BottomBubbleButton extends StatelessWidget {
  final AdClickResponseModel? adClickResponse;

  const BottomBubbleButton({
    Key? key,
    this.adClickResponse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BlocBuilder<RoomDetailCubit, RoomDetailState>(
        builder: (context, state) {
          // Hiển thị shimmer khi đang tải thông tin phòng
          if (state is! RoomDetailLoaded) {
            return _buildShimmerContent(context);
          }

          double price = state.room.price ?? 0;
          String formattedPrice = FormatUtils.formatCurrency(price);
          String? roomId = state.room.id;
          
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Giá thuê',
                      style: AppTextStyles.bodySmallMedium.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            formattedPrice,
                            style: AppTextStyles.heading5.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/tháng',
                          style: AppTextStyles.bodySmallMedium.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Nút Lưu (Favorite)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: BlocBuilder<FavoriteCubit, FavoriteState>(
                        builder: (context, favoriteState) {
                          // Hiển thị shimmer khi đang tải trạng thái yêu thích
                          if (favoriteState is FavoriteLoading) {
                            return _buildShimmerFavoriteButton(context);
                          }
                          
                          bool isFavorite = false;
                          if (favoriteState is FavoriteLoaded) {
                            isFavorite = favoriteState.isFavorite;
                          }
                          
                          return CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[200],
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border, 
                                size: 18,
                                color: isFavorite ? Colors.red : Theme.of(context).primaryColor,
                              ),
                              onPressed: roomId != null 
                                ? () => context.read<FavoriteCubit>().toggleFavorite(roomId)
                                : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          );
                        },
                      ),
                    ),
                    // Nút Liên hệ
                    Expanded(
                      child: BlocBuilder<DirectChatRoomCubit, DirectChatRoomState>(
                        builder: (context, directChatState) {
                          bool isLoading = directChatState is DirectChatRoomLoadingForRoom;
                          bool isAdConversation = adClickResponse != null;
                          
                          return ElevatedButton.icon(
                            onPressed: (roomId != null && !isLoading)
                                ? () {
                                    // Thêm context vào createDirectChatRoom
                                    context.read<DirectChatRoomCubit>().createDirectChatRoom(
                                      roomId,
                                      context: context,
                                      isAdConversation: isAdConversation,
                                      adClickId: adClickResponse?.adClickId,
                                    );
                                  }
                                : null,
                            icon: isLoading 
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.message_outlined, size: 16),
                            label: Text(isLoading ? 'Đang xử lý...' : 'Liên hệ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(double.infinity, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmerContent(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Shimmer cho nút yêu thích
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                  ),
                ),
                // Shimmer cho nút liên hệ
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerFavoriteButton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
      ),
    );
  }

  String _formatPrice(double price) {
    // Replaced with FormatUtils.formatCurrency
    return FormatUtils.formatCurrency(price);
  }
} 