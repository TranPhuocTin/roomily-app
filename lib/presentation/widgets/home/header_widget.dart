import 'package:flutter/material.dart';
import 'package:roomily/core/services/search_service.dart';
import 'package:roomily/core/services/user_location_service.dart';
import 'package:roomily/core/services/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../data/blocs/notification/notification_cubit.dart';
import '../../../data/blocs/notification/notification_state.dart';

class HeaderWidget extends StatefulWidget {
  final String avatarUrl;
  final String searchHint;
  final VoidCallback onNotificationPressed;
  final Function(SearchResult)? onSearchResultSelected;
  final bool isSearch;
  final bool showAvatar;
  final Widget? leadingIcon;
  final double iconSize;
  final EdgeInsets iconPadding;
  final bool showDivider;
  final bool showNotification;
  final VoidCallback? onSearchFieldTap;

  const HeaderWidget({
    Key? key,
    required this.avatarUrl,
    this.searchHint = "Tìm kiếm địa điểm...",
    required this.onNotificationPressed,
    this.onSearchResultSelected,
    this.isSearch = false,
    this.showAvatar = false,
    this.leadingIcon,
    this.iconSize = 35,
    this.iconPadding = const EdgeInsets.only(left: 5, top: -5),
    this.showDivider = true,
    this.showNotification = true,
    this.onSearchFieldTap,
  }) : super(key: key);

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SearchService _searchService = GetIt.instance<SearchService>();
  final UserLocationService _userLocationService = GetIt.instance<UserLocationService>();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _currentLocationHint = "Tìm kiếm địa điểm...";
  // String _lastKnownLocation = "";

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showResults = _focusNode.hasFocus && _searchResults.isNotEmpty;
      });
    });
    
    // Lấy địa chỉ hiện tại từ UserLocationService
    // _updateLocationHintFromService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Lấy địa chỉ hiện tại từ UserLocationService và lưu vào cache
  // void _updateLocationHintFromService() {
  //   if (!mounted) return;
  //
  //   // Lấy giá trị từ service
  //   String locationString = _userLocationService.currentLocationString;
  //
  //   // Nếu giá trị không thay đổi, không cần cập nhật UI
  //   if (locationString == _lastKnownLocation && _currentLocationHint.isNotEmpty) {
  //     return;
  //   }
  //
  //   // Lưu vào cache
  //   _lastKnownLocation = locationString;
  //
  //   // Lấy địa chỉ chi tiết từ currentAddress nếu có
  //   final currentAddress = _userLocationService.currentAddress;
  //   String displayLocation = locationString;
  //
  //   if (currentAddress != null) {
  //     // Ưu tiên hiển thị thông tin đường và quận nếu có
  //     final List<String> addressParts = [];
  //
  //     if (currentAddress.street != null && currentAddress.street!.isNotEmpty) {
  //       addressParts.add(currentAddress.street!);
  //     }
  //
  //     if (currentAddress.district != null && currentAddress.district!.isNotEmpty) {
  //       // Chuyển district sang dạng có dấu để hiển thị
  //       String districtDisplay = currentAddress.district!;
  //       // Nếu là quận số thì hiển thị dạng "Quận X"
  //       if (RegExp(r'^district\s+\d+$', caseSensitive: false).hasMatch(districtDisplay)) {
  //         final districtNumber = districtDisplay.toLowerCase().replaceAll('district', '').trim();
  //         districtDisplay = 'Quận $districtNumber';
  //       }
  //       addressParts.add(districtDisplay);
  //     }
  //
  //     if (currentAddress.city != null && currentAddress.city!.isNotEmpty) {
  //       // Chuyển đổi tên thành phố về dạng có dấu
  //       String cityDisplay = currentAddress.city!;
  //       if (cityDisplay.toLowerCase() == 'ho chi minh') {
  //         cityDisplay = 'TP. Hồ Chí Minh';
  //       } else if (cityDisplay.toLowerCase() == 'ha noi') {
  //         cityDisplay = 'Hà Nội';
  //       } else if (cityDisplay.toLowerCase() == 'da nang') {
  //         cityDisplay = 'Đà Nẵng';
  //       }
  //       addressParts.add(cityDisplay);
  //     }
  //
  //     if (addressParts.isNotEmpty) {
  //       displayLocation = addressParts.join(', ');
  //     }
  //   }
  //
  //   setState(() {
  //     // Giới hạn độ dài, nếu quá dài sẽ cắt bớt
  //     if (displayLocation.length > 35) {
  //       final parts = displayLocation.split(', ');
  //       if (parts.length > 1) {
  //         // Nếu có nhiều phần, ưu tiên giữ lại phần đầu (tên đường) và phần cuối (thành phố)
  //         if (parts.length >= 3) {
  //           displayLocation = '${parts.first}, ${parts.last}';
  //         } else {
  //           // Nếu chỉ có 2 phần, giữ nguyên
  //           displayLocation = parts.join(', ');
  //         }
  //       } else {
  //         // Nếu chỉ có 1 phần dài, cắt bớt và thêm "..."
  //         displayLocation = displayLocation.substring(0, 35) + '...';
  //       }
  //     }
  //
  //     _currentLocationHint = displayLocation.isNotEmpty ? displayLocation : "Tìm kiếm địa điểm...";
  //   });
  // }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final results = await _searchService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          child: Row(
            children: [
              // Avatar
              widget.showAvatar
                  ? Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          widget.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person,
                                size: 30, color: Colors.grey);
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),

              SizedBox(width: widget.showAvatar ? 12 : 0),

              // Search field with location icon
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Search field background
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.only(
                          left: widget.leadingIcon != null ? 12 : 40, right: 12),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          if (widget.leadingIcon != null) ...[
                            SizedBox(
                              width: widget.iconSize,
                              height: widget.iconSize,
                              child: widget.leadingIcon,
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Vertical divider
                          if (widget.showDivider)
                            Container(
                              width: 2,
                              height: 20,
                              color: Colors.red.shade400,
                              margin: const EdgeInsets.only(right: 8),
                            ),

                          // Search TextField
                          Expanded(
                            child: widget.onSearchFieldTap != null 
                              // Nếu có onSearchFieldTap, sử dụng GestureDetector để không hiện bàn phím
                              ? GestureDetector(
                                  onTap: widget.onSearchFieldTap,
                                  child: AbsorbPointer(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _focusNode,
                                      decoration: InputDecoration(
                                        hintText: _currentLocationHint,
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 20),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchResults = [];
                                                    _showResults = false;
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 14,
                                      ),
                                      textAlignVertical: TextAlignVertical.center,
                                    ),
                                  ),
                                )
                              // Nếu không có onSearchFieldTap, sử dụng TextField thông thường
                              : TextField(
                                  controller: _searchController,
                                  focusNode: _focusNode,
                                  decoration: InputDecoration(
                                    hintText: _currentLocationHint,
                                    hintStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 20),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchResults = [];
                                                _showResults = false;
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 14,
                                  ),
                                  onChanged: (value) {
                                    _performSearch(value);
                                  },
                                  textAlignVertical: TextAlignVertical.center,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Default map icon when no custom icon is provided
                    if (widget.leadingIcon == null)
                      Positioned(
                        left: widget.iconPadding.left,
                        top: widget.iconPadding.top,
                        child: Image.asset(
                          'assets/icons/map_active_icon.png',
                          width: widget.iconSize,
                          height: widget.iconSize,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Notification icon
              widget.showNotification
                  ? Builder(
                      builder: (context) {
                        try {
                          // Thử lấy NotificationService từ GetIt
                          final notificationService = GetIt.I<NotificationService>();
                          
                          return BlocProvider.value(
                            value: notificationService.notificationCubit,
                            child: BlocBuilder<NotificationCubit, NotificationState>(
                              builder: (context, state) {
                                return GestureDetector(
                                  onTap: widget.onNotificationPressed,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Image.asset(
                                        'assets/icons/notification_icon.png',
                                        width: 35,
                                        height: 35,
                                      ),
                                      if (state.unreadCount > 0)
                                        Positioned(
                                          right: -5,
                                          top: -5,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        } catch (e) {
                          // Fallback khi NotificationService chưa được đăng ký hoặc khởi tạo
                          debugPrint('Không thể lấy NotificationService: $e');
                          return GestureDetector(
                            onTap: widget.onNotificationPressed,
                            child: Image.asset(
                              'assets/icons/notification_icon.png',
                              width: 35,
                              height: 35,
                            ),
                          );
                        }
                      },
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxHeight: 200, // Giới hạn chiều cao tối đa
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_searchResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Không tìm thấy kết quả'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          leading: Icon(
                            result.placeType == 'address'
                                ? Icons.location_on
                                : Icons.place,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          title: Text(
                            result.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            result.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            if (widget.onSearchResultSelected != null) {
                              widget.onSearchResultSelected!(result);
                            }
                            _searchController.clear();
                            _focusNode.unfocus();
                            setState(() {
                              _searchResults = [];
                              _showResults = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
