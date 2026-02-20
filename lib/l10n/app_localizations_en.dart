// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rental App';

  @override
  String get home => 'Home';

  @override
  String get search => 'Discover';

  @override
  String get addListing => 'Add';

  @override
  String get rentals => 'Rentals';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System Mode';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get logout => 'Logout';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get myListings => 'My Listings';

  @override
  String get myRentals => 'My Rentals';

  @override
  String get favorites => 'Favorites';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get notifications => 'Notifications';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get nearbyItems => 'Nearby Items';

  @override
  String get categories => 'Categories';

  @override
  String get electronics => 'Electronics';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get sports => 'Sports';

  @override
  String get tools => 'Tools';

  @override
  String get furniture => 'Furniture';

  @override
  String get clothing => 'Clothing';

  @override
  String get noItemsFound => 'No items found nearby';

  @override
  String get increaseRadiusHint => 'Try increasing the search radius';

  @override
  String get enableLocationPrompt => 'Enable location to see nearby items';

  @override
  String get enable => 'Enable';

  @override
  String showingItemsWithin(int distance) {
    return 'Showing items within $distance km';
  }

  @override
  String get gettingLocation => 'Getting your location...';

  @override
  String get rentNow => 'Rent Now';

  @override
  String get searchRadius => 'Search Radius';

  @override
  String get done => 'Done';

  @override
  String get listItem => 'List Item';

  @override
  String get verifyIdentity => 'Verify Identity Now';

  @override
  String current(int distance) {
    return 'Current: $distance km';
  }

  @override
  String get kycVerified => 'Verified';

  @override
  String get kycPending => 'KYC Verification Pending';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get personalizeExperience => 'Personalize your experience';

  @override
  String get personalizeSubtitle =>
      'Update preferences, theme, and alerts seamlessly.';

  @override
  String get account => 'Account';

  @override
  String get preferences => 'Preferences';

  @override
  String get session => 'Session';

  @override
  String get displayName => 'Display Name';

  @override
  String get changePassword => 'Change Password';

  @override
  String get setPassword => 'Set Password';

  @override
  String get resetCredentials => 'Reset sign-in credentials';

  @override
  String get createPassword => 'Create a password for your account';

  @override
  String get reduceGlare => 'Reduce glare for low-light use';

  @override
  String get themes => 'Themes';

  @override
  String get alerts => 'Alerts';

  @override
  String get signOutConfirmation => 'Sign out?';

  @override
  String get signOutMessage =>
      'You will need to sign in again to access your rentals.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmSignOut => 'Sign out';

  @override
  String get guestWelcome => 'Let’s personalize your experience';

  @override
  String get guestSubtitle =>
      'Sign in to access your rentals, listings, support tickets and more.';

  @override
  String get signIn => 'Sign In';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get manageListings => 'Manage what you lend';

  @override
  String get trackRentals => 'Track active bookings';

  @override
  String get quickAccess => 'Quick access to saved items';

  @override
  String get walletsCards => 'Wallets & cards';

  @override
  String get promotionsAlerts => 'Promotions & alerts';

  @override
  String get faqsHistory => 'FAQs and ticket history';

  @override
  String get identityVerified => 'Identity verified';

  @override
  String get fullAccess => 'You have full access to all features.';

  @override
  String get completeKyc => 'Complete KYC to unlock listing & booking.';

  @override
  String get start => 'Start';

  @override
  String get adminSubtitle => 'Review reports, approve listings';

  @override
  String memberSince(int year) {
    return 'Member since $year';
  }

  @override
  String get kycPendingStatus => 'KYC Pending';

  @override
  String get goodToSeeYou => 'Good to see you,';

  @override
  String heyGreeting(String name) {
    return 'Hey $name';
  }

  @override
  String get deliveringCurated => 'Delivering curated rentals around you';

  @override
  String get enableLocationUnlock =>
      'Enable location to unlock hyper-local results';

  @override
  String get searchPlaceholder => 'Search cameras, cars, dresses, more...';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get locationOffMessage =>
      'Location off. We are showing trending picks near you.';

  @override
  String curatedInventoryMessage(int radius) {
    return 'Showing curated inventory within $radius km';
  }

  @override
  String get exploreCategories => 'Explore by categories';

  @override
  String get clear => 'Clear';

  @override
  String filteringInventory(String category) {
    return 'Filtering $category inventory';
  }

  @override
  String get trendingNearby => 'Trending nearby';

  @override
  String get seeAll => 'See all';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String pricePerDay(Object price) {
    return '₹$price/day';
  }

  @override
  String get messages => 'Messages';

  @override
  String get book => 'Book';

  @override
  String errorLoadingInventory(String error) {
    return 'Unable to load inventory: $error';
  }

  @override
  String get signInToManageFavorites => 'Sign in to manage favorites';

  @override
  String get map => 'Map';
}
