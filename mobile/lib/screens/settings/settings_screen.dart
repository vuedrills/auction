import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Settings Screen - Connected to Backend
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefsAsync = ref.read(notificationPreferencesProvider);
    prefsAsync.whenData((prefs) {
      setState(() {
        _pushNotifications = prefs['push_enabled'] ?? true;
      });
    });
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Settings', style: AppTypography.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: user?.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(imageUrl: user!.avatarUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? 'Guest', style: AppTypography.titleMedium),
                Text(user?.email ?? '', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                if (user?.homeTown != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(user!.homeTown!.name, style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                  ),
              ])),
              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/profile/edit')),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Home Town can only be changed once every 30 days.',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
          
          const SizedBox(height: 24),
          _SectionTitle('Account'),
          _SettingsItem(icon: Icons.person, color: Colors.blue, title: 'Personal Information', onTap: () => context.push('/profile/edit')),
          _SettingsItem(icon: Icons.credit_card, color: Colors.green, title: 'Payment Methods', onTap: () {}),
          _SettingsItem(icon: Icons.gavel, color: Colors.purple, title: 'Auction History', onTap: () => context.push('/profile/auctions')),
          
          const SizedBox(height: 24),
          _SectionTitle('Preferences'),
          _SettingsToggle(
            icon: Icons.notifications,
            color: Colors.orange,
            title: 'Push Notifications',
            value: _pushNotifications,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              ref.read(notificationRepositoryProvider).updatePreferences({'push_enabled': v});
            },
          ),
          _SettingsItem(icon: Icons.notifications_active, color: Colors.amber, title: 'Notification Settings', onTap: () => context.push('/notification-preferences')),
          _SettingsItem(icon: Icons.lock, color: Colors.grey, title: 'Privacy & Security', onTap: () {}),
          _SettingsToggle(
            icon: Icons.dark_mode,
            color: Colors.indigo,
            title: 'Dark Mode',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          
          const SizedBox(height: 24),
          _SectionTitle('Support'),
          _SettingsItem(icon: Icons.help, color: Colors.teal, title: 'Help Center', onTap: () => context.push('/help')),
          _SettingsItem(icon: Icons.description, color: Colors.grey, title: 'Terms & Policies', onTap: () => context.push('/terms')),
          
          const SizedBox(height: 24),
          // Logout
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text('Log Out', style: AppTypography.titleSmall.copyWith(color: AppColors.error)),
              onTap: _handleLogout,
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text('Trabab v1.0.2', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight, letterSpacing: 1)),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  const _SettingsItem({required this.icon, required this.color, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title, style: AppTypography.bodyMedium),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingsToggle({required this.icon, required this.color, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title, style: AppTypography.bodyMedium),
        trailing: Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary),
      ),
    );
  }
}
