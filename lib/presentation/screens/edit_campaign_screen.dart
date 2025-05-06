import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/models/campaign_create_model.dart';
import 'package:roomily/data/models/campaign_model.dart';
import 'package:roomily/data/blocs/campaigns/campaigns_cubit.dart';
import 'package:roomily/data/blocs/campaigns/campaigns_state.dart';
import 'package:roomily/data/repositories/ad_repository.dart';

class EditCampaignScreen extends StatelessWidget {
  final CampaignModel campaign;
  
  const EditCampaignScreen({Key? key, required this.campaign}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CampaignsCubit(adRepository: GetIt.instance<AdRepository>()),
      child: _EditCampaignView(campaign: campaign),
    );
  }
}

class _EditCampaignView extends StatefulWidget {
  final CampaignModel campaign;
  
  const _EditCampaignView({Key? key, required this.campaign}) : super(key: key);

  @override
  State<_EditCampaignView> createState() => _EditCampaignViewState();
}

class _EditCampaignViewState extends State<_EditCampaignView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  late TextEditingController _dailyBudgetController;
  late TextEditingController _cpmRateController;
  
  late String _pricingModel;
  late DateTime _startDate;
  late DateTime _endDate;
  
  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color backgroundColor = const Color(0xFFF8FAFF);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);
  final Color accentGreen = const Color(0xFF00C897);
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.campaign.name);
    _budgetController = TextEditingController(text: widget.campaign.budget.toString());
    _dailyBudgetController = TextEditingController(text: widget.campaign.dailyBudget.toString());
    _cpmRateController = TextEditingController(text: "0"); // Default CPM rate
    _pricingModel = 'CPC'; // Default to CPC pricing model
    _startDate = widget.campaign.startDate;
    _endDate = widget.campaign.endDate;
  }
  
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
      body: BlocListener<CampaignsCubit, CampaignsState>(
        listener: (context, state) {
          if (state is UpdateCampaignSuccess) {
            _showSuccessSnackbar('Đã cập nhật chiến dịch thành công');
            // Thêm delay trước khi pop màn hình để đảm bảo state được xử lý xong
            Future.delayed(const Duration(milliseconds: 200), () {
              Navigator.pop(context, true); // Thêm result để biết là cập nhật thành công
            });
          } else if (state is UpdateCampaignError) {
            _showErrorSnackbar('Cập nhật chiến dịch thất bại: ${state.message}');
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCampaignInfoSection(),
                      const SizedBox(height: 24),
                      _buildBudgetSection(),
                      const SizedBox(height: 40),
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
                    'Chỉnh sửa chiến dịch',
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
                    key: ValueKey(_startDate),
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
                    key: ValueKey(_endDate),
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
        if (_pricingModel == 'CPM')
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
                  if (_pricingModel != 'CPM') return null;
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
    Key? key,
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
          key: key,
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
    final minDate = isStart ? DateTime(2020) : _startDate;
    final maxDate = DateTime.now().add(const Duration(days: 365 * 5));
    
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
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked.isBefore(_startDate) ? _startDate.add(const Duration(days: 1)) : picked;
        }
      });
    }
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<CampaignsCubit, CampaignsState>(
      builder: (context, state) {
        final isLoading = state is UpdatingCampaign && state.campaignId == widget.campaign.id;
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
            onPressed: isLoading ? null : _submitForm,
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
                    'Cập nhật chiến dịch',
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final campaignData = CampaignCreateModel(
        name: _nameController.text,
        pricingModel: _pricingModel,
        cpmRate: _pricingModel == 'CPM' ? double.parse(_cpmRateController.text) : null,
        budget: double.parse(_budgetController.text),
        dailyBudget: double.parse(_dailyBudgetController.text),
        startDate: _formatDateToIsoUtc(_startDate),
        endDate: _formatDateToIsoUtc(_endDate),
      );
      
      context.read<CampaignsCubit>().updateCampaign(widget.campaign.id, campaignData);
    }
  }

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
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
            Expanded(
              child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis)
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF456C),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

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
          _pricingModel == 'CPC' 
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
    final isSelected = _pricingModel == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _pricingModel = value;
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