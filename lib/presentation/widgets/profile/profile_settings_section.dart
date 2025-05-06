import 'package:flutter/material.dart';
import 'package:roomily/data/models/user_profile.dart';

class ProfileSettingsSection extends StatelessWidget {
  final UserProfile userProfile;
  final Function(String) onLanguageChanged;
  final Function(bool) onThemeChanged;
  final Function(bool) onNotificationSettingsChanged;

  const ProfileSettingsSection({
    Key? key,
    required this.userProfile,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.onNotificationSettingsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài đặt & Tùy chỉnh',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            Icons.language,
            'Ngôn ngữ',
            'Tiếng Việt',
            () {
              // Show language selection dialog
              _showLanguageSelectionDialog(context);
            },
          ),
          const Divider(),
          _buildSwitchItem(
            context,
            Icons.dark_mode,
            'Chế độ tối',
            false,
            onThemeChanged,
          ),
          const Divider(),
          _buildSwitchItem(
            context,
            Icons.notifications,
            'Thông báo',
            true,
            onNotificationSettingsChanged,
          ),
          const Divider(),
          _buildSettingItem(
            context,
            Icons.security,
            'Bảo mật & Quyền riêng tư',
            '',
            () {
              // Navigate to security settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(
    BuildContext context,
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn ngôn ngữ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, 'Tiếng Việt', 'vi'),
              _buildLanguageOption(context, 'English', 'en'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String language,
    String code,
  ) {
    final isSelected = (language == 'Tiếng Việt'); // Default to Vietnamese

    return ListTile(
      title: Text(language),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        onLanguageChanged(code);
        Navigator.of(context).pop();
      },
    );
  }
} 