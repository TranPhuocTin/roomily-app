import 'package:flutter/material.dart';
import 'package:roomily/presentation/screens/sign_in_screen.dart';
import 'models/intro_content.dart';
import 'intro_content_config.dart';
import '../intro_screen.dart';
import '../../../core/cache/intro_preference.dart';

class IntroPageView extends StatefulWidget {
  // final VoidCallback onFinish;
  // final VoidCallback? onLoginPressed;

  const IntroPageView({
    super.key,
    // required this.onFinish,
    // this.onLoginPressed,
  });

  @override
  State<IntroPageView> createState() => _IntroPageViewState();
}

class _IntroPageViewState extends State<IntroPageView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<IntroContent> _contents;
  bool _isAnimating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contents = IntroContentConfig.getIntroContents(
      context,
      onLoginPressed: _handleLogin,
    );
  }

  @override
  void initState() {
    IntroPreference.setIntroSeen();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleLogin() {

    
    // Kiểm tra xem widget còn mounted không trước khi gọi callback
    if (!mounted) return;

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignInScreen(),));
  }

  Future<void> _onNextPage() async {
    if (_isAnimating) return; // Prevent multiple taps while animating
    
    if (_currentPage < _contents.length - 1) {
      setState(() => _isAnimating = true);

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
      
      if (!mounted) return;
      setState(() => _isAnimating = false);
    } else {
      // _finishIntro();
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignInScreen(),));
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          // Nếu không phải màn hình đầu tiên, quay lại màn hình trước
          await _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false;
        }
        return true; // Cho phép thoát app nếu ở màn hình đầu tiên
      },
      child: PageView.builder(
        controller: _pageController,
        itemCount: _contents.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        physics: _isAnimating 
          ? const NeverScrollableScrollPhysics() 
          : const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return BaseIntroScreen(
            content: _contents[index],
            currentPage: index,
            totalPages: _contents.length,
            onNext: _onNextPage,
            // onSkip: _onSkip,
          );
        },
      ),
    );
  }
}