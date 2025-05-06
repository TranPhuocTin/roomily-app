import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/presentation/widgets/common/section_divider.dart';
import 'package:roomily/presentation/widgets/room_detail/room_nearby_amenities_section.dart';
import 'package:flutter/services.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:roomily/data/models/ad_click_response_model.dart';
import '../../data/blocs/chat_room/chat_room_cubit.dart';
import '../../data/blocs/home/favorite_cubit.dart';
import '../../data/blocs/home/room_detail_cubit.dart';
import '../../data/blocs/home/room_detail_state.dart';
import '../../data/blocs/home/room_image_cubit.dart';
import '../../data/blocs/home/room_image_state.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/chat_room_repository.dart';
import '../../data/blocs/chat_room/direct_chat_room_cubit.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/room_report/room_report_cubit.dart';
import '../../data/repositories/room_report_repository.dart';
import '../widgets/room_detail/bottom_bubble_button.dart';
import '../widgets/room_detail/gallery_section.dart';
import '../widgets/room_detail/room_detail_header_section.dart';
import '../widgets/room_detail/room_detail_introduce_section.dart';
import '../widgets/room_detail/room_detail_property_section.dart';
import '../widgets/room_detail/room_location_section.dart';
import '../widgets/room_detail/roommate_finder_section.dart';
import '../widgets/room_detail/landlord_statistics_section.dart';
import '../widgets/room_detail/report_dialog.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final AdClickResponseModel? adClickResponse;

  const RoomDetailScreen({
    super.key, 
    required this.roomId, 
    this.adClickResponse,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final List<String> roomImages = [
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1560448204-603b3fc33ddc?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80'
  ];

  late ScrollController _scrollController;
  bool _isScrolled = false;
  Uint8List? _markerImageBytes;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadMarkerImage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  void showReportDialog(BuildContext context) {
    final roomId = widget.roomId;
    
    // Show bottom sheet with report option
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.report_problem, color: Colors.red),
                title: Text('Báo cáo phòng trọ này'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  
                  // Show report dialog
                  showDialog(
                    context: context,
                    builder: (context) => BlocProvider(
                      create: (context) => RoomReportCubit(
                        repository: GetIt.I<RoomReportRepository>(),
                      ),
                      child: ReportDialog(roomId: roomId),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadMarkerImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/icons/map_marker.png');
      setState(() {
        _markerImageBytes = data.buffer.asUint8List();
      });
    } catch (e) {
      print('Error loading marker image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RoomDetailCubit(GetIt.I<RoomRepository>())
            ..fetchRoomById(widget.roomId),
        ),
        BlocProvider(
          create: (context) => RoomImageCubit(GetIt.I<RoomImageRepository>())
            ..fetchRoomImages(widget.roomId),
        ),
        BlocProvider(
          create: (context) => FavoriteCubit(GetIt.I<FavoriteRepository>())
            ..loadRoomFavoriteData(widget.roomId),
        ),
        BlocProvider(
          create: (context) => ChatRoomCubit(repository: GetIt.I<ChatRoomRepository>()),
        ),
        BlocProvider(
          create: (context) {
            final roomDetailCubit = context.read<RoomDetailCubit>();
            final chatRoomCubit = context.read<ChatRoomCubit>();
            return DirectChatRoomCubit(
              repository: GetIt.I<ChatRoomRepository>(),
              chatRoomCubit: chatRoomCubit,
              roomDetailCubit: roomDetailCubit,
            );
          },
        ),
        BlocProvider(
          create: (context) => UserCubit(userRepository: GetIt.I<UserRepository>()),
        ),
        BlocProvider(
          create: (context) => RoomReportCubit(repository: GetIt.I<RoomReportRepository>()),
        ),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          foregroundColor: _isScrolled ? Colors.black : Colors.white,
          backgroundColor: _isScrolled
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.transparent,
          elevation: _isScrolled ? 2 : 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.grey,
          actions: [
            IconButton(
              onPressed: () {
                showReportDialog(context);
              },
              icon: Icon(
                Icons.more_vert,
                color: _isScrolled ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RoomDetailHeaderSection(),
                  const RoomDetailIntroduceSection(),
                  const SectionDivider(),
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: PropertyDetailsSection(),
                  ),
                  const SectionDivider(),
                  BlocBuilder<RoomDetailCubit, RoomDetailState>(
                    builder: (context, state) {
                      if (state is RoomDetailLoaded) {
                        return RoommateFinder(room: state.room);
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                  const SectionDivider(),
                  BlocBuilder<RoomDetailCubit, RoomDetailState>(
                    builder: (context, state) {
                      if (state is RoomDetailLoaded) {
                        return LandlordStatisticsSection(room: state.room);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SectionDivider(),
                  BlocBuilder<RoomDetailCubit, RoomDetailState>(
                    builder: (context, state) {
                      if (state is RoomDetailLoaded && 
                          state.room.latitude != null && 
                          state.room.longitude != null) {
                        return RoomLocationSection(
                          latitude: state.room.latitude!,
                          longitude: state.room.longitude!,
                          title: state.room.title,
                          address: state.room.address,
                          price: FormatUtils.formatCurrency(state.room.price ?? 0),
                          onMapTap: () {
                            // Mở bản đồ lớn với vị trí của phòng
                            final roomPosition = LatLng(
                              state.room.latitude!,
                              state.room.longitude!,
                            );
                            
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    title: Text('Vị trí ${state.room.title}'),
                                    leading: IconButton(
                                      icon: Icon(Icons.arrow_back),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                  body: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: roomPosition,
                                      zoom: 16.0,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('room_location'),
                                        position: roomPosition,
                                        infoWindow: InfoWindow(
                                          title: state.room.title,
                                          snippet: state.room.address,
                                        ),
                                      ),
                                    },
                                    myLocationButtonEnabled: true,
                                    zoomControlsEnabled: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SectionDivider(),
                  BlocBuilder<RoomDetailCubit, RoomDetailState>(
                    builder: (context, state) {
                      if (state is RoomDetailLoaded) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: NearbyAmenitiesSection(
                            room: state.room,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  BlocBuilder<RoomImageCubit, RoomImageState>(
                    builder: (context, state) {
                      if (state is RoomImageLoaded && state.images.isNotEmpty) {
                        return Column(
                          children: [
                            const SectionDivider(),
                            Padding(  
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: const GallerySection(),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomBubbleButton(
                adClickResponse: widget.adClickResponse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
