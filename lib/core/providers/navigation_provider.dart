import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A global notifier to manage the main navigation index (tabs).
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

/// Provider for the navigation index.
/// 0: Home, 1: Map, 2: Add Listing, 3: Rentals, 4: Profile
final navigationIndexProvider = NotifierProvider<NavigationNotifier, int>(() {
  return NavigationNotifier();
});
