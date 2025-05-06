import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/presentation/screens/room_detail_screen.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:roomily/data/blocs/home/room_image_cubit.dart';
import 'package:roomily/data/blocs/home/room_image_state.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';

import '../../data/blocs/home/favorite_cubit.dart';
import '../../data/blocs/home/favorite_state.dart';

class SavedRoomsScreen extends StatelessWidget {
  final FavoriteCubit favoriteCubit;
  
  const SavedRoomsScreen({
    super.key,
    required this.favoriteCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: favoriteCubit,
        ),
        BlocProvider(
          create: (context) => RoomImageCubit(
            GetIt.instance<RoomImageRepository>(),
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phòng đã lưu'),
          elevation: 0,
        ),
        body: BlocConsumer<FavoriteCubit, FavoriteState>(
          listener: (context, state) {
            print('[SavedRoomsScreen] State changed: ${state.runtimeType}');
            if (state is FavoriteError) {
              print('[SavedRoomsScreen] Error: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state is FavoriteLoaded) {
              print('[SavedRoomsScreen] Loaded ${state.favoriteRooms.length} rooms');
              // Load images for all rooms
              for (final room in state.favoriteRooms) {
                if (room.id != null) {
                  context.read<RoomImageCubit>().fetchRoomImages(room.id!);
                }
              }
            }
            if (state is FavoriteLoaded && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is FavoriteLoading) {
              print('[SavedRoomsScreen] Showing loading state');
              return _buildLoadingList();
            }
            
            if (state is FavoriteLoaded) {
              final rooms = state.favoriteRooms;
              print('[SavedRoomsScreen] Building UI with ${rooms.length} rooms');
              
              if (rooms.isEmpty) {
                print('[SavedRoomsScreen] No rooms to display');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có phòng nào được lưu',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy lưu những phòng bạn yêu thích để xem lại sau',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () {
                  print('[SavedRoomsScreen] Manual refresh triggered');
                  return context.read<FavoriteCubit>().getFavoriteRooms();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return _buildRoomCard(context, room);
                  },
                ),
              );
            }
            
            return const Center(
              child: Text(
                'Đang tải danh sách phòng đã lưu...',
                style: TextStyle(color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 150,
                  color: Colors.white,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
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
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRoomCard(BuildContext context, Room room) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360; // Adjust based on your needs
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailScreen(roomId: room.id!),
            ),
          ).then((_) {
            // Refresh the list when returning from the detail screen
            context.read<FavoriteCubit>().getFavoriteRooms();
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                BlocBuilder<RoomImageCubit, RoomImageState>(
                  builder: (context, state) {
                    if (state is RoomImageLoaded && state.roomId == room.id) {
                      if (state.images.isNotEmpty) {
                        return Image.network(
                          state.images.first.url,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        );
                      }
                    }
                    return _buildImagePlaceholder();
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatPrice(room.price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () {
                        _handleFavoriteToggle(context, room);
                      },
                      iconSize: 24,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          room.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Wrapping with SingleChildScrollView makes this section scrollable horizontally
                  // and prevents overflow on narrow screens
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.square_foot,
                          label: '${room.squareMeters}m²',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.people_outline,
                          label: '${room.maxPeople} người',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.electric_bolt,
                          label: '${room.electricPrice}k',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Use a Center widget to make the button centered
                  Center(
                    child: SizedBox(
                      width: isNarrow ? double.infinity : null,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _handleFavoriteToggle(context, room);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(isNarrow ? 'Xóa' : 'Xóa khỏi danh sách'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      ),
    );
  }

  void _handleFavoriteToggle(BuildContext context, Room room) {
    if (room.id == null) return;
    
    print('[SavedRoomsScreen] Handling favorite toggle for room: ${room.id}');
    
    // Show loading indicator
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Đang xóa khỏi danh sách...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Call the toggleFavorite method in the cubit
    context.read<FavoriteCubit>().toggleFavorite(room.id!);
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatPrice(double price) {
    return FormatUtils.formatCurrency(price);
  }
} 