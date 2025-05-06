import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomily/data/models/contract_responsibilities.dart';
import 'package:roomily/data/models/contract_modify_request.dart';
import 'package:roomily/data/blocs/contract/contract_cubit.dart';
import 'package:roomily/data/repositories/contract_repository.dart';
import 'package:get_it/get_it.dart';

/// Screen for editing contract responsibilities
class EditResponsibilitiesScreen extends StatefulWidget {
  final String roomId;
  final ContractResponsibilities initialResponsibilities;

  /// Constructor for [EditResponsibilitiesScreen]
  const EditResponsibilitiesScreen({
    Key? key,
    required this.roomId,
    required this.initialResponsibilities,
  }) : super(key: key);

  @override
  State<EditResponsibilitiesScreen> createState() => _EditResponsibilitiesScreenState();
}

class _EditResponsibilitiesScreenState extends State<EditResponsibilitiesScreen> with SingleTickerProviderStateMixin {
  late List<TextEditingController> _responsibilitiesAControllers;
  late List<TextEditingController> _responsibilitiesBControllers;
  late List<TextEditingController> _commonResponsibilitiesControllers;
  late ContractCubit _contractCubit;
  late TabController _tabController;
  bool _isLoading = false;
  bool _isDirty = false;

  // App colors
  late Color primaryColor;
  late Color secondaryColor;
  late Color lightBlue;
  late Color accentColor;
  late Color darkGray;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      FocusScope.of(context).unfocus();
    });
    
    // Initialize controllers with existing data
    _responsibilitiesAControllers = widget.initialResponsibilities.responsibilitiesA
        .map((item) => TextEditingController(text: item))
        .toList();
    
    _responsibilitiesBControllers = widget.initialResponsibilities.responsibilitiesB
        .map((item) => TextEditingController(text: item))
        .toList();
    
    _commonResponsibilitiesControllers = widget.initialResponsibilities.commonResponsibilities
        .map((item) => TextEditingController(text: item))
        .toList();
    
    // Add empty controllers if lists are empty
    if (_responsibilitiesAControllers.isEmpty) {
      _responsibilitiesAControllers.add(TextEditingController());
    }
    
    if (_responsibilitiesBControllers.isEmpty) {
      _responsibilitiesBControllers.add(TextEditingController());
    }
    
    if (_commonResponsibilitiesControllers.isEmpty) {
      _commonResponsibilitiesControllers.add(TextEditingController());
    }
    
    _contractCubit = ContractCubit(repository: GetIt.I<ContractRepository>());

    // Add listeners to detect changes
    for (var controller in [..._responsibilitiesAControllers, ..._responsibilitiesBControllers, ..._commonResponsibilitiesControllers]) {
      controller.addListener(_markAsDirty);
    }
  }

  void _markAsDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _responsibilitiesAControllers) {
      controller.dispose();
    }
    
    for (var controller in _responsibilitiesBControllers) {
      controller.dispose();
    }
    
    for (var controller in _commonResponsibilitiesControllers) {
      controller.dispose();
    }
    
    _tabController.dispose();
    _contractCubit.close();
    super.dispose();
  }

  void _addResponsibilityA() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(_markAsDirty);
      _responsibilitiesAControllers.add(controller);
      _isDirty = true;
    });
  }

  void _removeResponsibilityA(int index) {
    if (_responsibilitiesAControllers.length > 1) {
      setState(() {
        _responsibilitiesAControllers[index].dispose();
        _responsibilitiesAControllers.removeAt(index);
        _isDirty = true;
      });
    }
  }

  void _addResponsibilityB() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(_markAsDirty);
      _responsibilitiesBControllers.add(controller);
      _isDirty = true;
    });
  }

  void _removeResponsibilityB(int index) {
    if (_responsibilitiesBControllers.length > 1) {
      setState(() {
        _responsibilitiesBControllers[index].dispose();
        _responsibilitiesBControllers.removeAt(index);
        _isDirty = true;
      });
    }
  }

  void _addCommonResponsibility() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(_markAsDirty);
      _commonResponsibilitiesControllers.add(controller);
      _isDirty = true;
    });
  }

  void _removeCommonResponsibility(int index) {
    if (_commonResponsibilitiesControllers.length > 1) {
      setState(() {
        _commonResponsibilitiesControllers[index].dispose();
        _commonResponsibilitiesControllers.removeAt(index);
        _isDirty = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thoát'),
        content: const Text('Bạn có thay đổi chưa được lưu. Bạn có chắc chắn muốn thoát không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Thoát'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<void> _saveResponsibilities() async {
    // Filter out empty values
    final responsibilitiesA = _responsibilitiesAControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    
    final responsibilitiesB = _responsibilitiesBControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    
    final commonResponsibilities = _commonResponsibilitiesControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    
    // Create request object
    final request = ContractModifyRequest(
      roomId: widget.roomId,
      contractDate: '', // Placeholder - not modifying this field
      contractAddress: '', // Placeholder - not modifying this field
      rentalAddress: '', // Placeholder - not modifying this field
      deposit: 0, // Placeholder - not modifying this field
      responsibilitiesA: responsibilitiesA,
      responsibilitiesB: responsibilitiesB,
      commonResponsibilities: commonResponsibilities,
    );
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _contractCubit.modifyContract(request);
      
      if (success && mounted) {
        setState(() {
          _isDirty = false;
        });
        Navigator.of(context).pop(true); // Return success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trách nhiệm hợp đồng'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    // Set colors based on theme
    primaryColor = const Color(0xFF0075FF);
    secondaryColor = const Color(0xFF00D1FF);
    lightBlue = const Color(0xFFE6F4FF);
    accentColor = const Color(0xFFFFB300); // Amber accent
    darkGray = const Color(0xFF424242);
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
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
          title: const Text(
            'Chỉnh sửa trách nhiệm',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_isDirty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Badge(
                  backgroundColor: Colors.red,
                  smallSize: 8,
                  child: IconButton(
                    onPressed: _isLoading ? null : _saveResponsibilities,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    tooltip: 'Lưu thay đổi',
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _isLoading ? null : _saveResponsibilities,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                tooltip: 'Lưu thay đổi',
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            dividerHeight: 0,
            tabs: const [
              Tab(text: 'Bên A'),
              Tab(text: 'Bên B'),
              Tab(text: 'Chung'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            switch (_tabController.index) {
              case 0:
                _addResponsibilityA();
                break;
              case 1:
                _addResponsibilityB();
                break;
              case 2:
                _addCommonResponsibility();
                break;
            }
          },
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
          tooltip: 'Thêm trách nhiệm mới',
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab Bên A
                    _buildResponsibilitiesTab(
                      'Trách nhiệm bên A (Chủ nhà)',
                      _responsibilitiesAControllers,
                      _removeResponsibilityA,
                      primaryColor,
                    ),
                    
                    // Tab Bên B
                    _buildResponsibilitiesTab(
                      'Trách nhiệm bên B (Người thuê)',
                      _responsibilitiesBControllers,
                      _removeResponsibilityB,
                      secondaryColor,
                    ),
                    
                    // Tab Chung
                    _buildResponsibilitiesTab(
                      'Trách nhiệm chung',
                      _commonResponsibilitiesControllers,
                      _removeCommonResponsibility,
                      accentColor,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildResponsibilitiesTab(
    String title,
    List<TextEditingController> controllers,
    Function(int) onRemovePressed,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: controllers.length,
              itemBuilder: (context, index) {
                return _buildResponsibilityCard(
                  controllers[index],
                  index,
                  onRemovePressed,
                  color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsibilityCard(
    TextEditingController controller,
    int index,
    Function(int) onRemovePressed,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: color,
                    width: 4,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 8.0,
                  top: 12.0,
                  bottom: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Nhập trách nhiệm...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: darkGray.withOpacity(0.5),
                          ),
                        ),
                        maxLines: null,
                        style: TextStyle(
                          color: darkGray,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemovePressed(index),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Xóa mục này',
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 