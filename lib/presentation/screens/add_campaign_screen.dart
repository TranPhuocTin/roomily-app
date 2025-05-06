import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/models/campaign_create_model.dart';
import 'package:roomily/data/blocs/add_campaign/add_campaign_cubit.dart';
import 'package:roomily/data/blocs/add_campaign/add_campaign_state.dart';
import 'package:roomily/data/repositories/ad_repository.dart';

class AddCampaignScreen extends StatelessWidget {
  const AddCampaignScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddCampaignCubit(adRepository: GetIt.instance<AdRepository>()), // Tạo mới thay vì lấy từ GetIt
      child: const _AddCampaignView(),
    );
  }
}

class _AddCampaignView extends StatefulWidget {
  const _AddCampaignView({Key? key}) : super(key: key);

  @override
  State<_AddCampaignView> createState() => _AddCampaignViewState();
}

class _AddCampaignViewState extends State<_AddCampaignView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _dailyBudgetController = TextEditingController();
  final _cpmRateController = TextEditingController();
  
  String _selectedPricingModel = 'CPC'; // Default pricing model
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  
  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color backgroundColor = const Color(0xFFF8FAFF);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);
  final Color accentGreen = const Color(0xFF00C897);
  
  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _dailyBudgetController.dispose();
    _cpmRateController.dispose();
    super.dispose();
  }

  // Helper to format DateTime to ISO 8601 UTC string
  String _formatDateToIsoUtc(DateTime date) {
    // Ensure it's treated as UTC before formatting
    final utcDate = DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour, 
      date.minute, 
      date.second, 
      date.millisecond
    );
    return DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(utcDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildGradientAppBar(),
      body: BlocListener<AddCampaignCubit, AddCampaignState>(
        listener: (context, state) {
          if (state is AddCampaignSuccess) {
            _showSuccessSnackbar('Đã tạo chiến dịch quảng cáo thành công');
            // Pop màn hình ngay lập tức thay vì đợi delay
            Navigator.pop(context);
          } else if (state is AddCampaignFailure) {
            _showErrorSnackbar('Tạo chiến dịch thất bại: ${state.error}');
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildStepIndicator(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCampaignInfoSection(),
                      const SizedBox(height: 24),
                      _buildBudgetSection(),
                      const SizedBox(height: 24),
                      // _buildRoomSelectionSection(),
                      // const SizedBox(height: 40),
                      _buildSubmitButton(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const BackButton(color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Tạo chiến dịch mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStepItem(number: 1, title: "Thông tin", isActive: true, isCompleted: true),
          _buildStepConnector(isActive: true),
          _buildStepItem(number: 2, title: "Ngân sách", isActive: true, isCompleted: true),
          _buildStepConnector(isActive: true),
          _buildStepItem(number: 3, title: "Phòng", isActive: true, isCompleted: false),
        ],
      ),
    );
  }

  Widget _buildStepItem({ 
    required int number, 
    required String title, 
    required bool isActive, 
    required bool isCompleted
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ) : null,
              color: isActive ? null : const Color(0xFFE5EFFF),
            ),
            child: Center(
              child: isCompleted 
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    number.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : textSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isActive ? textPrimaryColor : textSecondaryColor,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isActive}) {
    return Container(
      width: 40,
      height: 1,
      color: isActive ? primaryColor : const Color(0xFFE5EFFF),
    );
  }

  Widget _buildCampaignInfoSection() {
    return _buildFormSection(
      title: 'Thông tin chiến dịch',
      icon: Icons.campaign_outlined,
      children: [
        _buildInputField(
          controller: _nameController,
          label: 'Tên chiến dịch',
          hint: 'Nhập tên chiến dịch, ví dụ: Quảng cáo mùa hè',
          prefixIcon: Icons.drive_file_rename_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tên chiến dịch';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, isStart: true),
                child: AbsorbPointer(
                  child: _buildInputField(
                    key: ValueKey(_startDate), // Add key to force update on date change
                    initialValue: DateFormat('dd/MM/yyyy').format(_startDate),
                    label: 'Ngày bắt đầu',
                    prefixIcon: Icons.event,
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng chọn ngày bắt đầu';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, isStart: false),
                child: AbsorbPointer(
                  child: _buildInputField(
                    key: ValueKey(_endDate), // Add key to force update on date change
                    initialValue: DateFormat('dd/MM/yyyy').format(_endDate),
                    label: 'Ngày kết thúc',
                    prefixIcon: Icons.event_available,
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng chọn ngày kết thúc';
                      }
                      // Add validation: end date must be after start date
                      if (_endDate.isBefore(_startDate)) {
                        return 'Ngày kết thúc phải sau ngày bắt đầu';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return _buildFormSection(
      title: 'Ngân sách',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _buildPricingModelSelection(),
        const SizedBox(height: 24),
        if (_selectedPricingModel == 'CPM')
          Column(
            children: [
              _buildInputField(
                controller: _cpmRateController,
                label: 'Giá CPM',
                hint: 'Ví dụ: 10000',
                prefixIcon: Icons.price_change_outlined,
                keyboardType: TextInputType.number,
                suffixText: 'VND',
                validator: (value) {
                  if (_selectedPricingModel != 'CPM') return null;
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá CPM';
                  }
                  final cpmRate = double.tryParse(value);
                  if (cpmRate == null || cpmRate <= 0) {
                    return 'Giá CPM phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        _buildInputField(
          controller: _budgetController,
          label: 'Tổng ngân sách',
          hint: 'Ví dụ: 2000000',
          prefixIcon: Icons.monetization_on_outlined,
          keyboardType: TextInputType.number,
          suffixText: 'VND',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tổng ngân sách';
            }
            final budget = double.tryParse(value);
            if (budget == null || budget <= 0) {
              return 'Ngân sách phải là số dương';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildInputField(
          controller: _dailyBudgetController,
          label: 'Ngân sách hàng ngày',
          hint: 'Ví dụ: 100000',
          prefixIcon: Icons.today_outlined,
          keyboardType: TextInputType.number,
          suffixText: 'VND',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập ngân sách hàng ngày';
            }
            final dailyBudget = double.tryParse(value);
            if (dailyBudget == null || dailyBudget <= 0) {
              return 'Ngân sách phải là số dương';
            }
            final totalBudget = double.tryParse(_budgetController.text);
            if (totalBudget != null && dailyBudget > totalBudget) {
              return 'Ngân sách hàng ngày không thể vượt quá tổng ngân sách';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDFE6F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tips_and_updates_outlined, size: 16, color: accentGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi ý',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ngân sách hàng ngày nên là 1/30 của tổng ngân sách để tối ưu hiệu quả',
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildRoomSelectionSection() {
  //   return _buildFormSection(
  //     title: 'Chọn phòng để quảng cáo',
  //     icon: Icons.home_work_outlined,
  //     children: [
  //       Container(
  //         margin: const EdgeInsets.only(bottom: 16),
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF5F8FF),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Row(
  //           children: [
  //             Icon(Icons.info_outline, size: 16, color: primaryColor),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Text(
  //                 'Chọn phòng bạn muốn quảng cáo. Phòng được chọn sẽ hiển thị ưu tiên trong kết quả tìm kiếm.',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   color: textSecondaryColor,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildFormSection({ 
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({ 
    Key? key, // Add key parameter
    TextEditingController? controller,
    String? initialValue,
    required String label,
    String? hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: key, // Use key
          controller: controller,
          initialValue: initialValue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: textSecondaryColor.withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(prefixIcon, color: textSecondaryColor, size: 20),
            suffixText: suffixText,
            suffixStyle: TextStyle(
              color: textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F8FF),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFEFF3FA), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF456C), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF456C), width: 1),
            ),
          ),
          style: TextStyle(
            color: textPrimaryColor,
            fontSize: 14,
          ),
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    // Allow selecting past dates for start if needed, but usually campaigns start now or later
    // final minDate = isStart ? DateTime.now().subtract(Duration(days: 365)) : _startDate;
    final minDate = isStart ? DateTime(2020) : _startDate; // Allow start date from 2020
    final maxDate = DateTime.now().add(const Duration(days: 365 * 5)); // Allow up to 5 years in future
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(minDate) && initialDate.isBefore(maxDate) 
                   ? initialDate 
                   : (isStart ? DateTime.now() : _startDate.add(Duration(days: 1))),
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textPrimaryColor, 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, 
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // If end date is now before start date, adjust end date (e.g., 7 days after start)
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          // Ensure end date is not before start date
          _endDate = picked.isBefore(_startDate) ? _startDate.add(const Duration(days: 1)) : picked;
        }
      });
    }
  }

  // --- Submit Button with Loading State ---
  Widget _buildSubmitButton() {
    return BlocBuilder<AddCampaignCubit, AddCampaignState>(
      builder: (context, state) {
        final isLoading = state is AddCampaignLoading;
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitForm, // Disable button when loading
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: primaryColor,
              disabledBackgroundColor: primaryColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                  )
                : const Text(
                    'Tạo chiến dịch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  // --- Updated Submit Logic ---
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Optional: Check if at least one room is selected if that becomes a requirement later
      // final selectedRoomsCount = _mockRooms.where((room) => room['isSelected'] == true).length;
      // if (selectedRoomsCount == 0) {
      //   _showErrorSnackbar('Vui lòng chọn ít nhất một phòng để quảng cáo');
      //   return;
      // }
      
      final campaignData = CampaignCreateModel(
        name: _nameController.text,
        pricingModel: _selectedPricingModel,
        cpmRate: _selectedPricingModel == 'CPM' ? double.parse(_cpmRateController.text) : null,
        budget: double.parse(_budgetController.text),
        dailyBudget: double.parse(_dailyBudgetController.text),
        startDate: _formatDateToIsoUtc(_startDate),
        endDate: _formatDateToIsoUtc(_endDate),
      );
      
      context.read<AddCampaignCubit>().createCampaign(campaignData);
    }
  }

  // --- Snackbar Helpers (Keep the existing ones) ---
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: accentGreen, size: 16),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: accentGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Color(0xFFFF456C), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded( // Allow text wrapping
              child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis)
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF456C),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Add pricing model selection widget
  Widget _buildPricingModelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình thức tính phí',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEFF3FA), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildPricingModelOption('CPC', 'Trả phí theo click'),
              ),
              Expanded(
                child: _buildPricingModelOption('CPM', 'Trả phí theo hiển thị'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedPricingModel == 'CPC' 
              ? 'Bạn sẽ trả phí mỗi khi có người click vào quảng cáo phòng của bạn'
              : 'Bạn sẽ trả phí mỗi khi quảng cáo phòng của bạn được hiển thị',
          style: TextStyle(
            fontSize: 12,
            color: textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingModelOption(String value, String label) {
    final isSelected = _selectedPricingModel == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPricingModel = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: primaryColor, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? primaryColor : textSecondaryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isSelected
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}