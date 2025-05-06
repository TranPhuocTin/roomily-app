import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/payment_request.dart';
import 'package:intl/intl.dart';

import '../../data/blocs/payment/payment_cubit.dart';
import '../../data/blocs/payment/payment_state.dart';
import 'payment_qr_screen.dart';

class PaymentInputScreen extends StatefulWidget {
  final String? rentedRoomId;
  final bool inAppWallet;
  final bool isLandlordDashboard;
  
  const PaymentInputScreen({
    Key? key, 
    this.rentedRoomId,
    this.inAppWallet = false,
    this.isLandlordDashboard = false,
  }) : super(key: key);

  @override
  _PaymentInputScreenState createState() => _PaymentInputScreenState();
}

class _PaymentInputScreenState extends State<PaymentInputScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  String get productName => widget.inAppWallet 
      ? "Nạp tiền vào ví" 
      : "Nộp tiền phòng";
      
  String get description => widget.inAppWallet 
      ? "Nạp tiền vào ví ứng dụng" 
      : "Nộp tiền vào ví phòng";
  
  // Các mức giá đề xuất sẽ được tính động dựa trên input
  List<int> _suggestedAmounts = [];
  int? selectedAmount;

  @override
  void initState() {
    super.initState();
    
    // Validate that rentedRoomId is provided when not using inAppWallet
    if (!widget.inAppWallet && (widget.rentedRoomId == null || widget.rentedRoomId!.isEmpty)) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Không tìm thấy thông tin phòng'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
    }
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
    
    // Lắng nghe thay đổi input để tạo suggestions
    _amountController.addListener(_updateSuggestedAmounts);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateSuggestedAmounts);
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateSuggestedAmounts() {
    String text = _amountController.text.trim();
    
    if (text.isEmpty) {
      setState(() {
        _suggestedAmounts = [];
      });
      return;
    }
    
    try {
      // Chuyển đổi input sang số
      int inputAmount = int.tryParse(text) ?? 0;
      if (inputAmount <= 0) {
        setState(() {
          _suggestedAmounts = [];
        });
        return;
      }
      
      // Tính số chữ số của input
      int numberOfDigits = text.length;
      
      // Tạo 3 mức đề xuất dựa trên input
      List<int> suggestions = [];
      
      // Mức 1: Input * 10
      if (inputAmount * 10 <= 1000000000) { // Giới hạn 1 tỷ
        suggestions.add(inputAmount * 10);
      }
      
      // Mức 2: Input * 100
      if (inputAmount * 100 <= 1000000000) {
        suggestions.add(inputAmount * 100);
      }
      
      // Mức 3: Input * 1000
      if (inputAmount * 1000 <= 1000000000) {
        suggestions.add(inputAmount * 1000);
      }
      
      // Nếu có ít hơn 3 mức, thêm mức cố định
      if (suggestions.length < 3) {
        if (!suggestions.contains(500000) && 500000 > inputAmount) {
          suggestions.add(500000);
        }
        if (suggestions.length < 3 && !suggestions.contains(1000000) && 1000000 > inputAmount) {
          suggestions.add(1000000);
        }
        if (suggestions.length < 3 && !suggestions.contains(2000000) && 2000000 > inputAmount) {
          suggestions.add(2000000);
        }
      }
      
      // Sắp xếp theo thứ tự tăng dần
      suggestions.sort();
      
      setState(() {
        _suggestedAmounts = suggestions;
      });
    } catch (e) {
      setState(() {
        _suggestedAmounts = [];
      });
    }
  }

  void _selectAmount(int amount) {
    setState(() {
      selectedAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  void _requestPaymentInfo(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = int.tryParse(_amountController.text.trim());
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
        );
        return;
      }

      final paymentRequest = PaymentRequest(
        productName: productName,
        description: description,
        rentedRoomId: widget.rentedRoomId ?? "",
        amount: amount,
        inAppWallet: widget.inAppWallet,
      );

      final paymentCubit = context.read<PaymentCubit>();
      
      // Thực hiện tạo yêu cầu thanh toán
      paymentCubit.createPayment(paymentRequest: paymentRequest).then((_) {
        // Khi thành công, kiểm tra trạng thái hiện tại
        final currentState = paymentCubit.state;
        if (currentState is PaymentResponseSuccess) {
          // Chuyển hướng sang màn hình QR
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentQRScreen(
                paymentResponse: currentState.paymentResponse,
                inAppWallet: widget.inAppWallet,
                isLandlordDashboard: widget.isLandlordDashboard,
              ),
            ),
          ).then((value) {
            // Khi quay lại từ màn hình QR, truyền kết quả về màn hình trước
            Navigator.pop(context, value);
          });
        }
      });
    }
  }

  Widget _buildPaymentForm(PaymentResponseState state) {
    final Color mainColor = widget.inAppWallet ? Colors.blue : Colors.teal;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với logo và tên
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.inAppWallet ? Icons.account_balance_wallet : Icons.home,
                          color: mainColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Input số tiền với thiết kế hiện đại
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: mainColor,
                          size: 28,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          color: Colors.grey[400],
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        if (int.tryParse(value.trim()) == null) {
                          return 'Số tiền không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Các mức giá đề xuất - chỉ hiển thị khi có đề xuất
                  if (_suggestedAmounts.isNotEmpty) ...[
                    const Text(
                      'Mức giá đề xuất',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _suggestedAmounts.map((amount) {
                        final isSelected = selectedAmount == amount;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => _selectAmount(amount),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? mainColor.withOpacity(0.1) : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? mainColor : Colors.grey[200]!,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      currencyFormat.format(amount),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? mainColor : Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(amount / 1000000).toStringAsFixed(1)}M',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? mainColor : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Nút lấy thông tin thanh toán
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: state is PaymentResponseLoading
                          ? null
                          : () => _requestPaymentInfo(context),
                      child: state is PaymentResponseLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Lấy thông tin thanh toán',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = widget.inAppWallet ? Colors.blue : Colors.teal;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        title: Text(
          widget.inAppWallet ? 'Nạp Tiền Ví' : 'Thanh Toán',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            widget.isLandlordDashboard ? Navigator.pop(context, true) : Navigator.pop(context, false);
          }
        ),
      ),
      body: BlocConsumer<PaymentCubit, PaymentResponseState>(
        listener: (context, state) {
          if (state is PaymentResponseFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể tạo thông tin thanh toán: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildPaymentForm(state),
          );
        },
      ),
    );
  }
} 