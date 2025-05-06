import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/contract/contract_cubit.dart';
import 'package:roomily/data/repositories/contract_repository.dart';
import 'package:roomily/data/repositories/contract_repository_impl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../data/blocs/contract/contract_state.dart';

/// A screen for viewing contract HTML content using WebView
class ContractViewerScreen extends StatefulWidget {
  final String roomId;
  final bool isRentedRoom;

  /// Constructor for [ContractViewerScreen]
  const ContractViewerScreen({
    Key? key,
    required this.roomId,
    this.isRentedRoom = false,
  }) : super(key: key);

  @override
  State<ContractViewerScreen> createState() => _ContractViewerScreenState();
}

class _ContractViewerScreenState extends State<ContractViewerScreen> {
  late WebViewController _controller;
  late ContractCubit _contractCubit;

  @override
  void initState() {
    super.initState();
    // Initialize the contract cubit with the repository implementation
    _contractCubit = ContractCubit(repository: ContractRepositoryImpl());
    // Fetch contract when the screen initializes
    _loadContract();
  }

  @override
  void dispose() {
    // Make sure to close the Cubit when the screen is disposed
    _contractCubit.close();
    super.dispose();
  }

  Future<void> _loadContract() async {
    if (widget.isRentedRoom) {
      await _contractCubit.getContractByRentedRoom(widget.roomId);
    } else {
      await _contractCubit.getDefaultContract(widget.roomId);
    }
  }

  Future<void> _downloadContractPdf() async {
    try {
      final pdfBytes = await _contractCubit.downloadContractPdf(widget.roomId);
      if (pdfBytes != null) {
        // Here you could implement saving or opening the PDF
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File PDF đã được tải xuống thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải file PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hợp đồng thuê phòng'),
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContract,
          ),
          // Tải xuống PDF
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadContractPdf,
          ),
          // In hợp đồng
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              _controller.runJavaScript('window.print()');
            },
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _contractCubit,
        child: BlocConsumer<ContractCubit, ContractState>(
          listener: (context, state) {
            if (state is ContractError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ContractInitial) {
              return const Center(
                child: Text('Bấm nút làm mới để tải hợp đồng'),
              );
            }
            
            if (state is ContractLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (state is ContractLoaded) {
              // Tạo JavaScript để cấu hình các tùy chọn cho zoom và pan
              const String zoomPanScript = '''
                // Kích hoạt zoom và pan
                document.body.style.touchAction = 'manipulation';
                document.body.style.userSelect = 'none';
                document.body.style.webkitUserSelect = 'none';
                
                // Thêm meta tag để hiển thị toàn bộ trang với zoom out
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=0.4, maximum-scale=5.0, user-scalable=yes';
                document.getElementsByTagName('head')[0].appendChild(meta);
                
                // Đặt style để fit nội dung vào khung nhìn
                document.body.style.transform = 'scale(0.9)';
                document.body.style.transformOrigin = 'top center';
                document.body.style.margin = '0';
                document.body.style.padding = '10px';
                
                // Đảm bảo các nút Print hoạt động
                var printButtons = document.getElementsByClassName('print-button');
                for (var i = 0; i < printButtons.length; i++) {
                  printButtons[i].addEventListener('click', function() {
                    window.print();
                  });
                }
              ''';
              
              // Initialize WebView controller with HTML content
              _controller = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setBackgroundColor(Colors.white)
                ..enableZoom(true)
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onPageFinished: (String url) {
                      _controller.runJavaScript(zoomPanScript);
                    },
                  ),
                )
                ..loadHtmlString(state.htmlContent, baseUrl: 'https://roomily.tech');
              
              return WebViewWidget(controller: _controller);
            }
            
            // Default or error state
            return Center(
              child: Text(
                state is ContractError 
                    ? 'Lỗi khi tải hợp đồng: ${state.message}' 
                    : 'Không thể tải hợp đồng',
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }
}