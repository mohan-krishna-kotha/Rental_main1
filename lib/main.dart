import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/items_provider.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'features/add_listing/presentation/screens/add_listing_screen.dart';
import 'features/rentals/presentation/screens/rentals_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'features/rentals/presentation/providers/order_provider.dart';
import 'core/models/booking_request_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/navigation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Notification Service
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Save FCM token to Firestore when user signs in and listen for owner booking requests
    if (currentUser != null) {
      // Save token once when auth state becomes available
      ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) async {
        final user = next.asData?.value;
        if (user != null) {
          try {
            final token = await NotificationService().getFcmToken();
            if (token != null) {
              await ref
                  .read(firestoreServiceProvider)
                  .saveUserFcmToken(user.uid, token);
            }
          } catch (e) {
            debugPrint('Failed to save FCM token on sign-in: $e');
          }
        }
      });

      ref.listen<
        AsyncValue<List<BookingRequestModel>>
      >(ownerBookingRequestsProvider(currentUser.uid), (previous, next) {
        try {
          final prevList = previous?.asData?.value ?? [];
          final nextList = next.asData?.value ?? [];

          // If new requests were added, notify about the first new one
          if (nextList.length > prevList.length) {
            final newOnes = nextList.where(
              (r) => prevList.every((p) => p.id != r.id),
            );
            if (newOnes.isNotEmpty) {
              final r = newOnes.first;
              NotificationService().showInAppNotification(
                'New rental request',
                '${r.renterName ?? 'Someone'} requested ${r.productName ?? 'your item'}',
              );
            }
          } else if (prevList.isEmpty && nextList.isNotEmpty) {
            final r = nextList.first;
            NotificationService().showInAppNotification(
              'New rental request',
              '${r.renterName ?? 'Someone'} requested ${r.productName ?? 'your item'}',
            );
          }
        } catch (e) {
          debugPrint('Error while handling booking request notification: $e');
        }
      });
    }

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Rental App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isCreatingProfile = false;

  void _handleUserAuthentication(User user) async {
    if (_isCreatingProfile) return; // Prevent multiple calls

    setState(() => _isCreatingProfile = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Check if user already exists first
      final userExists = await firestoreService.userExistsInFirestore(user.uid);

      if (!userExists) {
        debugPrint('User not found in Firestore, creating profile...');
        await firestoreService.createUserProfile(user);

        // Verify creation was successful
        final nowExists = await firestoreService.userExistsInFirestore(
          user.uid,
        );
        debugPrint(
          'Auto-created user profile for: ${user.uid}, success: $nowExists',
        );
      }
    } catch (e) {
      debugPrint('Error in _handleUserAuthentication: $e');
    } finally {
      setState(() => _isCreatingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Trigger profile creation asynchronously
          if (!_isCreatingProfile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleUserAuthentication(user);
            });
          }
          return const MainNavigator();
        }
        return const AuthScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class MainNavigator extends ConsumerWidget {
  const MainNavigator({super.key});

  static final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const AddListingScreen(),
    const RentalsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).setIndex(index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.map,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: l10n.addListing,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.rentals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
