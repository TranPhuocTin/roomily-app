import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/utils/room_report_type.dart';
import 'package:roomily/data/blocs/room_report/room_report_cubit.dart';
import 'package:roomily/data/blocs/room_report/room_report_state.dart';
import 'package:roomily/data/blocs/user/user_cubit.dart';
import 'package:roomily/data/blocs/user/user_state.dart';

class ReportDialog extends StatefulWidget {
  final String roomId;

  const ReportDialog({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  RoomReportType _selectedType = RoomReportType.FAKE; // Default type
  
  final List<Map<String, dynamic>> _reportTypes = [
    {
      'value': RoomReportType.FAKE,
      'label': 'Thông tin giả mạo',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.red.shade700,
    },
    {
      'value': RoomReportType.SPAM,
      'label': 'Spam / Quảng cáo',
      'icon': Icons.mark_email_unread_outlined,
      'color': Colors.orange,
    },
    {
      'value': RoomReportType.ILLEGAL,
      'label': 'Vi phạm pháp luật',
      'icon': Icons.gavel,
      'color': Colors.purple,
    },
    {
      'value': RoomReportType.OTHER,
      'label': 'Lý do khác',
      'icon': Icons.more_horiz,
      'color': Colors.blue,
    },
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<RoomReportCubit, RoomReportState>(
      listener: (context, state) {
        if (state is RoomReportLoading) {
          setState(() {
            _isSubmitting = true;
          });
        } else if (state is RoomReportSuccess) {
          setState(() {
            _isSubmitting = false;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Báo cáo của bạn đã được gửi thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is RoomReportError) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có lỗi xảy ra: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.report_problem_rounded,
                      color: theme.colorScheme.error,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Báo cáo phòng trọ',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Loại báo cáo:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: _reportTypes.map((type) {
                          final bool isSelected = _selectedType == type['value'];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = type['value'];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? type['color'].withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: _reportTypes.last == type
                                        ? Colors.transparent
                                        : theme.colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: type['color'].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      type['icon'],
                                      color: type['color'],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      type['label'],
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: type['color'],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chi tiết báo cáo:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nhập chi tiết lý do báo cáo...',
                    hintStyle: TextStyle(
                      color: theme.hintColor.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: TextButton.icon(
                        onPressed: _isSubmitting 
                          ? null 
                          : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Hủy'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting 
                          ? null 
                          : _submitReport,
                        icon: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.send),
                        label: const Text('Gửi báo cáo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitReport() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập lý do báo cáo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final state = context.read<UserCubit>().state;
    if (state is UserInfoLoaded) {
      final reporterId = state.user.id;
      context.read<RoomReportCubit>().reportRoom(
        reporterId: reporterId,
        roomId: widget.roomId,
        reason: reason,
        type: _selectedType,
      );
    } else {
      // Load user info first
      context.read<UserCubit>().getUserInfo().then((_) {
        final newState = context.read<UserCubit>().state;
        if (newState is UserInfoLoaded) {
          final reporterId = newState.user.id;
          context.read<RoomReportCubit>().reportRoom(
            reporterId: reporterId,
            roomId: widget.roomId,
            reason: reason,
            type: _selectedType,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lấy thông tin người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }
} 