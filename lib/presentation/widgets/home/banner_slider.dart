import 'package:flutter/material.dart';

class BannerSlider extends StatefulWidget {
  final List<String> bannerUrls;
  final double height;
  final double borderRadius;
  final Duration autoScrollDuration;
  final bool enableAutoScroll;
  final Function(int)? onBannerTap;
  final EdgeInsetsGeometry padding;
  final Color indicatorActiveColor;
  final Color indicatorInactiveColor;
  final double viewportFraction;

  const BannerSlider({
    Key? key,
    required this.bannerUrls,
    this.height = 180,
    this.borderRadius = 20,
    this.autoScrollDuration = const Duration(seconds: 5),
    this.enableAutoScroll = true,
    this.onBannerTap,
    this.padding = EdgeInsets.zero,
    this.indicatorActiveColor = Colors.black,
    this.indicatorInactiveColor = Colors.grey,
    this.viewportFraction = 0.98,
  }) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Số lượng trang ảo ở mỗi bên để tạo hiệu ứng cuộn vô hạn
  static const int _infiniteOffset = 1000;

  @override
  void initState() {
    super.initState();
    // Bắt đầu từ vị trí giữa để có thể cuộn vô hạn về cả hai phía
    int initialPage = _infiniteOffset;
    _pageController = PageController(
      initialPage: initialPage, 
      viewportFraction: widget.viewportFraction,
    );
    _currentPage = initialPage % widget.bannerUrls.length;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
    
    if (widget.enableAutoScroll && widget.bannerUrls.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    Future.delayed(widget.autoScrollDuration, () {
      if (mounted) {
        // Luôn cuộn đến trang tiếp theo
        int nextPage = _pageController.page!.round() + 1;
        
        _animationController.reset();
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        ).then((_) {
          _animationController.forward();
        });
        
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                // Tính toán trang thực tế từ trang ảo
                int actualIndex = index % widget.bannerUrls.length;
                
                setState(() {
                  _currentPage = actualIndex;
                });
                
                _animationController.reset();
                _animationController.forward();
              },
              // Tạo số lượng trang vô hạn
              itemCount: null,
              itemBuilder: (context, index) {
                // Lấy trang thực tế từ trang ảo
                final int actualIndex = index % widget.bannerUrls.length;
                
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Tính toán scale dựa trên việc đây có phải là trang hiện tại không
                    final bool isCurrentPage = index % widget.bannerUrls.length == _currentPage;
                    final double scale = isCurrentPage ? _scaleAnimation.value : 0.98;
                    
                    return Transform.scale(
                      scale: scale,
                      child: _buildBannerItem(widget.bannerUrls[actualIndex], actualIndex),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildBannerItem(String imageUrl, int index) {
    return Hero(
      tag: 'banner_$index',
      child: GestureDetector(
        onTap: () {
          if (widget.onBannerTap != null) {
            widget.onBannerTap!(index);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // Banner Image
                Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade200,
                              Colors.teal.shade200,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Subtle gradient overlay for better text visibility if needed
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.bannerUrls.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentPage == index ? 16 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentPage == index
                ? widget.indicatorActiveColor.withOpacity(0.7)
                : widget.indicatorInactiveColor.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
} 