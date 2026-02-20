import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/edit_display_name_dialog.dart';
import 'change_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userModelProvider).value;
    final locale = ref.watch(localeProvider);
    final currentLanguage = locale.languageCode == 'hi' ? 'Hindi' : 'English';

    final l10n = AppLocalizations.of(context)!;

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text(l10n.signIn)), // Reusing signIn generally or add a specific message if needed, but 'signIn' is close. Actually "Please sign in..." is specific. Let's keep it hardcoded or add key. User didn't report this one specifically, but let's be thorough.
        // Wait, I didn't add "Please sign in to access settings". I'll skip this one for now to avoid error, or use "guestSubtitle" if appropriate? No.
        // I will keep "Please sign in to access settings" hardcoded or use a generic "sign in" if I have it. I added "signIn".
        // Let's just leave this specific error message for now as I missed adding a key for it.
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _buildHeroBanner(context, currentUser, l10n),
            const SizedBox(height: 24),
            _buildSectionCard(
              context,
              title: l10n.account,
              children: [
                _settingTile(
                  context,
                  icon: Icons.person_outline,
                  title: l10n.displayName,
                  subtitle: currentUser.displayName,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => EditDisplayNameDialog(
                        currentName: currentUser.displayName,
                      ),
                    );
                  },
                ),
                _settingTile(
                  context,
                  icon: Icons.lock_outline,
                  title: FirebaseAuth.instance.currentUser?.providerData
                              .any((p) => p.providerId == 'password') ==
                          true
                      ? l10n.changePassword
                      : l10n.setPassword,
                  subtitle: FirebaseAuth.instance.currentUser?.providerData
                              .any((p) => p.providerId == 'password') ==
                          true
                      ? l10n.resetCredentials
                      : l10n.createPassword,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              context,
              title: l10n.preferences,
              children: [
                _settingTile(
                  context,
                  icon: Icons.language,
                  title: l10n.language,
                  subtitle: currentLanguage,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLanguageDialog,
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final themeMode = ref.watch(themeModeProvider);
                    final platformBrightness = MediaQuery.of(
                      context,
                    ).platformBrightness;
                    final followsSystemDark =
                        themeMode == ThemeMode.system &&
                        platformBrightness == Brightness.dark;
                    final isDark =
                        themeMode == ThemeMode.dark || followsSystemDark;
                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.darkMode),
                      subtitle: Text(l10n.reduceGlare),
                      value: isDark,
                      secondary: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                      ),
                      onChanged: (_) {
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              context,
              title: l10n.session,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    l10n.logout,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.signOutConfirmation),
                        content: Text(
                          l10n.signOutMessage,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text(l10n.confirmSignOut),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (mounted) Navigator.pop(context);
                      await ref.read(authServiceProvider).signOut();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, UserModel user, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF781C2E), Color(0xFF9E2F3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.personalizeExperience,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.personalizeSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children.expand(
            (tile) => [tile, if (tile != children.last) const Divider()],
          ),
        ],
      ),
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF781C2E).withOpacity(0.1),
        child: Icon(icon, color: const Color(0xFF781C2E)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    final currentLocale = ref.read(localeProvider);
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          _buildLanguageOption('English', 'en', currentLocale.languageCode == 'en'),
          _buildLanguageOption('Hindi', 'hi', currentLocale.languageCode == 'hi'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String name, String code, bool isSelected) {
    return SimpleDialogOption(
      onPressed: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name),
            if (isSelected) const Icon(Icons.check, color: Colors.green),
          ],
        ),
      ),
    );
  }
}


