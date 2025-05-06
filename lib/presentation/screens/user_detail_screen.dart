import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roomily/data/models/user.dart';
import 'package:roomily/data/repositories/user_repository_impl.dart';
import 'package:roomily/presentation/widgets/common/section_divider.dart';

import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/user/user_state.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({Key? key}) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late UserCubit _userCubit;
  
  // Map to track visibility state of sensitive fields
  final Map<String, bool> _visibilityMap = {
    'privateId': false,
    'email': false,
    'phone': false,
    'balance': false,
    'address': false,
  };

  @override
  void initState() {
    super.initState();
    _userCubit = UserCubit(userRepository: UserRepositoryImpl());
    
    // Lấy thông tin user
    print("Initializing UserDetailScreen - Getting user info");
    _userCubit.getUserInfo();
    
    // Thêm debug để kiểm tra state ban đầu
    Future.delayed(Duration.zero, () {
      print("Initial UserCubit state: ${_userCubit.state}");
    });
  }

  @override
  void dispose() {
    _userCubit.close();
    super.dispose();
  }
  
  // Toggle visibility for a field
  void _toggleVisibility(String field) {
    setState(() {
      _visibilityMap[field] = !(_visibilityMap[field] ?? false);
    });
  }
  
  // Mask a string value based on type
  String _getMaskedValue(String type, String value) {
    if (value.isEmpty) return 'Chưa cập nhật';
    
    switch (type) {
      case 'privateId':
        return '••••••••' + value.substring(Math.max(0, value.length - 4));
      case 'email':
        final parts = value.split('@');
        if (parts.length < 2) return '••••••@••••••';
        return parts[0].substring(0, Math.min(2, parts[0].length)) + 
               '••••••@' + parts[1];
      case 'phone':
        return '••••••' + value.substring(Math.max(0, value.length - 3));
      case 'balance':
        return '••••••••• VND';
      case 'address':
        if (value.length <= 5) return '•••••••••••';
        return value.substring(0, 3) + '••••••••••';
      default:
        return '••••••••••';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _userCubit,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Thông tin cá nhân',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            BlocBuilder<UserCubit, UserInfoState>(
              builder: (context, state) {
                // Kiểm tra xem đã load xong thông tin người dùng chưa
                bool isLoaded = state is UserInfoLoaded || state is UserInfoByIdLoaded;
                
                return IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: isLoaded ? Colors.purple : Colors.grey,
                  ),
                  onPressed: isLoaded 
                    ? () {
                        print("Edit button in AppBar pressed");
                        // Sử dụng try-catch để bắt lỗi nếu có
                        try {
                          _openEditProfileModal(context);
                        } catch (e) {
                          print("Error opening modal from AppBar button: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null, // Vô hiệu hóa nút nếu chưa tải xong dữ liệu
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<UserCubit, UserInfoState>(
          builder: (context, state) {
            print("Building UserDetailScreen with state: $state");
            if (state is UserInfoLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.purple));
            } else if (state is UserInfoError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            } else if (state is UserInfoLoaded) {
              return _buildUserDetailContent(context, state.user);
            } else if (state is UserInfoByIdLoaded) {
              return _buildUserDetailContent(context, state.user);
            }
            
            // Fallback to loading
            return const Center(child: CircularProgressIndicator(color: Colors.purple));
          },
        ),
      ),
    );
  }

  Widget _buildUserDetailContent(BuildContext context, User user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar và tên
          _buildProfileHeader(user),
          
          const SizedBox(height: 16),
          
          // Thông tin cá nhân
          _buildInfoSection(
            'THÔNG TIN CÁ NHÂN',
            Icons.person,
            [
              InfoItem(label: 'Họ và tên', value: user.fullName),
              InfoItem(label: 'Tên người dùng', value: user.username),
              InfoItem(label: 'Giới tính', value: user.getGenderAsString() ?? 'Chưa cập nhật'),
              InfoItem(
                label: 'Mã ID', 
                value: _visibilityMap['privateId'] == true 
                  ? user.privateId 
                  : _getMaskedValue('privateId', user.privateId),
                isSensitive: true,
                fieldKey: 'privateId',
                isVisible: _visibilityMap['privateId'] ?? false,
                onToggleVisibility: () => _toggleVisibility('privateId'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Thông tin liên hệ
          _buildInfoSection(
            'THÔNG TIN LIÊN HỆ',
            Icons.contact_mail,
            [
              InfoItem(
                label: 'Email', 
                value: _visibilityMap['email'] == true 
                  ? user.email 
                  : _getMaskedValue('email', user.email),
                isSensitive: true,
                fieldKey: 'email',
                isVisible: _visibilityMap['email'] ?? false,
                onToggleVisibility: () => _toggleVisibility('email'),
              ),
              InfoItem(
                label: 'Số điện thoại', 
                value: _visibilityMap['phone'] == true 
                  ? user.phone 
                  : _getMaskedValue('phone', user.phone),
                isSensitive: true,
                fieldKey: 'phone',
                isVisible: _visibilityMap['phone'] ?? false,
                onToggleVisibility: () => _toggleVisibility('phone'),
              ),
              InfoItem(
                label: 'Địa chỉ', 
                value: _visibilityMap['address'] == true 
                  ? user.address 
                  : _getMaskedValue('address', user.address),
                isSensitive: true,
                fieldKey: 'address',
                isVisible: _visibilityMap['address'] ?? false,
                onToggleVisibility: () => _toggleVisibility('address'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bảo mật và xác thực
          _buildInfoSection(
            'BẢO MẬT & XÁC THỰC',
            Icons.security,
            [
              InfoItem(
                label: 'Trạng thái xác thực', 
                value: user.isVerified ? 'Đã xác thực' : 'Chưa xác thực',
                valueColor: user.isVerified ? Colors.green : Colors.orange,
                valueIcon: user.isVerified ? Icons.verified : Icons.warning,
                valueIconColor: user.isVerified ? Colors.green : Colors.orange,
              ),
              InfoItem(label: 'Đánh giá người dùng', value: '${user.rating}/5.0'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // // Các nút thao tác
          // _buildActionButtons(),
          //
          // const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple.withOpacity(0.3), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.profilePicture != null 
                      ? NetworkImage(user.profilePicture!)
                      : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
              ),
              GestureDetector(
                onTap: () => _showImagePickerOptions(context),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.purple,
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                user.isVerified ? Icons.verified_user : Icons.person,
                size: 16,
                color: user.isVerified ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                user.isVerified ? 'Đã xác thực' : 'Chưa xác thực',
                style: TextStyle(
                  fontSize: 14,
                  color: user.isVerified ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user.balance != null)
            GestureDetector(
              onTap: () => _toggleVisibility('balance'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade300, Colors.purple.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _visibilityMap['balance'] == true
                        ? '${user.balance.toStringAsFixed(0)} VND'
                        : _getMaskedValue('balance', user.balance.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _visibilityMap['balance'] == true ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withOpacity(0.7),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Hiển thị bottom sheet với các tùy chọn chọn ảnh
  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn ảnh đại diện',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    context,
                    icon: Icons.photo_camera,
                    title: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImagePickerOption(
                    context,
                    icon: Icons.photo_library,
                    title: 'Thư viện',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Tạo UI cho mỗi tùy chọn trong bottom sheet
  Widget _buildImagePickerOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.purple,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // Chọn hình ảnh từ camera hoặc gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Hiển thị hộp thoại xác nhận với preview ảnh
        _showImageConfirmationDialog(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hiển thị dialog xác nhận với preview ảnh đã chọn
  void _showImageConfirmationDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận ảnh đại diện'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  imageFile,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Bạn có muốn sử dụng ảnh này làm ảnh đại diện không?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadAvatar(imageFile);
              },
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ],
        );
      },
    );
  }

  // Upload ảnh đại diện mới
  Future<void> _uploadAvatar(File imageFile) async {
    try {
      // Hiển thị loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(width: 20),
                  Text('Đang cập nhật ảnh đại diện...'),
                ],
              ),
            ),
          );
        },
      );

      // In thông tin về file để debug
      print('Uploading avatar from path: ${imageFile.path}');
      print('Image size: ${await imageFile.length()} bytes');
      
      // Cập nhật avatar trong profile bằng cách gửi đường dẫn file
      final userCubit = BlocProvider.of<UserCubit>(context, listen: false);
      await userCubit.updateUserAvatar(imageFile.path);

      await context.read<UserCubit>().getUserInfo();
      // Đóng dialog loading
      if (mounted) {
        Navigator.pop(context);
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      // Đóng dialog loading nếu có lỗi
      if (mounted) {
        Navigator.pop(context);
        
        // Hiển thị thông báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật ảnh đại diện thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoSection(String title, IconData icon, List<InfoItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Info items
          ...items.map((item) => _buildInfoItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (item.valueIcon != null) ...[
                  Icon(
                    item.valueIcon,
                    size: 16,
                    color: item.valueIconColor ?? Colors.grey[800],
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: item.valueColor ?? Colors.grey[800],
                    ),
                  ),
                ),
                if (item.isSensitive) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: item.onToggleVisibility,
                    child: Icon(
                      item.isVisible ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildActionButtons() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Column(
  //       children: [
  //         _buildActionButton(
  //           'Đổi mật khẩu',
  //           Icons.lock,
  //           Colors.indigo,
  //           () {
  //             // TODO: Implement change password functionality
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(
  //                 content: Text('Tính năng đang được phát triển'),
  //               ),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Mở modal để chỉnh sửa thông tin cá nhân
  void _openEditProfileModal(BuildContext context) {
    print("Opening edit modal");
    
    try {
      final userState = context.read<UserCubit>().state;
      print("UserCubit state: $userState");
      
      // Kiểm tra nếu state là UserInfoLoaded hoặc UserInfoByIdLoaded
      if (userState is UserInfoLoaded || userState is UserInfoByIdLoaded) {
        print("User info loaded, showing modal");
        // Lấy thông tin user từ state
        User user;
        if (userState is UserInfoLoaded) {
          user = userState.user;
        } else {
          // Trong trường hợp là UserInfoByIdLoaded
          user = (userState as UserInfoByIdLoaded).user;
        }
        
        // Tạo các controller cho form
        final fullNameController = TextEditingController(text: user.fullName);
        final emailController = TextEditingController(text: user.email);
        final phoneController = TextEditingController(text: user.phone);
        final addressController = TextEditingController(text: user.address);
        
        // Biến lưu giới tính
        dynamic selectedGender = user.gender;
        
        // Đảm bảo dispose controller khi không cần thiết nữa
        void disposeControllers() {
          fullNameController.dispose();
          emailController.dispose();
          phoneController.dispose();
          addressController.dispose();
        }
        
        // Sử dụng Future.microtask để đảm bảo modal được hiển thị sau khi build hoàn tất
        Future.microtask(() {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  Navigator.pop(context);
                                  disposeControllers();
                                },
                              ),
                              const Text(
                                'Chỉnh sửa thông tin',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  print("Save button pressed");
                                  // Tạo user mới với thông tin đã cập nhật
                                  final updatedUser = User(
                                    id: user.id,
                                    privateId: user.privateId,
                                    username: user.username,
                                    fullName: fullNameController.text,
                                    gender: selectedGender,
                                    email: emailController.text,
                                    phone: phoneController.text,
                                    profilePicture: user.profilePicture,
                                    address: addressController.text,
                                    rating: user.rating,
                                    isVerified: user.isVerified,
                                    balance: user.balance,
                                  );
                                  
                                  // Hiển thị loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext dialogContext) {
                                      return Dialog(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              CircularProgressIndicator(color: Colors.purple),
                                              SizedBox(width: 20),
                                              Text('Đang cập nhật...'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  
                                  try {
                                    print("Updating user info");
                                    // Tìm UserCubit từ context gốc để tránh lỗi khi modal đóng
                                    final userCubit = BlocProvider.of<UserCubit>(context, listen: false);
                                    await userCubit.updateUserInfo(updatedUser);
                                    
                                    // Đóng dialog loading và modal
                                    if (mounted) {
                                      Navigator.pop(context); // Đóng loading dialog
                                      Navigator.pop(context); // Đóng modal
                                      disposeControllers();
                                      
                                      // Hiển thị thông báo thành công
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cập nhật thông tin thành công'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print("Error updating user: $e");
                                    // Đóng dialog loading
                                    if (mounted) {
                                      Navigator.pop(context);
                                      
                                      // Hiển thị thông báo lỗi
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Cập nhật thất bại: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text(
                                  'Lưu',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Form fields
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormField('Họ và tên', fullNameController, Icons.person),
                                const SizedBox(height: 16),
                                _buildFormField('Email', emailController, Icons.email),
                                const SizedBox(height: 16),
                                _buildFormField('Số điện thoại', phoneController, Icons.phone),
                                const SizedBox(height: 16),
                                _buildFormField('Địa chỉ', addressController, Icons.location_on),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ).then((_) async {
            // Đảm bảo controllers được dispose khi modal đóng
            if(!mounted) return;
            await context.read<UserCubit>().getUserInfo();
            disposeControllers();
          });
        });
      } else {
        print("User info not loaded: $userState");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở form cập nhật, vui lòng thử lại sau'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error opening modal: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Widget để tạo trường nhập liệu
  Widget _buildFormField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Nhập $label',
              prefixIcon: Icon(icon, color: Colors.purple),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class InfoItem {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? valueIcon;
  final Color? valueIconColor;
  final bool isSensitive;
  final String? fieldKey;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueIcon,
    this.valueIconColor,
    this.isSensitive = false,
    this.fieldKey,
    this.isVisible = false,
    this.onToggleVisibility,
  });
}

// For masking strings
class Math {
  static int max(int a, int b) => a > b ? a : b;
  static int min(int a, int b) => a < b ? a : b;
} 