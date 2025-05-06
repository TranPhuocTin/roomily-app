import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/presentation/screens/contract_viewer_screen.dart';
import 'package:roomily/data/repositories/contract_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:roomily/data/blocs/contract/contract_cubit.dart';
import 'package:roomily/presentation/screens/edit_responsibilities_screen.dart';
import 'package:roomily/presentation/screens/edit_landlord_info_screen.dart';
import 'package:get_it/get_it.dart';

/// Screen for managing contracts
class ContractManagementScreen extends StatelessWidget {
  final Room? room;

  /// Constructor for [ContractManagementScreen]
  const ContractManagementScreen({
    Key? key,
    this.room,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Updated color palette with app's primary colors
    final Color primaryColor = const Color(0xFF0075FF);
    final Color secondaryColor = const Color(0xFF00D1FF);
    final Color lightBlue = const Color(0xFFE6F3FF);  // Light version of primary color
    final Color accentAmber = const Color(0xFFFFD54F);
    final Color pdfRed = const Color(0xFFE53935);  // Màu đỏ cho PDF
    final Color darkGray = const Color(0xFF424242);
    final Color lightGray = const Color(0xFFF5F5F5);
    final Color infoBlue = primaryColor;  // Sử dụng primaryColor thay vì màu xanh khác
    final Color securityGreen = const Color(0xFF66BB6A);  // Màu xanh lá cho bảo mật
    final Color warningOrange = const Color(0xFFFFA726);  // Màu cam cho cảnh báo
    
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
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
          'Quản lý hợp đồng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
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
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header section
              // Container(
              //   width: double.infinity,
              //   margin: const EdgeInsets.only(bottom: 24.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //         'Quản lý hợp đồng',
              //         style: theme.textTheme.headlineMedium?.copyWith(
              //           color: primaryPurple,
              //           fontWeight: FontWeight.bold,
              //         ),
              //         ),
              //         const SizedBox(height: 8),
              //       Text(
              //         'Xem và quản lý hợp đồng thuê phòng của bạn',
              //         style: theme.textTheme.bodyLarge?.copyWith(
              //           color: darkGray,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

            // Room details card if a room is provided
            if (room != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                        child: Text(
                          'Thông tin phòng',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InfoRow(
                                  icon: Icons.apartment,
                                  label: 'Tên phòng:',
                                  value: room!.title,
                                  iconColor: primaryColor,
                                  labelColor: darkGray,
                                ),
                                const SizedBox(height: 12),
                                InfoRow(
                                  icon: Icons.location_on,
                                  label: 'Địa chỉ:',
                                  value: room!.address,
                                  iconColor: primaryColor,
                                  labelColor: darkGray,
                                ),
                                const SizedBox(height: 12),
                                InfoRow(
                                  icon: Icons.attach_money,
                                  label: 'Giá thuê:',
                                  value: '${room!.price} đ/tháng',
                                  valueColor: darkGray,
                                  iconColor: Colors.green[600],
                                  labelColor: darkGray,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Contract actions section - Redesigned with grid layout
              Container(
                margin: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Text(
                        'Thao tác hợp đồng',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                            children: [
                              ActionTile(
                                icon: Icons.visibility,
                                title: 'Xem hợp đồng',
                                color: primaryColor,
                                onTap: room != null && room!.id != null
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ContractViewerScreen(roomId: room!.id!),
                          ),
                        );
                      }
                                    : null,
                              ),
                              ActionTile(
                                icon: Icons.picture_as_pdf,
                                title: 'Xuất PDF',
                                color: pdfRed,
                                onTap: room != null && room!.id != null
                                    ? () async {
                                        try {
                                          // Hiển thị loading dialog
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              return const AlertDialog(
                                                content: Row(
                                                  children: [
                                                    CircularProgressIndicator(),
                                                    SizedBox(width: 20),
                                                    Text('Đang tải xuống PDF...'),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                          
                                          // Tải PDF từ API
                                          final contractRepository = GetIt.I<ContractRepository>();
                                          final pdfBytes = await contractRepository.downloadContractPdf(room!.id!);
                                          
                                          // Lưu file PDF
                                          final directory = await getApplicationDocumentsDirectory();
                                          final file = File('${directory.path}/hopdong_${room!.id}.pdf');
                                          await file.writeAsBytes(pdfBytes);
                                          
                                          // Đóng dialog
                                          Navigator.of(context).pop();
                                          
                                          // Mở file PDF
                                          final result = await OpenFile.open(file.path);
                                          if (result.type != ResultType.done) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Không thể mở file PDF: ${result.message}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          // Đóng dialog nếu đang hiển thị
                                          if (Navigator.of(context).canPop()) {
                                            Navigator.of(context).pop();
                                          }
                                          
                                          // Hiển thị thông báo lỗi
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Lỗi khi tải xuống PDF: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                              ),
                              ActionTile(
                                icon: Icons.edit_note,
                                title: 'Trách nhiệm',
                                color: warningOrange,
                                onTap: room != null && room!.id != null
                                    ? () async {
                                        final contractCubit = ContractCubit(
                                          repository: GetIt.I<ContractRepository>()
                                        );
                                        
                                        try {
                                          // Show loading dialog
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => const AlertDialog(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 16),
                                                  Text('Đang tải dữ liệu...'),
                                                ],
                                              ),
                                            ),
                                          );
                                          
                                          // Get contract responsibilities
                                          final responsibilities = await contractCubit.getContractResponsibilities(room!.id!);
                                          
                                          // Close loading dialog
                                          Navigator.of(context).pop();
                                          
                                          if (responsibilities != null) {
                                            if (!context.mounted) return;
                                            
                                            // Navigate to edit responsibilities screen
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditResponsibilitiesScreen(
                                                  roomId: room!.id!,
                                                  initialResponsibilities: responsibilities,
                                                ),
                                              ),
                                            );
                                            
                                            if (result == true && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Cập nhật trách nhiệm thành công'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          } else {
                                            if (!context.mounted) return;
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Không thể tải trách nhiệm hợp đồng'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          // Close loading dialog if still showing
                                          if (context.mounted && Navigator.of(context).canPop()) {
                                            Navigator.of(context).pop();
                                          }
                                          
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Lỗi: ${e.toString()}'),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } finally {
                                          contractCubit.close();
                                        }
                                      }
                                    : null,
                              ),
                              ActionTile(
                                icon: Icons.file_copy,
                                title: 'Thông tin',
                                color: securityGreen,
                                onTap: room != null && room!.id != null
                                    ? () async {
                                        // Navigate to edit landlord info screen
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const EditLandlordInfoScreen(),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Information about contracts
              Container(
                margin: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Text(
                        'Thông tin hữu ích',
                        style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Về hợp đồng thuê phòng',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: darkGray,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ContractInfoItem(
                                icon: Icons.gavel,
                                title: 'Giá trị pháp lý',
                                description: 'Hợp đồng thuê phòng trọ là tài liệu pháp lý quan trọng xác định quyền và nghĩa vụ của cả bên cho thuê và bên thuê phòng.',
                                iconBgColor: primaryColor.withOpacity(0.1),
                                iconColor: primaryColor,
                                titleColor: darkGray,
                                descriptionColor: darkGray,
                              ),
                              const SizedBox(height: 16),
                              ContractInfoItem(
                                icon: Icons.policy,
                                title: 'Đọc kỹ trước khi ký',
                                description: 'Hãy đảm bảo đọc kỹ tất cả các điều khoản trước khi ký kết hợp đồng.',
                                iconBgColor: primaryColor.withOpacity(0.1),
                                iconColor: primaryColor,
                                titleColor: darkGray,
                                descriptionColor: darkGray,
                              ),
                              const SizedBox(height: 16),
                              ContractInfoItem(
                                icon: Icons.security,
                                title: 'Bảo vệ quyền lợi',
                                description: 'Hợp đồng bảo vệ quyền lợi của cả bên thuê và bên cho thuê, tránh các tranh chấp không đáng có.',
                                iconBgColor: securityGreen.withOpacity(0.1),
                                iconColor: securityGreen,
                                titleColor: darkGray,
                                descriptionColor: darkGray,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying information rows with icon and label
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;
  final Color? labelColor;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconColor,
    this.labelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? theme.colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: labelColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Modern action tile widget for grid layout
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;

  const ActionTile({
    Key? key,
    required this.icon,
    required this.title,
    this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    final Color tileColor = isDisabled 
        ? Colors.grey.shade300 
        : color?.withOpacity(0.1) ?? Theme.of(context).primaryColor.withOpacity(0.1);
    final Color iconColor = isDisabled 
        ? Colors.grey.shade500 
        : color ?? Theme.of(context).primaryColor;
    final Color textColor = isDisabled 
        ? Colors.grey.shade700 
        : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for contract information items
class ContractInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconBgColor;
  final Color? iconColor;
  final Color? titleColor;
  final Color? descriptionColor;

  const ContractInfoItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconBgColor,
    this.iconColor,
    this.titleColor,
    this.descriptionColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor ?? theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: descriptionColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 