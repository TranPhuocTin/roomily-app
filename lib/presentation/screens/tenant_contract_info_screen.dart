import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/blocs/contract/contract_cubit.dart';
import 'package:roomily/data/models/tenant_contract_info.dart';
import 'package:roomily/data/repositories/contract_repository_impl.dart';

import '../../data/blocs/contract/contract_state.dart';

class TenantContractInfoScreen extends StatefulWidget {
  final String roomId;

  const TenantContractInfoScreen({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  State<TenantContractInfoScreen> createState() => _TenantContractInfoScreenState();
}

class _TenantContractInfoScreenState extends State<TenantContractInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late ContractCubit _contractCubit;

  // Defining the primary green color to be used throughout the screen
  final Color _primaryGreen = Colors.green;

  // Text controllers
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _residenceController = TextEditingController();
  final _identityNumberController = TextEditingController();
  final _identityDateController = TextEditingController();
  final _identityPlaceController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isLoading = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _contractCubit = ContractCubit(repository: ContractRepositoryImpl());
    _loadTenantInfo();
  }

  Future<void> _loadTenantInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final tenantInfo = await _contractCubit.getTenantInfo(widget.roomId);
      
      if (tenantInfo != null) {
        _fullNameController.text = tenantInfo.tenantFullName;
        _dateOfBirthController.text = tenantInfo.tenantDateOfBirth;
        _residenceController.text = tenantInfo.tenantPermanentResidence;
        _identityNumberController.text = tenantInfo.tenantIdentityNumber;
        _identityDateController.text = tenantInfo.tenantIdentityProvidedDate;
        _identityPlaceController.text = tenantInfo.tenantIdentityProvidedPlace;
        _phoneNumberController.text = tenantInfo.tenantPhoneNumber;

        _dataLoaded = true;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tenantInfo = TenantContractInfo(
        rentedRoomId: widget.roomId,
        tenantFullName: _fullNameController.text,
        tenantDateOfBirth: _dateOfBirthController.text,
        tenantPermanentResidence: _residenceController.text,
        tenantIdentityNumber: _identityNumberController.text,
        tenantIdentityProvidedDate: _identityDateController.text,
        tenantIdentityProvidedPlace: _identityPlaceController.text,
        tenantPhoneNumber: _phoneNumberController.text,
      );

      final success = await _contractCubit.updateTenantInfo(tenantInfo);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Cập nhật thông tin thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryGreen,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _residenceController.dispose();
    _identityNumberController.dispose();
    _identityDateController.dispose();
    _identityPlaceController.dispose();
    _phoneNumberController.dispose();
    _contractCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin người thuê'),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocConsumer<ContractCubit, ContractState>(
        bloc: _contractCubit,
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
          if (_isLoading || state is ContractLoading) {
            return Center(child: CircularProgressIndicator(color: _primaryGreen));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _primaryGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_document, color: _primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Thông tin này sẽ được sử dụng để điền vào hợp đồng. Vui lòng cung cấp thông tin chính xác.',
                            style: TextStyle(color: _primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Full name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: _inputDecoration(
                      'Họ và tên',
                      'Nhập họ và tên đầy đủ',
                      Icons.person,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Date of birth
                  GestureDetector(
                    onTap: () => _selectDate(_dateOfBirthController),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dateOfBirthController,
                        decoration: _inputDecoration(
                          'Ngày sinh',
                          'YYYY-MM-DD',
                          Icons.calendar_today,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn ngày sinh';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Permanent residence
                  TextFormField(
                    controller: _residenceController,
                    decoration: _inputDecoration(
                      'Địa chỉ thường trú',
                      'Nhập địa chỉ thường trú',
                      Icons.home,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa chỉ thường trú';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Identity number
                  TextFormField(
                    controller: _identityNumberController,
                    decoration: _inputDecoration(
                      'Số CMND/CCCD',
                      'Nhập số CMND/CCCD',
                      Icons.credit_card,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số CMND/CCCD';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Identity provided date
                  GestureDetector(
                    onTap: () => _selectDate(_identityDateController),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _identityDateController,
                        decoration: _inputDecoration(
                          'Ngày cấp',
                          'YYYY-MM-DD',
                          Icons.calendar_today,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn ngày cấp';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Identity provided place
                  TextFormField(
                    controller: _identityPlaceController,
                    decoration: _inputDecoration(
                      'Nơi cấp',
                      'Nhập nơi cấp',
                      Icons.location_city,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập nơi cấp';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Phone number
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: _inputDecoration(
                      'Số điện thoại',
                      'Nhập số điện thoại',
                      Icons.phone,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Lưu thông tin',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primaryGreen),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _primaryGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      fillColor: Colors.white,
      filled: true,
    );
  }
} 