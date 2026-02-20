import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rental App'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get search;

  /// No description provided for @addListing.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addListing;

  /// No description provided for @rentals.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get rentals;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System Mode'**
  String get systemMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @myRentals.
  ///
  /// In en, this message translates to:
  /// **'My Rentals'**
  String get myRentals;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @nearbyItems.
  ///
  /// In en, this message translates to:
  /// **'Nearby Items'**
  String get nearbyItems;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @furniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get furniture;

  /// No description provided for @clothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get clothing;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found nearby'**
  String get noItemsFound;

  /// No description provided for @increaseRadiusHint.
  ///
  /// In en, this message translates to:
  /// **'Try increasing the search radius'**
  String get increaseRadiusHint;

  /// No description provided for @enableLocationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enable location to see nearby items'**
  String get enableLocationPrompt;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @showingItemsWithin.
  ///
  /// In en, this message translates to:
  /// **'Showing items within {distance} km'**
  String showingItemsWithin(int distance);

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get gettingLocation;

  /// No description provided for @rentNow.
  ///
  /// In en, this message translates to:
  /// **'Rent Now'**
  String get rentNow;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get searchRadius;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @listItem.
  ///
  /// In en, this message translates to:
  /// **'List Item'**
  String get listItem;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity Now'**
  String get verifyIdentity;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current: {distance} km'**
  String current(int distance);

  /// No description provided for @kycVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get kycVerified;

  /// No description provided for @kycPending.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification Pending'**
  String get kycPending;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @personalizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Personalize your experience'**
  String get personalizeExperience;

  /// No description provided for @personalizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update preferences, theme, and alerts seamlessly.'**
  String get personalizeSubtitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPassword;

  /// No description provided for @resetCredentials.
  ///
  /// In en, this message translates to:
  /// **'Reset sign-in credentials'**
  String get resetCredentials;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password for your account'**
  String get createPassword;

  /// No description provided for @reduceGlare.
  ///
  /// In en, this message translates to:
  /// **'Reduce glare for low-light use'**
  String get reduceGlare;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themes;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmation;

  /// No description provided for @signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access your rentals.'**
  String get signOutMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get confirmSignOut;

  /// No description provided for @guestWelcome.
  ///
  /// In en, this message translates to:
  /// **'Let’s personalize your experience'**
  String get guestWelcome;

  /// No description provided for @guestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your rentals, listings, support tickets and more.'**
  String get guestSubtitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @manageListings.
  ///
  /// In en, this message translates to:
  /// **'Manage what you lend'**
  String get manageListings;

  /// No description provided for @trackRentals.
  ///
  /// In en, this message translates to:
  /// **'Track active bookings'**
  String get trackRentals;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access to saved items'**
  String get quickAccess;

  /// No description provided for @walletsCards.
  ///
  /// In en, this message translates to:
  /// **'Wallets & cards'**
  String get walletsCards;

  /// No description provided for @promotionsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Promotions & alerts'**
  String get promotionsAlerts;

  /// No description provided for @faqsHistory.
  ///
  /// In en, this message translates to:
  /// **'FAQs and ticket history'**
  String get faqsHistory;

  /// No description provided for @identityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get identityVerified;

  /// No description provided for @fullAccess.
  ///
  /// In en, this message translates to:
  /// **'You have full access to all features.'**
  String get fullAccess;

  /// No description provided for @completeKyc.
  ///
  /// In en, this message translates to:
  /// **'Complete KYC to unlock listing & booking.'**
  String get completeKyc;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review reports, approve listings'**
  String get adminSubtitle;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {year}'**
  String memberSince(int year);

  /// No description provided for @kycPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'KYC Pending'**
  String get kycPendingStatus;

  /// No description provided for @goodToSeeYou.
  ///
  /// In en, this message translates to:
  /// **'Good to see you,'**
  String get goodToSeeYou;

  /// No description provided for @heyGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey {name}'**
  String heyGreeting(String name);

  /// No description provided for @deliveringCurated.
  ///
  /// In en, this message translates to:
  /// **'Delivering curated rentals around you'**
  String get deliveringCurated;

  /// No description provided for @enableLocationUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enable location to unlock hyper-local results'**
  String get enableLocationUnlock;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search cameras, cars, dresses, more...'**
  String get searchPlaceholder;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @locationOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Location off. We are showing trending picks near you.'**
  String get locationOffMessage;

  /// No description provided for @curatedInventoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Showing curated inventory within {radius} km'**
  String curatedInventoryMessage(int radius);

  /// No description provided for @exploreCategories.
  ///
  /// In en, this message translates to:
  /// **'Explore by categories'**
  String get exploreCategories;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @filteringInventory.
  ///
  /// In en, this message translates to:
  /// **'Filtering {category} inventory'**
  String filteringInventory(String category);

  /// No description provided for @trendingNearby.
  ///
  /// In en, this message translates to:
  /// **'Trending nearby'**
  String get trendingNearby;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @pricePerDay.
  ///
  /// In en, this message translates to:
  /// **'₹{price}/day'**
  String pricePerDay(Object price);

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @errorLoadingInventory.
  ///
  /// In en, this message translates to:
  /// **'Unable to load inventory: {error}'**
  String errorLoadingInventory(String error);

  /// No description provided for @signInToManageFavorites.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage favorites'**
  String get signInToManageFavorites;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
