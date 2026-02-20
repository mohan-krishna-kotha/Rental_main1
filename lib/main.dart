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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';

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

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const AddListingScreen(),
    const RentalsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
