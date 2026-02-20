import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../rentals/presentation/screens/rentals_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';

import 'my_listings_screen.dart';
import 'favorites_screen.dart';
import 'payment_methods_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'kyc_screen.dart';
import 'settings_screen.dart';

import '../../../../core/providers/items_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Direct stream binding for real-time KYC status from 'kyc' collection
    final kycAsync = ref.watch(userKycProvider);
    final userAsync = ref.watch(userModelProvider);
    final authUser = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (firestoreUser) {
        if (authUser == null) {
          return _buildGuestView(context);
        }

        final user =
            firestoreUser ??
            UserModel(
              uid: authUser.uid,
              email: authUser.email ?? '',
              displayName: authUser.displayName ?? 'User',
              createdAt: DateTime.now(),
            );
        
        // Derive the authoritative KYC status from the KYC provider
        // If data is null -> 'not_submitted'
        // If data exists, use its status.
        final kycStatus = kycAsync.maybeWhen(
           data: (kyc) => kyc?.status ?? 'not_submitted',
           orElse: () => user.kycStatus, // Fallback to user model if loading/error
        );

        return _buildProfileView(context, ref, user, kycStatus);
      },
    );
  }

  // -------------------- GUEST VIEW --------------------

  Widget _buildGuestView(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF781C2E), Color(0xFF9E2F3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  l10n.guestWelcome,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.guestSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: Text(l10n.signIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF781C2E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- PROFILE VIEW --------------------

  Widget _buildProfileView(
    BuildContext context,
    WidgetRef ref,
    UserModel currentUser,
    String kycStatus,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final tier = currentUser.subscriptionTier.isNotEmpty
        ? currentUser.subscriptionTier
        : 'basic';
    final membershipLabel = tier.replaceAll('_', ' ').toUpperCase();

    final actions =
        <({String title, String subtitle, IconData icon, Widget screen})>[
          (
            title: l10n.myListings,
            subtitle: l10n.manageListings,
            icon: Icons.inventory_2_outlined,
            screen: const MyListingsScreen(),
          ),
          (
            title: l10n.myRentals,
            subtitle: l10n.trackRentals,
            icon: Icons.receipt_long,
            screen: const RentalsScreen(),
          ),
          (
            title: l10n.favorites,
            subtitle: l10n.quickAccess,
            icon: Icons.favorite_outline,
            screen: const FavoritesScreen(),
          ),
          (
            title: l10n.paymentMethods,
            subtitle: l10n.walletsCards,
            icon: Icons.payment,
            screen: const PaymentMethodsScreen(),
          ),
          (
            title: l10n.notifications,
            subtitle: l10n.promotionsAlerts,
            icon: Icons.notifications_active_outlined,
            screen: const NotificationsScreen(),
          ),
          (
            title: l10n.helpSupport,
            subtitle: l10n.faqsHistory,
            icon: Icons.headset_mic,
            screen: const HelpSupportScreen(),
          ),
        ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildHeroCard(context, currentUser, membershipLabel, l10n, kycStatus),
                    const SizedBox(height: 20),
                    if (currentUser.role == 'admin') ...[
                      _buildAdminButton(context, l10n),
                      const SizedBox(height: 16),
                    ],
                    _buildKycCard(context, kycStatus, l10n),
                    const SizedBox(height: 24),
                    Text(l10n.dashboard, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...actions.map(
                      (action) => _buildProfileTile(
                        context,
                        icon: action.icon,
                        title: action.title,
                        subtitle: action.subtitle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => action.screen),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- HELPERS --------------------

  Widget _buildHeroCard(
    BuildContext context,
    UserModel user,
    String membershipLabel,
    AppLocalizations l10n,
    String kycStatus,
  ) {
    final theme = Theme.of(context);
    
    // Determine badge content based on kycStatus
    final isVerified = kycStatus == 'approved' || kycStatus == 'verified';
    final isPending = kycStatus == 'pending';
    
    String statusLabel;
    IconData statusIcon;
    Color? statusColor;
    
    if (isVerified) {
      statusLabel = l10n.kycVerified;
      statusIcon = Icons.verified;
      statusColor = const Color(0xFF0F9D58);
    } else if (isPending) {
      statusLabel = l10n.kycPendingStatus;
      statusIcon = Icons.hourglass_bottom;
      statusColor = Colors.orange;
    } else {
       // 'not_submitted' or rejected or other
       statusLabel = 'Start KYC'; // Or localized string if available
       statusIcon = Icons.badge_outlined;
       statusColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF781C2E), Color(0xFF9E2F3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF781C2E).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileBadge(
                label: membershipLabel,
                icon: Icons.workspace_premium,
              ),
              _ProfileBadge(
                icon: statusIcon,
                iconColor: statusColor,
                label: statusLabel,
              ),
              _ProfileBadge(
                label: l10n.memberSince(user.createdAt.year),
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKycCard(BuildContext context, String kycStatus, AppLocalizations l10n) {
    final isVerified = kycStatus == 'approved' || kycStatus == 'verified';
    final isPending = kycStatus == 'pending';
    final isRejected = kycStatus == 'rejected';
    
    // Default color for Verified
    Color color = Colors.green;
    String title = l10n.identityVerified;
    String subtitle = l10n.fullAccess;
    IconData icon = Icons.verified;
    
    if (isVerified) {
       color = Colors.green;
       title = l10n.identityVerified;
       subtitle = l10n.fullAccess;
       icon = Icons.verified;
    } else if (isPending) {
       color = Colors.orange;
       title = l10n.kycPendingStatus;
       subtitle = 'Your documents are under review.'; 
       icon = Icons.hourglass_top;
    } else if (isRejected) {
       color = Colors.red;
       title = 'KYC Rejected';
       subtitle = 'Please resubmit valid documents.';
       icon = Icons.error_outline;
    } else {
       // not_submitted
       color = const Color(0xFF781C2E);
       title = l10n.verifyIdentity;
       subtitle = l10n.completeKyc;
       icon = Icons.badge_outlined;
    }

    // Determine the button or status indicator
    Widget actionWidget;
    if (isVerified) {
       actionWidget = const Icon(Icons.check_circle, color: Colors.green);
    } else if (isPending) {
       actionWidget = Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
         decoration: BoxDecoration(
           color: Colors.orange.withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.orange),
         ),
         child: const Text('Processing', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
       );
    } else {
       // Rejected or Not Submitted -> Show Start/Retry button
       actionWidget = ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KycScreen()),
            );
          },
          child: Text(isRejected ? 'Retry' : l10n.start),
       );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          actionWidget,
        ],
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings, color: Colors.white),
        title: Text(
          l10n.adminDashboard,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          l10n.adminSubtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        },
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.label, this.icon, this.iconColor});

  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final backgroundColor = isLight
        ? const Color(0xFFFFF4F0)
        : Colors.white.withOpacity(0.15);
    final borderColor = isLight ? const Color(0xFFFFCFC3) : Colors.white24;
    final textColor = isLight ? const Color(0xFF781C2E) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
