// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'रेंटल ऐप';

  @override
  String get home => 'होम';

  @override
  String get search => 'खोज';

  @override
  String get addListing => 'जोड़ें';

  @override
  String get rentals => 'रेंटल';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get systemMode => 'सिस्टम मोड';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'अंग्रेजी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get helpSupport => 'सहायता और समर्थन';

  @override
  String get myListings => 'मेरी लिस्टिंग';

  @override
  String get myRentals => 'मेरे रेंटल';

  @override
  String get favorites => 'पसंदीदा';

  @override
  String get paymentMethods => 'भुगतान विधियां';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get testNotification => 'टेस्ट नोटिफिकेशन';

  @override
  String get nearbyItems => 'आसपास की वस्तुएं';

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String get electronics => 'इलेक्ट्रॉनिक्स';

  @override
  String get vehicles => 'वाहन';

  @override
  String get sports => 'खेल';

  @override
  String get tools => 'औजार';

  @override
  String get furniture => 'फर्नीचर';

  @override
  String get clothing => 'कपड़े';

  @override
  String get noItemsFound => 'आसपास कोई वस्तु नहीं मिली';

  @override
  String get increaseRadiusHint => 'खोज दायरा बढ़ाने का प्रयास करें';

  @override
  String get enableLocationPrompt =>
      'आसपास की वस्तुएं देखने के लिए स्थान सक्षम करें';

  @override
  String get enable => 'सक्षम करें';

  @override
  String showingItemsWithin(int distance) {
    return '$distance किमी के भीतर वस्तु दिखा रहा है';
  }

  @override
  String get gettingLocation => 'आपका स्थान प्राप्त कर रहा है...';

  @override
  String get rentNow => 'अभी किराए पर लें';

  @override
  String get searchRadius => 'खोज त्रिज्या';

  @override
  String get done => 'हो गया';

  @override
  String get listItem => 'सूचीबद्ध करें';

  @override
  String get verifyIdentity => 'अभी पहचान सत्यापित करें';

  @override
  String current(int distance) {
    return 'वर्तमान: $distance किमी';
  }

  @override
  String get kycVerified => 'सत्यापित';

  @override
  String get kycPending => 'KYC सत्यापन लंबित है';

  @override
  String get adminDashboard => 'व्यवस्थापक डैशबोर्ड';

  @override
  String get personalizeExperience => 'अपना अनुभव निजीकृत करें';

  @override
  String get personalizeSubtitle =>
      'पसंदीदा, थीम और अलर्ट को आसानी से अपडेट करें।';

  @override
  String get account => 'खाता';

  @override
  String get preferences => 'पसंदीदा';

  @override
  String get session => 'सत्र';

  @override
  String get displayName => 'प्रदर्शन नाम';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get setPassword => 'पासवर्ड सेट करें';

  @override
  String get resetCredentials => 'साइन-इन क्रेडेंशियल रीसेट करें';

  @override
  String get createPassword => 'अपने खाते के लिए पासवर्ड बनाएं';

  @override
  String get reduceGlare => 'कम रोशनी के लिए चमक कम करें';

  @override
  String get themes => 'थीम';

  @override
  String get alerts => 'अलर्ट';

  @override
  String get signOutConfirmation => 'साइन आउट करें?';

  @override
  String get signOutMessage =>
      'अपने रेंटल तक पहुंचने के लिए आपको फिर से साइन इन करना होगा।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirmSignOut => 'साइन आउट';

  @override
  String get guestWelcome => 'आइए आपके अनुभव को निजीकृत करें';

  @override
  String get guestSubtitle =>
      'अपने रेंटल, लिस्टिंग, सपोर्ट टिकट और बहुत कुछ तक पहुंचने के लिए साइन इन करें।';

  @override
  String get signIn => 'साइन इन';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get manageListings => 'जो आप उधार देते हैं उसका प्रबंधन करें';

  @override
  String get trackRentals => 'सक्रिय बुकिंग ट्रैक करें';

  @override
  String get quickAccess => 'सहेजी गई वस्तुओं तक त्वरित पहुंच';

  @override
  String get walletsCards => 'वॉलेट और कार्ड';

  @override
  String get promotionsAlerts => 'प्रचार और अलर्ट';

  @override
  String get faqsHistory => 'अक्सर पूछे जाने वाले प्रश्न और टिकट इतिहास';

  @override
  String get identityVerified => 'पहचान सत्यापित';

  @override
  String get fullAccess => 'आप सभी सुविधाओं तक पूर्ण पहुंच रखते हैं।';

  @override
  String get completeKyc =>
      'लिस्टिंग और बुकिंग अनलॉक करने के लिए केवाईसी पूरा करें।';

  @override
  String get start => 'शुरू करें';

  @override
  String get adminSubtitle => 'रिपोर्ट की समीक्षा करें, लिस्टिंग को मंजूरी दें';

  @override
  String memberSince(int year) {
    return 'सदस्य $year से';
  }

  @override
  String get kycPendingStatus => 'केवाईसी लंबित';

  @override
  String get goodToSeeYou => 'आपको देखकर अच्छा लगा,';

  @override
  String heyGreeting(String name) {
    return 'हे $name';
  }

  @override
  String get deliveringCurated => 'आपके आसपास क्यूरेटेड रेंटल वितरित करना';

  @override
  String get enableLocationUnlock =>
      'हाइपर-लोकल परिणाम अनलॉक करने के लिए स्थान सक्षम करें';

  @override
  String get searchPlaceholder => 'कैमरा, कार, कपड़े, और बहुत कुछ खोजें...';

  @override
  String get goPremium => 'प्रीमियम बनें';

  @override
  String get locationOffMessage =>
      'स्थान बंद है। हम आपके पास ट्रेंडिंग पिक्स दिखा रहे हैं।';

  @override
  String curatedInventoryMessage(int radius) {
    return '$radius किमी के भीतर क्यूरेटेड इन्वेंट्री दिखा रहा है';
  }

  @override
  String get exploreCategories => 'श्रेणियों के अनुसार अन्वेषण करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String filteringInventory(String category) {
    return '$category इन्वेंट्री फ़िल्टर की जा रही है';
  }

  @override
  String get trendingNearby => 'आसपास ट्रेंडिंग';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get recommendedForYou => 'आपके लिए अनुशंसित';

  @override
  String pricePerDay(Object price) {
    return '₹$price/दिन';
  }

  @override
  String get messages => 'संदेश';

  @override
  String get book => 'बुक करें';

  @override
  String errorLoadingInventory(String error) {
    return 'इन्वेंट्री लोड करने में असमर्थ: $error';
  }

  @override
  String get signInToManageFavorites =>
      'पसंदीदा प्रबंधित करने के लिए साइन इन करें';

  @override
  String get map => 'नक्शा';
}
