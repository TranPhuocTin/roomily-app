import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomily/data/blocs/contract/contract_cubit.dart';
import 'package:roomily/data/models/landlord_contract_info.dart';
import 'package:roomily/data/repositories/contract_repository.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
/// Screen for editing landlord contract information
class EditLandlordInfoScreen extends StatefulWidget {
  final LandlordContractInfo? initialInfo;

  /// Constructor for [EditLandlordInfoScreen]
  const EditLandlordInfoScreen({
    Key? key,
    this.initialInfo,
  }) : super(key: key);

  @override
  State<EditLandlordInfoScreen> createState() => _EditLandlordInfoScreenState();
}

class _EditLandlordInfoScreenState extends State<EditLandlordInfoScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _fullNameController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _permanentResidenceController;
  late TextEditingController _identityNumberController;
  late TextEditingController _identityProvidedDateController;
  late TextEditingController _identityProvidedPlaceController;
  late TextEditingController _phoneNumberController;
  late ContractCubit _contractCubit;
  bool _isLoading = false;
  bool _isDirty = false;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedIdentityDate;
  final _formKey = GlobalKey<FormState>();
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentStep = 0;

  // App colors
  late Color primaryColor;
  late Color secondaryColor;
  late Color lightBlue;
  late Color darkGray;
  late Color accentColor;

  @override
  void initState() {
    super.initState();
    
    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    
    // Initialize colors
    primaryColor = const Color(0xFF0075FF);
    secondaryColor = const Color(0xFF00D1FF);
    lightBlue = const Color(0xFFE6F4FF);
    darkGray = const Color(0xFF424242);
    accentColor = const Color(0xFFFFB300);
    
    // Initialize controllers
    _fullNameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _permanentResidenceController = TextEditingController();
    _identityNumberController = TextEditingController();
    _identityProvidedDateController = TextEditingController();
    _identityProvidedPlaceController = TextEditingController();
    _phoneNumberController = TextEditingController();
    
    _contractCubit = ContractCubit(repository: GetIt.I<ContractRepository>());
    
    // If we have initial info, fill the controllers
    if (widget.initialInfo != null) {
      _fillControllersWithInitialInfo();
    } else {
      // Otherwise, fetch the info from the API
      _loadLandlordInfo();
    }
    
    // Add listeners to detect changes
    _fullNameController.addListener(_markAsDirty);
    _dateOfBirthController.addListener(_markAsDirty);
    _permanentResidenceController.addListener(_markAsDirty);
    _identityNumberController.addListener(_markAsDirty);
    _identityProvidedDateController.addListener(_markAsDirty);
    _identityProvidedPlaceController.addListener(_markAsDirty);
    _phoneNumberController.addListener(_markAsDirty);
  }
  
  void _fillControllersWithInitialInfo() {
    final info = widget.initialInfo!;
    _fullNameController.text = info.landlordFullName;
    _dateOfBirthController.text = info.landlordDateOfBirth;
    _permanentResidenceController.text = info.landlordPermanentResidence;
    _identityNumberController.text = info.landlordIdentityNumber;
    _identityProvidedDateController.text = info.landlordIdentityProvidedDate;
    _identityProvidedPlaceController.text = info.landlordIdentityProvidedPlace;
    _phoneNumberController.text = info.landlordPhoneNumber;
    
    // Try to parse dates
    try {
      _selectedDateOfBirth = DateFormat('yyyy-MM-dd').parse(info.landlordDateOfBirth);
    } catch (e) {
      debugPrint('Error parsing date of birth: $e');
    }
    
    try {
      _selectedIdentityDate = DateFormat('yyyy-MM-dd').parse(info.landlordIdentityProvidedDate);
    } catch (e) {
      debugPrint('Error parsing identity provided date: $e');
    }
  }
  
  Future<void> _loadLandlordInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final info = await _contractCubit.getLandlordInfo();
      
      if (info != null && mounted) {
        _fullNameController.text = info.landlordFullName;
        _dateOfBirthController.text = info.landlordDateOfBirth;
        _permanentResidenceController.text = info.landlordPermanentResidence;
        _identityNumberController.text = info.landlordIdentityNumber;
        _identityProvidedDateController.text = info.landlordIdentityProvidedDate;
        _identityProvidedPlaceController.text = info.landlordIdentityProvidedPlace;
        _phoneNumberController.text = info.landlordPhoneNumber;
        
        // Try to parse dates
        try {
          _selectedDateOfBirth = DateFormat('yyyy-MM-dd').parse(info.landlordDateOfBirth);
        } catch (e) {
          debugPrint('Error parsing date of birth: $e');
        }
        
        try {
          _selectedIdentityDate = DateFormat('yyyy-MM-dd').parse(info.landlordIdentityProvidedDate);
        } catch (e) {
          debugPrint('Error parsing identity provided date: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải thông tin: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _markAsDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }
  
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: darkGray,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
        _markAsDirty();
      });
    }
  }
  
  Future<void> _selectIdentityProvidedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedIdentityDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: darkGray,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedIdentityDate = picked;
        _identityProvidedDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _markAsDirty();
      });
    }
  }
  
  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin hợp lệ'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Show confirmation dialog
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn lưu thông tin này vào hợp đồng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('LƯU'),
          ),
        ],
      ),
    );
    
    if (shouldSave != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final info = LandlordContractInfo(
        landlordFullName: _fullNameController.text,
        landlordDateOfBirth: _dateOfBirthController.text,
        landlordPermanentResidence: _permanentResidenceController.text,
        landlordIdentityNumber: _identityNumberController.text,
        landlordIdentityProvidedDate: _identityProvidedDateController.text,
        landlordIdentityProvidedPlace: _identityProvidedPlaceController.text,
        landlordPhoneNumber: _phoneNumberController.text,
      );
      
      final success = await _contractCubit.updateLandlordInfo(info);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isDirty = false;
        });
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật thông tin'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật thông tin: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<bool> _onWillPop() async {
    if (!_isDirty) {
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có thay đổi chưa lưu. Bạn có chắc chắn muốn thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('THOÁT'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _permanentResidenceController.dispose();
    _identityNumberController.dispose();
    _identityProvidedDateController.dispose();
    _identityProvidedPlaceController.dispose();
    _phoneNumberController.dispose();
    _animationController.dispose();
    _contractCubit.close();
    super.dispose();
  }

  // Get current form completeness percentage
  double get _formCompleteness {
    int totalFields = 7; // Total number of required fields
    int completedFields = 0;
    
    if (_fullNameController.text.isNotEmpty) completedFields++;
    if (_dateOfBirthController.text.isNotEmpty) completedFields++;
    if (_permanentResidenceController.text.isNotEmpty) completedFields++;
    if (_identityNumberController.text.isNotEmpty) completedFields++;
    if (_identityProvidedDateController.text.isNotEmpty) completedFields++;
    if (_identityProvidedPlaceController.text.isNotEmpty) completedFields++;
    if (_phoneNumberController.text.isNotEmpty) completedFields++;
    
    return completedFields / totalFields;
  }
  
  @override
  Widget build(BuildContext context) {
    final List<Step> steps = [
      Step(
        title: const Text('Thông tin cá nhân'),
        content: _buildPersonalInfoSection(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Thông tin CMND/CCCD'),
        content: _buildIdentitySection(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Thông tin liên hệ'),
        content: _buildContactSection(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin chủ nhà', style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          )),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
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
          ),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            if (_isDirty)
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.white),
                      onPressed: _isLoading ? null : _saveInfo,
                    ),
                    if (_isDirty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang tải dữ liệu...',
                      style: TextStyle(
                        color: darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lightBlue.withOpacity(0.3),
                      Colors.white,
                    ],
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Progress indicator
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tiến độ hoàn thành',
                                    style: TextStyle(
                                      color: darkGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${(_formCompleteness * 100).toInt()}%',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _formCompleteness,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                borderRadius: BorderRadius.circular(10),
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ),
                        
                        // Stepper or scrollable form based on screen size
                        MediaQuery.of(context).size.width > 600
                            ? Expanded(
                                child: Stepper(
                                  type: StepperType.horizontal,
                                  currentStep: _currentStep,
                                  onStepTapped: (step) {
                                    setState(() {
                                      _currentStep = step;
                                    });
                                  },
                                  onStepContinue: () {
                                    if (_currentStep < steps.length - 1) {
                                      setState(() {
                                        _currentStep += 1;
                                      });
                                    } else {
                                      _saveInfo();
                                    }
                                  },
                                  onStepCancel: () {
                                    if (_currentStep > 0) {
                                      setState(() {
                                        _currentStep -= 1;
                                      });
                                    }
                                  },
                                  steps: steps,
                                  controlsBuilder: (context, details) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Row(
                                        children: [
                                          if (_currentStep > 0)
                                            TextButton(
                                              onPressed: details.onStepCancel,
                                              child: const Text('QUAY LẠI'),
                                            ),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: details.onStepContinue,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                              elevation: 2,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            ),
                                            child: Text(
                                              _currentStep < steps.length - 1 ? 'TIẾP TỤC' : 'HOÀN THÀNH',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Form explanation
                                      _buildInfoCard(),
                                      const SizedBox(height: 24),
                                      
                                      // Personal information section
                                      _buildSectionHeader('THÔNG TIN CÁ NHÂN'),
                                      const SizedBox(height: 16),
                                      _buildPersonalInfoSection(),
                                      const SizedBox(height: 24),
                                      
                                      // Identity information section
                                      _buildSectionHeader('THÔNG TIN CMND/CCCD'),
                                      const SizedBox(height: 16),
                                      _buildIdentitySection(),
                                      const SizedBox(height: 24),
                                      
                                      // Contact information section
                                      _buildSectionHeader('THÔNG TIN LIÊN HỆ'),
                                      const SizedBox(height: 16),
                                      _buildContactSection(),
                                      const SizedBox(height: 32),
                                      
                                      // Save button
                                      _buildSaveButton(),
                                      const SizedBox(height: 16),
                                    ],
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
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              lightBlue,
              lightBlue.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thông tin chủ nhà trong hợp đồng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Thông tin này sẽ được hiển thị trong tất cả hợp đồng của bạn. Hãy điền chính xác các thông tin để đảm bảo hợp đồng hợp lệ.',
              style: TextStyle(color: darkGray, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Full name field
            _buildInputField(
              controller: _fullNameController,
              label: 'Họ và tên',
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Date of birth field with date picker
            _buildDateField(
              controller: _dateOfBirthController,
              label: 'Ngày sinh',
              prefixIcon: Icons.calendar_today,
              onTap: () => _selectDateOfBirth(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn ngày sinh';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Permanent residence field
            _buildInputField(
              controller: _permanentResidenceController,
              label: 'Nơi đăng ký hộ khẩu thường trú',
              prefixIcon: Icons.home,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập nơi đăng ký hộ khẩu thường trú';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIdentitySection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Identity number field
            _buildInputField(
              controller: _identityNumberController,
              label: 'Số CMND/CCCD',
              prefixIcon: Icons.badge,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số CMND/CCCD';
                }
                if (value.length < 9 || value.length > 12) {
                  return 'Số CMND/CCCD không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Identity provided date field
            _buildDateField(
              controller: _identityProvidedDateController,
              label: 'Ngày cấp',
              prefixIcon: Icons.date_range,
              onTap: () => _selectIdentityProvidedDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn ngày cấp';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Identity provided place field
            _buildInputField(
              controller: _identityProvidedPlaceController,
              label: 'Nơi cấp',
              prefixIcon: Icons.location_city,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập nơi cấp';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Phone number field
            _buildInputField(
              controller: _phoneNumberController,
              label: 'Số điện thoại',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (value.length < 10 || value.length > 11) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        prefixIcon: Icon(prefixIcon, color: darkGray.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
  
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        prefixIcon: Icon(prefixIcon, color: darkGray.withOpacity(0.7)),
        suffixIcon: Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.calendar_month, color: primaryColor),
            onPressed: onTap,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
      onTap: onTap,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
  
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveInfo,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save),
                  const SizedBox(width: 8),
                  Text(
                    'LƯU THÔNG TIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 