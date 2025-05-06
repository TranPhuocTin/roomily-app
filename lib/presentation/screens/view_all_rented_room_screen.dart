import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/repositories/rented_room_repository.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/core/utils/rented_room_status.dart';
import 'package:roomily/presentation/screens/tenant_room_management_screen.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';

import '../../data/blocs/rented_room/rented_room_cubit.dart';
import '../../data/blocs/rented_room/rented_room_state.dart';

class ViewAllRentedRoomScreen extends StatelessWidget {
  const ViewAllRentedRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => RentedRoomCubit(
          rentedRoomRepository: GetIt.I<RentedRoomRepository>(),
          roomRepository: RoomRepositoryImpl(),
        )..getRentedRooms(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Phòng đã thuê',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: BlocConsumer<RentedRoomCubit, RentedRoomState>(
            listener: (context, state) {
              if (state is RentedRoomSuccess) {
                if (state.rentedRooms != null && state.rentedRooms!.isNotEmpty) {
                  context.read<RentedRoomCubit>().enrichRentedRoomsWithDetails(state.rentedRooms!);
                }
              }
            },
            builder: (context, state) {
              if (state is RentedRoomLoading || state is RentedRoomEnrichingDetails) {
                return const Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ));
              } else if (state is RentedRoomFailure) {
                return _buildErrorWidget(state.error);
              } else if (state is RentedRoomWithDetailsSuccess) {
                return _buildRoomsList(context, state.rentedRooms, state.roomDetails);
              } else if (state is RentedRoomSuccess) {
                final rooms = state.rentedRooms ?? [];
                if (rooms.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildRoomsList(context, rooms, {});
              }
              return const SizedBox();
            },
          ),
        ),
    );
  }
  
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_room.png', 
            height: 120,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.home_outlined,
              size: 80,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa thuê phòng nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy tìm kiếm và thuê phòng để quản lý tại đây',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context, List<RentedRoom> rooms, Map<String, Room> roomDetails) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final rentedRoom = rooms[index];
        final roomDetail = roomDetails[rentedRoom.roomId];
        return _buildRoomCard(context, rentedRoom, roomDetail);
      },
    );
  }

  Widget _buildRoomCard(BuildContext context, RentedRoom rentedRoom, Room? roomDetail) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (rentedRoom.status) {
      case RentedRoomStatus.IN_USE:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đang thuê';
        break;
      case RentedRoomStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Đang chờ xác nhận';
        break;
      case RentedRoomStatus.DEPOSIT_NOT_PAID:
        statusColor = Colors.amber;
        statusIcon = Icons.payment;
        statusText = 'Chưa thanh toán đặt cọc';
        break;
      case RentedRoomStatus.BILL_MISSING:
        statusColor = Colors.blue;
        statusIcon = Icons.receipt_long;
        statusText = 'Thiếu hóa đơn';
        break;
      case RentedRoomStatus.DEBT:
        statusColor = Colors.red;
        statusIcon = Icons.money_off;
        statusText = 'Đang nợ';
        break;
      case RentedRoomStatus.CANCELLED:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'Đã hủy';
        break;
    }

    String formatDate(String dateString) {
      try {
        final dateTime = DateTime.parse(dateString);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        return dateString;
      }
    }
    
    String formatCurrency(dynamic amount) {
      try {
        final value = double.parse(amount.toString());
        final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
        return formatter.format(value);
      } catch (e) {
        return '$amount ₫';
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TenantRoomManagementScreen(
                rentedRoomId: rentedRoom.id,
                roomDetail: roomDetail,
              ),
            ),
          ).then((_) {
            // Reload data when returning from TenantRoomManagementScreen
            debugPrint('🔄 Reloading data after returning from TenantRoomManagementScreen');
            context.read<RentedRoomCubit>().getRentedRooms();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      image: roomDetail?.id != null ? DecorationImage(
                        image: NetworkImage('https://roomily-images.s3.ap-southeast-1.amazonaws.com/${roomDetail!.id}/thumbnail.jpg'),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) => {},
                      ) : null,
                    ),
                    child: roomDetail?.id == null ? const Icon(
                      Icons.apartment,
                      size: 40,
                      color: Colors.teal,
                    ) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomDetail?.title ?? 'Phòng #${rentedRoom.roomId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (roomDetail != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            roomDetail.address,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const Divider(height: 24),
              if (roomDetail != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.money,
                        'Giá phòng',
                        formatCurrency(roomDetail.price),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.electric_bolt,
                        'Giá điện',
                        '${formatCurrency(roomDetail.electricPrice)}/kWh',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.water_drop,
                        'Giá nước',
                        '${formatCurrency(roomDetail.waterPrice)}/m³',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày bắt đầu',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(rentedRoom.startDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày kết thúc',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(rentedRoom.endDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 16, color: Colors.teal),
                    const SizedBox(width: 4),
                    Text(
                      'Ví phòng: ${formatCurrency(rentedRoom.rentedRoomWallet)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
