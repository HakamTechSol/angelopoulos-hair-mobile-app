// localization_service.dart - Optimized version
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('el', 'GR');

  Locale get currentLocale => _currentLocale;

  static const List<Locale> supportedLocales = [
    Locale('el', 'GR'),
    Locale('en', 'US'),
    Locale('ro', 'RO'),
  ];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageKey) ?? 'el';

    _currentLocale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == savedLanguageCode,
      orElse: () => const Locale('el', 'GR'),
    );
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    final newLocale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('el', 'GR'),
    );

    if (newLocale != _currentLocale) {
      _currentLocale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedStrings = {
    'el': {
      // Core App
      'app_title': 'ANGELOPOULOS',
      'app_subtitle': 'REWARDS',
      'sign_in': 'ΣΥΝΔΕΣΗ',
      'welcome': 'Καλώς ήρθατε',
      'my_balance': 'Το υπόλοιπό μου',
      'points': 'Πόντοι',
      'loading': 'Φόρτωση...',
      'retry': 'Δοκιμή ξανά',
      'save': 'Αποθήκευση',
      'cancel': 'Ακύρωση',
      'close': 'Κλείσιμο',
      'confirm': 'Επιβεβαίωση',
      'back': 'Πίσω',
      'continue': 'Συνέχεια',
      'refresh': 'Ανανέωση',
      'error': 'Σφάλμα',

      // Auth & Profile
      'sign_in_subtitle': 'Συνδεθείτε με τον αριθμό τηλεφώνου σας',
      'phone_number': 'Αριθμός τηλεφώνου',
      'enter_phone': 'Εισάγετε τον αριθμό τηλεφώνου σας',
      'enter_phone_with_country_code': 'Εισάγετε τηλέφωνο με κωδικό χώρας',
      'email': 'Ηλεκτρονικό ταχυδρομείο',
      'password': 'Κωδικός πρόσβασης',
      'full_name': 'Ονοματεπώνυμο',
      'enter_full_name': 'Εισάγετε το πλήρες όνομά σας',
      'phone': 'Τηλέφωνο',
      'address': 'Διεύθυνση',
      'city': 'Πόλη',
      'zip': 'Ταχυδρομικός κώδικας',
      'sign_in_button': 'Σύνδεση',
      'sign_up': 'Εγγραφή',
      'create_account': 'Δημιουργία λογαριασμού',
      'no_account': 'Δεν έχετε λογαριασμό; ',
      'have_account': 'Έχετε ήδη λογαριασμό; ',
      'accept_terms': 'Αποδέχομαι τους',
      'i_accept': 'Αποδέχομαι',
      'terms_of_use': 'Όροι χρήσης',
      'privacy_policy': 'Πολιτική απορρήτου',
      'and': 'και',
      'account': 'Προφιλ',
      'personal_details': ' Προσωπικά δεδομένα ',
      'account_details': 'Επιπλέον δεδομένα',
      'account_created': 'Ημερομηνία δημιουργίας',
      'points_earned': 'Πόντοι',
      'points_redeemed': 'Εξαργυρώθηκαν',
      'edit': 'Επεξεργασία',
      'update_profile': 'Ενημέρωση',
      'logout': 'Αποσύνδεση',

      // OTP and Phone Verification
      'send_otp': 'Αποστολή OTP',
      'verify_otp': 'Επαλήθευση OTP',
      'enter_otp': 'Εισάγετε OTP',
      'enter_six_digit_otp': 'Εισάγετε 6-ψήφιο κωδικό OTP',
      'enter_six_digit_code': 'Εισάγετε 6-ψήφιο κωδικό',
      'sent_to': 'Στάλθηκε σε',
      'resend_otp': 'Επαναποστολή OTP',
      'resend_in': 'Επαναποστολή σε',
      'otp_sent': 'Ο κωδικός OTP στάλθηκε',
      'otp_resent': 'Ο κωδικός OTP εστάλη ξανά',
      'sending_otp': 'Αποστολή OTP...',
      'verifying_otp': 'Επαλήθευση OTP...',
      'creating_account': 'Δημιουργία λογαριασμού...',
      'phone_verified_success': 'Το τηλέφωνο επαληθεύτηκε με επιτυχία',
      'phone_verified_auto': 'Το τηλέφωνο επαληθεύτηκε αυτόματα',
      'phone_verified_creating':
          'Το τηλέφωνο επαληθεύτηκε. Δημιουργία λογαριασμού...',

      // Navigation
      'home': 'Αρχική',
      'rewards': 'Πόντοι',
      'scan': 'Σάρωση',
      'alerts': 'Alerts',
      'notifications': 'Alerts',

      // Home Screen
      'good_morning': 'Καλημέρα!',
      'good_afternoon': 'Καλό απόγευμα!',
      'good_evening': 'Καλησπέρα!',
      'welcome_text': 'Καλώς ήρθατε',
      'glow_more_earn_more': 'Λάμψε περισσότερο, κέρδισε περισσότερα!',
      'daily_beauty_rewards': 'Καθημερινές ανταμοιβές ομορφιάς',
      'discover_beauty_services': 'Ανακαλύψτε υπηρεσίες ομορφιάς',
      'discover_more': 'Ανακαλύψτε περισσότερα',
      'special_offers': 'Ειδικές προσφορές',
      'shop_now': 'Αγοράστε τώρα',
      'welcome_to_loyalty_rewards': 'Καλώς ήρθατε στο Loyalty Rewards',

      // Scan & QR
      'scan_receipt': 'Σάρωση απόδειξης',
      'go_back': 'Πίσω',
      'scan_your_receipt': 'Σαρώστε την απόδειξή σας',
      'earn_points':
          'Κερδίστε πόντους άμεσα και ξεκλειδώστε καταπληκτικές ανταμοιβές',
      'earn_points_instantly': 'Κερδίστε πόντους άμεσα',
      'start_scanning': 'ΞΕΚΙΝΗΣΤΕ ΣΑΡΩΣΗ',
      'scan_successful': 'Η σάρωση ήταν επιτυχής!',
      'processing': 'Επεξεργασία...',
      'position_qr': 'Τοποθετήστε τον κωδικό QR στο πλαίσιο',
      'position_qr_code': 'Τοποθετήστε τον κωδικό QR στο πλαίσιο',
      'got_it': 'Το κατάλαβα',
      'qr_scanner': 'Σαρωτής QR',
      'scanned': 'Σαρώθηκε',
      'qr_not_supported_web': 'Η σάρωση QR δεν υποστηρίζεται στον ιστό',
      'qr_scanner_not_available_web':
          'Ο σαρωτής QR δεν είναι διαθέσιμος στον ιστό',

      'processingReceipt': 'Επεξεργασία απόδειξης',
      'pleaseWaitDoNotClose': 'Παρακαλώ περιμένετε, μην κλείσετε την εφαρμογή',

      // Notifications
      'no_notifications': 'Δεν υπάρχουν ειδοποιήσεις',
      'notification_details': 'Λεπτομέρειες ειδοποίησης',
      'message_details': 'Λεπτομέρειες μηνύματος',
      'no_message_content': 'Δεν υπάρχει περιεχόμενο μηνύματος',
      'no_message_content_available':
          'Δεν υπάρχει διαθέσιμο περιεχόμενο μηνύματος',
      'no_title': 'Χωρίς τίτλο',
      'read': 'Αναγνωσμένο',
      'unread': 'Μη αναγνωσμένο',
      'new_rewards_added': 'Προστέθηκαν νέες ανταμοιβές!',
      'successful_redemption': 'Επιτυχής εξαργύρωση',
      'newsletter_title': 'Ενημερωτικό δελτίο',
      'failed_load_notifications': 'Αποτυχία φόρτωσης ειδοποιήσεων',
      'all_notifications_marked_read':
          'Όλες οι ειδοποιήσεις σημειώθηκαν ως αναγνωσμένες',
      'error_marking_read': 'Σφάλμα κατά την επισήμανση ως αναγνωσμένο',
      'failed_mark_read': 'Αποτυχία επισήμανσης ως αναγνωσμένο',

      // Language
      'language_selection': 'Επιλογή γλώσσας',
      'choose_language': 'Επιλέξτε γλώσσα',
      'change_language': 'Αλλαγή γλώσσας',
      'language_changed': 'Η γλώσσα άλλαξε με επιτυχία',
      'greek': 'Ελληνικά',
      'english': 'Αγγλικά',
      'romanian': 'Ρουμανικά',

      // Rewards & Products
      'no_rewards_available': 'Δεν υπάρχουν διαθέσιμες ανταμοιβές',
      'error_loading_rewards': 'Σφάλμα κατά τη φόρτωση ανταμοιβών',
      'loading_rewards_text': 'Φόρτωση ανταμοιβών...',
      'error_loading_rewards_title': 'Σφάλμα κατά τη φόρτωση ανταμοιβών',
      'load_more_products': 'Φόρτωση περισσότερων προϊόντων',
      'failed_to_load_image': 'Αποτυχία φόρτωσης εικόνας',
      'image_not_found': 'Η εικόνα δεν βρέθηκε',
      'image_not_available': 'Η εικόνα δεν είναι διαθέσιμη',

      // Form Validation
      'phone_required': 'Απαιτείται αριθμός τηλεφώνου',
      'phone_min_length':
          'Ο αριθμός τηλεφώνου πρέπει να έχει τουλάχιστον 10 ψηφία',
      'phone_too_long': 'Ο αριθμός τηλεφώνου είναι πολύ μεγάλος',
      'phone_digits_only': 'Ο αριθμός τηλεφώνου μπορεί να περιέχει μόνο ψηφία',
      'invalid_phone_format': 'Μη έγκυρη μορφή τηλεφώνου',
      'invalid_phone_format_country':
          'Μη έγκυρη μορφή τηλεφώνου για αυτή τη χώρα',
      'include_country_code': 'Συμπεριλάβετε τον κωδικό χώρας',
      'name_required': 'Απαιτείται όνομα',
      'name_min_length': 'Το όνομα πρέπει να έχει τουλάχιστον 2 χαρακτήρες',
      'name_letters_only': 'Το όνομα μπορεί να περιέχει μόνο γράμματα',
      'accept_terms_error': 'Παρακαλώ αποδεχτείτε τους όρους χρήσης',
      'fix_errors': 'Διορθώστε τα σφάλματα για να συνεχίσετε',

      // OTP Validation
      'otp_required': 'Απαιτείται κωδικός OTP',
      'otp_must_be_six_digits': 'Το OTP πρέπει να έχει 6 ψηφία',
      'otp_digits_only': 'Το OTP μπορεί να περιέχει μόνο ψηφία',
      'invalid_otp': 'Μη έγκυρος κωδικός OTP',
      'invalid_otp_check': 'Μη έγκυρος κωδικός OTP. Ελέγξτε και δοκιμάστε ξανά',
      'otp_expired': 'Ο κωδικός OTP έχει λήξει',
      'request_otp_first': 'Παρακαλώ ζητήστε πρώτα έναν κωδικό OTP',

      // Receipt Processing
      'no_receipt_found': 'Δεν βρέθηκε απόδειξη για αυτόν τον πελάτη',
      'bonus_applied': 'Το μπόνους εφαρμόστηκε με επιτυχία στην απόδειξη',
      'bonus_successfully_applied': 'Το μπόνους εφαρμόστηκε με επιτυχία',
      'failed_apply_bonus': 'Αποτυχία εφαρμογής μπόνους',
      'failed_to_apply_bonus': 'Αποτυχία εφαρμογής μπόνους',
      'error_applying_bonus': 'Σφάλμα κατά την εφαρμογή μπόνους',
      'failed_check_receipt': 'Αποτυχία ελέγχου απόδειξης. Κωδικός',
      'failed_to_check_receipt_code': 'Αποτυχία ελέγχου κωδικού απόδειξης',
      'error_checking_receipt': 'Σφάλμα κατά τον έλεγχο της απόδειξης',

      // Error Messages
      'user_not_exist': 'Ο χρήστης δεν υπάρχει!',
      'user_already_exists': 'Ο χρήστης υπάρχει ήδη',
      'configuration_error': 'Σφάλμα διαμόρφωσης. Επανεκκινήστε την εφαρμογή',
      'missing_config': 'Λείπει η διαμόρφωση. Επανεκκινήστε την εφαρμογή',
      'missing_configuration':
          'Λείπει η διαμόρφωση. Επανεκκινήστε την εφαρμογή',
      'license_failed': 'Αποτυχία ελέγχου άδειας',
      'login_failed': 'Η σύνδεση απέτυχε: Μη έγκυρα διαπιστευτήρια',
      'login_error': 'Σφάλμα σύνδεσης',
      'signup_failed': 'Η εγγραφή απέτυχε',
      'signup_error': 'Σφάλμα εγγραφής',
      'connection_error': 'Σφάλμα σύνδεσης',
      'server_error': 'Σφάλμα διακομιστή',
      'network_error': 'Σφάλμα δικτύου',
      'unknown_error': 'Άγνωστο σφάλμα',
      'request_timeout': 'Λήξη χρονικού ορίου αίτησης',
      'invalid_response_format': 'Μη έγκυρη μορφή απόκρισης',

      // Phone and OTP API Errors
      'failed_send_otp': 'Αποτυχία αποστολής OTP',
      'failed_send_otp_try_again': 'Αποτυχία αποστολής OTP. Δοκιμάστε ξανά',
      'failed_resend_otp': 'Αποτυχία επαναποστολής OTP',
      'error_sending_otp': 'Σφάλμα αποστολής OTP',
      'too_many_attempts': 'Πάρα πολλές προσπάθειες. Δοκιμάστε αργότερα',
      'sms_quota_exceeded': 'Το όριο SMS εξαντλήθηκε',
      'app_not_authorized': 'Η εφαρμογή δεν είναι εξουσιοδοτημένη',
      'recaptcha_failed': 'Η επαλήθευση reCAPTCHA απέτυχε',

      // User Management
      'failed_check_user': 'Αποτυχία ελέγχου χρήστη',
      'error_checking_user': 'Σφάλμα ελέγχου χρήστη',
      'checking_user': 'Έλεγχος χρήστη...',
      'signing_in': 'Σύνδεση...',
      'missing_user_credentials':
          'Λείπουν τα διαπιστευτήρια χρήστη. Παρακαλώ συνδεθείτε ξανά',
      'failed_load_user_data': 'Αποτυχία φόρτωσης δεδομένων χρήστη',
      'error_loading_user_name': 'Σφάλμα φόρτωσης ονόματος χρήστη',

      // Profile Management
      'select_profile_picture': 'Επιλέξτε φωτογραφία προφίλ',
      'camera': 'Κάμερα',
      'gallery': 'Συλλογή',
      'remove': 'Αφαίρεση',
      'processing_image': 'Επεξεργασία εικόνας...',
      'profile_picture_updated': 'Η φωτογραφία προφίλ ενημερώθηκε!',
      'profile_picture_removed': 'Η φωτογραφία προφίλ αφαιρέθηκε!',
      'profile_updated_successfully': 'Το προφίλ ενημερώθηκε με επιτυχία!',
      'failed_update_profile': 'Αποτυχία ενημέρωσης προφίλ',
      'image_size_too_large':
          'Το μέγεθος της εικόνας είναι πολύ μεγάλο. Επιλέξτε μικρότερη εικόνα',
      'image_encoding_failed': 'Αποτυχία κωδικοποίησης εικόνας',
      'failed_save_image': 'Αποτυχία αποθήκευσης εικόνας',
      'image_file_not_found': 'Το αρχείο εικόνας δεν βρέθηκε',

      // Logout
      'logged_out_successfully': 'Αποσυνδεθήκατε με επιτυχία!',
      'confirm_logout': 'Επιβεβαίωση αποσύνδεσης',
      'logout_confirmation': 'Είστε σίγουροι ότι θέλετε να αποσυνδεθείτε;',

      // Points and Balance
      'error_loading_points': 'Σφάλμα φόρτωσης πόντων',
      'loading_text': 'Φόρτωση...',
      'points_text': 'Πόντοι',
      'my_balance_text': 'Το υπόλοιπό μου',

      // Permissions
      'phone_permission_message':
          'Η άδεια τηλεφώνου βοηθά στην επαλήθευση της συσκευής σας. Μπορείτε να την ενεργοποιήσετε από τις ρυθμίσεις',

      // General UI Elements
      'enter': 'Εισάγετε',
      'not_available': 'Μη διαθέσιμο',
      'feature_coming_soon': 'Η λειτουργία έρχεται σύντομα',
      'developed_by': 'Αναπτύχθηκε από',
      'sku': 'Κωδικός προϊόντος',
      'none_text': 'Κανένα',

      // Debug Information
      'show_debug_info': 'Εμφάνιση πληροφοριών αποσφαλμάτωσης',
      'debug_information': 'Πληροφορίες αποσφαλμάτωσης',
      'last_error': 'Τελευταίο σφάλμα',
      'company_url_debug': 'Διεύθυνση URL εταιρείας (Αποσφαλμάτωση)',
      'software_type_debug': 'Τύπος λογισμικού (Αποσφαλμάτωση)',
      'client_id_debug': 'Αναγνωριστικό πελάτη (Αποσφαλμάτωση)',
      'trdr_debug': 'TRDR (Αποσφαλμάτωση)',
      'shared_preferences_debug': 'SharedPreferences (Αποσφαλμάτωση)',
      'missing_shared_preferences_values': 'Λείπουν τιμές SharedPreferences',
      'missing_shared_preferences_values_detailed':
          'Λείπουν λεπτομερείς τιμές SharedPreferences',
      'response_status_debug': 'Κατάσταση απόκρισης (Αποσφαλμάτωση)',
      'response_body_debug': 'Σώμα απόκρισης (Αποσφαλμάτωση)',
      'response_headers_debug': 'Κεφαλίδες απόκρισης (Αποσφαλμάτωση)',
      'api_call_debug_uri': 'URI κλήσης API (Αποσφαλμάτωση)',
      'request_body_debug': 'Σώμα αιτήματος (Αποσφαλμάτωση)',
      'access_denied_403': 'Η πρόσβαση απορρίφθηκε (403)',
      'service_not_found_404': 'Η υπηρεσία δεν βρέθηκε (404)',
      'server_error_500': 'Σφάλμα διακομιστή (500)',

      // URL and Link Handling
      'no_url_available': 'Δεν υπάρχει διαθέσιμο URL',
      'attempting_to_launch_url': 'Προσπάθεια εκκίνησης URL',
      'parsed_uri_debug': 'Αναλυμένο URI (Αποσφαλμάτωση)',
      'successfully_launched_url': 'Το URL εκκινήθηκε με επιτυχία',
      'failed_to_launch_url': 'Αποτυχία εκκίνησης URL',
      'error_launching_url': 'Σφάλμα εκκίνησης URL',
      'failed_to_open_link': 'Αποτυχία ανοίγματος συνδέσμου',

      // UI Labels for Debug/Admin
      'company_url_label': 'Διεύθυνση URL εταιρείας',
      'software_type_label': 'Τύπος λογισμικού',
      'client_id_label': 'Αναγνωριστικό πελάτη',
      'trdr_label': 'TRDR',
      'last_error_label': 'Τελευταίο σφάλμα',
      'retry_text': 'Επανάληψη',
      'refresh_text': 'Ανανέωση',
      'close_text': 'Κλείσιμο',
      'shop_now_text': 'Αγοράστε τώρα',
      'load_more_products_text': 'Φόρτωση περισσότερων προϊόντων',
      'debug_information_text': 'Πληροφορίες αποσφαλμάτωσης',
      'show_debug_info_text': 'Εμφάνιση πληροφοριών αποσφαλμάτωσης',
      'sku_text': 'Κωδικός προϊόντος',

      // 'deleteAccount': 'Διαγραφή Λογαριασμού',
      'deleteAccount': 'Διαγραφή Λογαριασμου ?',
      'deleteAccountWarning':
          'Είστε σίγουροι ότι θέλετε να διαγράψετε τον λογαριασμό σας;',
      'deleteAccountNote':
          '⚠️ Αυτή η ενέργεια δεν μπορεί να αναιρεθεί. Ο λογαριασμός σας θα διαγραφεί οριστικά.',
      'accountDeletionScheduled': 'Προγραμμ. Διαγραφή',
      'accountWillBeDeleted':
          'Ο λογαριασμός σας θα διαγραφεί οριστικά σε 7 ημέρες. Μπορείτε να ακυρώσετε αυτήν τη διαγραφή επικοινωνώντας με την υποστήριξη πριν από την ημερομηνία διαγραφής.',
      'failedDeleteAccount': 'Αποτυχία διαγραφής λογαριασμού',
      'okay': 'Εντάξει',
    },

    'en': {
      // Core App
      'app_title': 'ANGELOPOULOS',
      'app_subtitle': 'REWARDS',
      'welcome': 'Welcome',
      'sign_in': 'SIGN IN',
      'go_back': 'Go back',
      'my_balance': 'My Balance',
      'points': 'POINTS',
      'loading': 'Loading...',
      'retry': 'Retry',
      'save': 'Save',
      'cancel': 'Cancel',
      'close': 'Close',
      'confirm': 'Confirm',
      'back': 'Back',
      'continue': 'Continue',
      'refresh': 'Refresh',
      'error': 'Error',

      // Auth & Profile
      'sign_in_subtitle': 'Sign in with your phone number',
      'phone_number': 'Phone Number',
      'enter_phone': 'Enter your phone number',
      'enter_phone_with_country_code': 'Enter phone number with country code',
      'email': 'Email',
      'password': 'Password',
      'full_name': 'Full Name',
      'enter_full_name': 'Enter your full name',
      'phone': 'Phone',
      'address': 'Address',
      'city': 'City',
      'zip': 'Postal Code',
      'sign_in_button': 'Sign In',
      'sign_up': 'Sign Up',
      'create_account': 'Create Account',
      'no_account': 'Don\'t have an account? ',
      'have_account': 'Already have an account? ',
      'accept_terms': 'I accept the',
      'i_accept': 'I accept',
      'terms_of_use': 'Terms of Use',
      'privacy_policy': 'Privacy Policy',
      'and': 'and',
      'account': 'Account',
      'personal_details': 'Personal Details',
      'account_details': 'Account Details',
      'account_created': 'Account Created',
      'points_earned': 'Points Earned',
      'points_redeemed': 'Points Redeemed',
      'edit': 'Edit',
      'update_profile': 'Update Profile',
      'logout': 'Logout',

      // OTP and Phone Verification
      'send_otp': 'Send OTP',
      'verify_otp': 'Verify OTP',
      'enter_otp': 'Enter OTP',
      'enter_six_digit_otp': 'Enter 6-digit OTP code',
      'enter_six_digit_code': 'Enter 6-digit code',
      'sent_to': 'Sent to',
      'resend_otp': 'Resend OTP',
      'resend_in': 'Resend in',
      'otp_sent': 'OTP code sent',
      'otp_resent': 'OTP code resent',
      'sending_otp': 'Sending OTP...',
      'verifying_otp': 'Verifying OTP...',
      'creating_account': 'Creating account...',
      'phone_verified_success': 'Phone verified successfully',
      'phone_verified_auto': 'Phone verified automatically',
      'phone_verified_creating': 'Phone verified. Creating account...',

      // Navigation
      'home': 'Home',
      'rewards': 'Rewards',
      'scan': 'Scan',
      'alerts': 'Alerts',
      'notifications': 'Notifications',

      // Home Screen
      'good_morning': 'Good Morning!',
      'good_afternoon': 'Good Afternoon!',
      'good_evening': 'Good Evening!',
      'welcome_text': 'Welcome',
      'glow_more_earn_more': 'Glow More, Earn More!',
      'daily_beauty_rewards': 'Daily Beauty Rewards',
      'discover_beauty_services': 'Discover Beauty Services',
      'discover_more': 'Discover More',
      'special_offers': 'Special Offers',
      'shop_now': 'Shop Now',
      'welcome_to_loyalty_rewards': 'Welcome to Loyalty Rewards',

      // Scan & QR
      'scan_receipt': 'Scan Receipt',
      'scan_your_receipt': 'Scan your receipt',
      'earn_points': 'Earn points instantly and unlock amazing rewards',
      'earn_points_instantly': 'Earn points instantly',
      'start_scanning': 'START SCANNING',
      'scan_successful': 'Scan Successful!',
      'processing': 'Processing...',
      'position_qr': 'Position QR code within the frame',
      'position_qr_code': 'Position QR code in frame',
      'got_it': 'Got It',
      'qr_scanner': 'QR Scanner',
      'scanned': 'Scanned',
      'qr_not_supported_web': 'QR scanning not supported on web',
      'qr_scanner_not_available_web': 'QR scanner not available on web',
      'processingReceipt': 'Processing Receipt',
      'pleaseWaitDoNotClose': 'Please wait, do not close the app',

      // Notifications
      'no_notifications': 'No notifications',
      'notification_details': 'Notification Details',
      'message_details': 'Message Details',
      'no_message_content': 'No message content',
      'no_message_content_available': 'No message content available',
      'no_title': 'No Title',
      'read': 'Read',
      'unread': 'Unread',
      'new_rewards_added': 'New Rewards Have Been Added!',
      'successful_redemption': 'Successful Redemption',
      'newsletter_title': 'Newsletter',
      'failed_load_notifications': 'Failed to load notifications',
      'all_notifications_marked_read': 'All notifications marked as read',
      'error_marking_read': 'Error marking as read',
      'failed_mark_read': 'Failed to mark as read',

      // Language
      'language_selection': 'Language Selection',
      'choose_language': 'Select language',
      'change_language': 'Change Language',
      'language_changed': 'Language changed successfully',
      'greek': 'Greek',
      'english': 'English',
      'romanian': 'Romanian',

      // Rewards & Products
      'no_rewards_available': 'No rewards available',
      'error_loading_rewards': 'Error Loading Rewards',
      'loading_rewards_text': 'Loading rewards...',
      'error_loading_rewards_title': 'Error Loading Rewards',
      'load_more_products': 'Load More Products',
      'failed_to_load_image': 'Failed to load image',
      'image_not_found': 'Image not found',
      'image_not_available': 'Image not available',

      // Form Validation
      'phone_required': 'Phone number is required',
      'phone_min_length': 'Phone number must be at least 10 digits',
      'phone_too_long': 'Phone number is too long',
      'phone_digits_only': 'Phone number can only contain digits',
      'invalid_phone_format': 'Invalid phone number format',
      'invalid_phone_format_country':
          'Invalid phone number format for this country',
      'include_country_code': 'Include country code',
      'name_required': 'Name is required',
      'name_min_length': 'Name must be at least 2 characters',
      'name_letters_only': 'Name can only contain letters',
      'accept_terms_error': 'Please accept the terms of use',
      'fix_errors': 'Fix errors to continue',

      // OTP Validation
      'otp_required': 'OTP code is required',
      'otp_must_be_six_digits': 'OTP must be 6 digits',
      'otp_digits_only': 'OTP can only contain digits',
      'invalid_otp': 'Invalid OTP code',
      'invalid_otp_check': 'Invalid OTP code. Check and try again',
      'otp_expired': 'OTP code has expired',
      'request_otp_first': 'Please request an OTP code first',

      // Receipt Processing
      'no_receipt_found': 'No receipt found for this customer',
      'bonus_applied': 'Bonus successfully applied to receipt',
      'bonus_successfully_applied': 'Bonus successfully applied',
      'failed_apply_bonus': 'Failed to apply bonus',
      'failed_to_apply_bonus': 'Failed to apply bonus',
      'error_applying_bonus': 'Error applying bonus',
      'failed_check_receipt': 'Failed to check receipt. Code',
      'failed_to_check_receipt_code': 'Failed to check receipt code',
      'error_checking_receipt': 'Error checking receipt',

      // Error Messages
      'user_not_exist': 'User does not exist!',
      'user_already_exists': 'User already exists',
      'configuration_error': 'Configuration error. Please restart app',
      'missing_config': 'Missing configuration. Please restart the app',
      'missing_configuration': 'Missing configuration. Please restart the app',
      'license_failed': 'License check failed',
      'login_failed': 'Login failed: Invalid credentials',
      'login_error': 'Login error',
      'signup_failed': 'Signup failed',
      'signup_error': 'Signup error',
      'connection_error': 'Connection error',
      'server_error': 'Server error',
      'network_error': 'Network error',
      'unknown_error': 'Unknown error',
      'request_timeout': 'Request timeout',
      'invalid_response_format': 'Invalid response format',

      // Phone and OTP API Errors
      'failed_send_otp': 'Failed to send OTP',
      'failed_send_otp_try_again': 'Failed to send OTP. Try again',
      'failed_resend_otp': 'Failed to resend OTP',
      'error_sending_otp': 'Error sending OTP',
      'too_many_attempts': 'Too many attempts. Try later',
      'sms_quota_exceeded': 'SMS quota exceeded',
      'app_not_authorized': 'App not authorized',
      'recaptcha_failed': 'reCAPTCHA verification failed',

      // User Management
      'failed_check_user': 'Failed to check user',
      'error_checking_user': 'Error checking user',
      'checking_user': 'Checking User...',
      'signing_in': 'Signing in...',
      'missing_user_credentials':
          'Missing user credentials. Please login again',
      'failed_load_user_data': 'Failed to load user data',
      'error_loading_user_name': 'Error loading user name',

      // Profile Management
      'select_profile_picture': 'Select Profile Picture',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'remove': 'Remove',
      'processing_image': 'Processing image...',
      'profile_picture_updated': 'Profile picture updated!',
      'profile_picture_removed': 'Profile picture removed!',
      'profile_updated_successfully': 'Profile updated successfully!',
      'failed_update_profile': 'Failed to update profile',
      'image_size_too_large':
          'Image size too large. Please select a smaller image',
      'image_encoding_failed': 'Image encoding failed',
      'failed_save_image': 'Failed to save image',
      'image_file_not_found': 'Image file not found',

      // Logout
      'logged_out_successfully': 'Logged out successfully!',
      'confirm_logout': 'Confirm Logout',
      'logout_confirmation': 'Are you sure you want to logout?',

      // Points and Balance
      'error_loading_points': 'Error loading points',
      'loading_text': 'Loading...',
      'points_text': 'Points',
      'my_balance_text': 'My Balance',

      // Permissions
      'phone_permission_message':
          'Phone permission helps verify your device. You can enable it in settings',

      // General UI Elements
      'enter': 'Enter',
      'not_available': 'Not Available',
      'feature_coming_soon': 'Feature coming soon',
      'developed_by': 'Developed by',
      'sku': 'SKU',
      'none_text': 'None',

      // Debug Information
      'show_debug_info': 'Show Debug Info',
      'debug_information': 'Debug Information',
      'last_error': 'Last Error',
      'company_url_debug': 'Company URL (Debug)',
      'software_type_debug': 'Software Type (Debug)',
      'client_id_debug': 'Client ID (Debug)',
      'trdr_debug': 'TRDR (Debug)',
      'shared_preferences_debug': 'SharedPreferences (Debug)',
      'missing_shared_preferences_values': 'Missing SharedPreferences values',
      'missing_shared_preferences_values_detailed':
          'Missing detailed SharedPreferences values',
      'response_status_debug': 'Response Status (Debug)',
      'response_body_debug': 'Response Body (Debug)',
      'response_headers_debug': 'Response Headers (Debug)',
      'api_call_debug_uri': 'API Call URI (Debug)',
      'request_body_debug': 'Request Body (Debug)',
      'access_denied_403': 'Access denied (403)',
      'service_not_found_404': 'Service not found (404)',
      'server_error_500': 'Server error (500)',

      // URL and Link Handling
      'no_url_available': 'No URL available',
      'attempting_to_launch_url': 'Attempting to launch URL',
      'parsed_uri_debug': 'Parsed URI (Debug)',
      'successfully_launched_url': 'Successfully launched URL',
      'failed_to_launch_url': 'Failed to launch URL',
      'error_launching_url': 'Error launching URL',
      'failed_to_open_link': 'Failed to open link',

      // UI Labels for Debug/Admin
      'company_url_label': 'Company URL',
      'software_type_label': 'Software Type',
      'client_id_label': 'Client ID',
      'trdr_label': 'TRDR',
      'last_error_label': 'Last Error',
      'retry_text': 'Retry',
      'refresh_text': 'Refresh',
      'close_text': 'Close',
      'shop_now_text': 'Shop Now',
      'load_more_products_text': 'Load More Products',
      'debug_information_text': 'Debug Information',
      'show_debug_info_text': 'Show Debug Info',
      'sku_text': 'SKU',

      'deleteAccount': 'Delete Account ?',
      'deleteAccountWarning': 'Are you sure you want to delete your account?',
      'deleteAccountNote':
          '⚠️ This action cannot be undone. Your account will be permanently deleted',
      'accountDeletionScheduled': 'Deletion Scheduled',
      'accountWillBeDeleted':
          'Your account will be permanently deleted in 7 days. You can cancel this by contacting support before the deletion date.',
      'failedDeleteAccount': 'Failed to delete account',
      'okay': 'Okay',
    },
    'ro': {
      // Core App
      'app_title': 'ANGELOPOULOS',
      'app_subtitle': 'REWARDS',
      'sign_in': 'CONECTARE',
      'welcome': 'Bun venit',
      'my_balance': 'Balanta mea',
      'points': 'PUNCTE',
      'loading': 'Se încarcă...',
      'retry': 'Reîncercare',
      'save': 'Salvează',
      'cancel': 'Anulează',
      'close': 'Închide',
      'confirm': 'Confirmă',
      'back': 'Înapoi',
      'continue': 'Continuă',
      'refresh': 'Reîmprospătare',
      'error': 'Eroare',

      // Auth & Profile
      'sign_in_subtitle': 'Conectați-vă cu numărul dvs. de telefon',
      'phone_number': 'Număr de Telefon',
      'enter_phone': 'Introduceți numărul dvs. de telefon',
      'enter_phone_with_country_code': 'Introduceți telefonul cu codul țării',
      'email': 'Email',
      'password': 'Parolă',
      'full_name': 'Nume Complet',
      'enter_full_name': 'Introduceți numele complet',
      'phone': 'Telefon',
      'address': 'Adresă',
      'city': 'Oraș',
      'zip': 'Cod Poștal',
      'sign_in_button': 'Conectare',
      'sign_up': 'Înregistrare',
      'create_account': 'Creare Cont',
      'no_account': 'Nu aveți cont? ',
      'have_account': 'Aveți deja un cont? ',
      'accept_terms': 'Accept',
      'i_accept': 'Accept',
      'terms_of_use': 'termenii de utilizare',
      'privacy_policy': 'politica de confidențialitate',
      'and': 'și',
      'account': 'Cont',
      'go_back': 'Înapoi',
      'personal_details': 'Detalii Personale',
      'account_details': 'Detalii Cont',
      'account_created': 'Cont Creat',
      'points_earned': 'Puncte Câștigate',
      'points_redeemed': 'Puncte Răscumpărate',
      'edit': 'Editează',
      'update_profile': 'Actualizează Profilul',
      'logout': 'Deconectare',

      // OTP and Phone Verification
      'send_otp': 'Trimite OTP',
      'verify_otp': 'Verifică OTP',
      'enter_otp': 'Introduceți OTP',
      'enter_six_digit_otp': 'Introduceți codul OTP de 6 cifre',
      'enter_six_digit_code': 'Introduceți codul de 6 cifre',
      'sent_to': 'Trimis la',
      'resend_otp': 'Retrimite OTP',
      'resend_in': 'Retrimite în',
      'otp_sent': 'Codul OTP a fost trimis',
      'otp_resent': 'Codul OTP a fost retrimis',
      'sending_otp': 'Trimitere OTP...',
      'verifying_otp': 'Verificare OTP...',
      'creating_account': 'Creare cont...',
      'phone_verified_success': 'Telefonul a fost verificat cu succes',
      'phone_verified_auto': 'Telefonul a fost verificat automat',
      'phone_verified_creating': 'Telefon verificat. Creare cont...',

      // Navigation
      'home': 'Acasă',
      'rewards': 'puncte',
      'scan': 'Scanează',
      'alerts': 'Alerte',
      'notifications': 'Notificări',

      // Home Screen
      'good_morning': 'Bună dimineața!',
      'good_afternoon': 'Bună ziua!',
      'good_evening': 'Bună seara!',
      'welcome_text': 'Bun venit',
      'glow_more_earn_more': 'Strălucește Mai Mult, Câștigă Mai Mult!',
      'daily_beauty_rewards': 'Recompense de Frumusețe Zilnice',
      'discover_beauty_services': 'Descoperă Serviciile de Frumusețe',
      'discover_more': 'Descoperă Mai Mult',
      'special_offers': 'Oferte Speciale',
      'shop_now': 'Cumpără Acum',
      'welcome_to_loyalty_rewards': 'Bun venit la Programul de Fidelitate',

      // Scan & QR
      'scan_receipt': 'Scanează Chitanța',
      'scan_your_receipt': 'Scanează chitanța',
      'earn_points':
          'Câștigă puncte instantaneu și deblochează recompense uimitoare',
      'earn_points_instantly': 'Câștigă puncte instantaneu',
      'start_scanning': 'ÎNCEPE SCANAREA',
      'scan_successful': 'Scanare Reușită!',
      'processing': 'Procesare...',
      'position_qr': 'Poziționați codul QR în cadru',
      'position_qr_code': 'Poziționați codul QR în cadru',
      'got_it': 'Am înțeles',
      'qr_scanner': 'Scaner QR',
      'scanned': 'Scanat',
      'qr_not_supported_web': 'Scanarea QR nu este suportată pe web',
      'qr_scanner_not_available_web': 'Scanerul QR nu este disponibil pe web',
      'processingReceipt': 'Procesare chitanță',
      'pleaseWaitDoNotClose': 'Vă rugăm să așteptați, nu închideți aplicația',

      // Notifications
      'no_notifications': 'Nicio notificare',
      'notification_details': 'Detalii Notificare',
      'message_details': 'Detalii Mesaj',
      'no_message_content': 'Fără conținut mesaj',
      'no_message_content_available': 'Nu există conținut de mesaj disponibil',
      'no_title': 'Fără Titlu',
      'read': 'Citit',
      'unread': 'Necitit',
      'new_rewards_added': 'Au fost Adăugate Recompense Noi!',
      'successful_redemption': 'Răscumpărare Reușită',
      'newsletter_title': 'Buletin Informativ',
      'failed_load_notifications': 'Eșec la încărcarea notificărilor',
      'all_notifications_marked_read':
          'Toate notificările au fost marcate ca citite',
      'error_marking_read': 'Eroare la marcarea ca citit',
      'failed_mark_read': 'Eșec la marcarea ca citit',

      // Language
      'language_selection': 'Selectare Limbă',
      'choose_language': 'Selectați limba',
      'change_language': 'Schimbă Limba',
      'language_changed': 'Limba a fost schimbată cu succes',
      'greek': 'Ελληνικά',
      'english': 'English',
      'romanian': 'Română',

      // Rewards & Products
      'no_rewards_available': 'Nicio recompensă disponibilă',
      'error_loading_rewards': 'Eroare la Încărcarea Recompenselor',
      'loading_rewards_text': 'Încărcare recompense...',
      'error_loading_rewards_title': 'Eroare la Încărcarea Recompenselor',
      'load_more_products': 'Încarcă Mai Multe Produse',
      'failed_to_load_image': 'Nu s-a putut încărca imaginea',
      'image_not_found': 'Imaginea nu a fost găsită',
      'image_not_available': 'Imaginea nu este disponibilă',

      // Form Validation
      'phone_required': 'Numărul de telefon este obligatoriu',
      'phone_min_length':
          'Numărul de telefon trebuie să aibă cel puțin 10 cifre',
      'phone_too_long': 'Numărul de telefon este prea lung',
      'phone_digits_only': 'Numărul de telefon poate conține doar cifre',
      'invalid_phone_format': 'Format număr de telefon invalid',
      'invalid_phone_format_country':
          'Format număr de telefon invalid pentru această țară',
      'include_country_code': 'Includeți codul țării',
      'name_required': 'Numele este obligatoriu',
      'name_min_length': 'Numele trebuie să aibă cel puțin 2 caractere',
      'name_letters_only': 'Numele poate conține doar litere',
      'accept_terms_error': 'Vă rugăm să acceptați termenii de utilizare',
      'fix_errors': 'Corectați erorile pentru a continua',

      // OTP Validation
      'otp_required': 'Codul OTP este obligatoriu',
      'otp_must_be_six_digits': 'OTP trebuie să fie de 6 cifre',
      'otp_digits_only': 'OTP poate conține doar cifre',
      'invalid_otp': 'Cod OTP invalid',
      'invalid_otp_check': 'Cod OTP invalid. Verificați și încercați din nou',
      'otp_expired': 'Codul OTP a expirat',
      'request_otp_first': 'Vă rugăm să solicitați mai întâi un cod OTP',

      // Receipt Processing
      'no_receipt_found': 'Nu s-a găsit nicio chitanță pentru acest client',
      'bonus_applied': 'Bonus aplicat cu succes chitanței',
      'bonus_successfully_applied': 'Bonus aplicat cu succes',
      'failed_apply_bonus': 'Nu s-a putut aplica bonusul',
      'failed_to_apply_bonus': 'Nu s-a putut aplica bonusul',
      'error_applying_bonus': 'Eroare la aplicarea bonusului',
      'failed_check_receipt': 'Verificarea chitanței a eșuat. Cod',
      'failed_to_check_receipt_code': 'Nu s-a putut verifica codul chitanței',
      'error_checking_receipt': 'Eroare la verificarea chitanței',

      // Error Messages
      'user_not_exist': 'Utilizatorul nu există!',
      'user_already_exists': 'Utilizatorul există deja',
      'configuration_error':
          'Eroare de configurare. Vă rugăm reporniți aplicația',
      'missing_config': 'Lipsă configurare. Vă rugăm reporniți aplicația',
      'missing_configuration':
          'Lipsă configurare. Vă rugăm reporniți aplicația',
      'license_failed': 'Verificarea licenței a eșuat',
      'login_failed': 'Conectare eșuată: Credențiale invalide',
      'login_error': 'Eroare la conectare',
      'signup_failed': 'Înregistrare eșuată',
      'signup_error': 'Eroare la înregistrare',
      'connection_error': 'Eroare de conexiune',
      'server_error': 'Eroare de server',
      'network_error': 'Eroare de rețea',
      'unknown_error': 'Eroare necunoscută',
      'request_timeout': 'Timeout cerere',
      'invalid_response_format': 'Format răspuns invalid',

      // Phone and OTP API Errors
      'failed_send_otp': 'Nu s-a putut trimite OTP',
      'failed_send_otp_try_again':
          'Nu s-a putut trimite OTP. Încercați din nou',
      'failed_resend_otp': 'Nu s-a putut retrimite OTP',
      'error_sending_otp': 'Eroare la trimiterea OTP',
      'too_many_attempts': 'Prea multe încercări. Încercați mai târziu',
      'sms_quota_exceeded': 'Cota SMS depășită',
      'app_not_authorized': 'Aplicație neautorizată',
      'recaptcha_failed': 'Verificarea reCAPTCHA a eșuat',

      // User Management
      'failed_check_user': 'Nu s-a putut verifica utilizatorul',
      'error_checking_user': 'Eroare la verificarea utilizatorului',
      'checking_user': 'Verificare Utilizator...',
      'signing_in': 'Se conectează...',
      'missing_user_credentials':
          'Lipsesc datele de autentificare. Vă rugăm să vă conectați din nou',
      'failed_load_user_data': 'Nu s-au putut încărca datele utilizatorului',
      'error_loading_user_name': 'Eroare la încărcarea numelui utilizatorului',

      // Profile Management
      'select_profile_picture': 'Selectează Imagine Profil',
      'camera': 'Cameră',
      'gallery': 'Galerie',
      'remove': 'Șterge',
      'processing_image': 'Procesare imagine...',
      'profile_picture_updated': 'Imaginea de profil a fost actualizată!',
      'profile_picture_removed': 'Imaginea de profil a fost ștearsă!',
      'profile_updated_successfully': 'Profil actualizat cu succes!',
      'failed_update_profile': 'Nu s-a putut actualiza profilul',
      'image_size_too_large':
          'Imaginea este prea mare. Vă rugăm selectați o imagine mai mică',
      'image_encoding_failed': 'Codificarea imaginii a eșuat',
      'failed_save_image': 'Salvarea imaginii a eșuat',
      'image_file_not_found': 'Fișierul imagine nu a fost găsit',

      // Logout
      'logged_out_successfully': 'Deconectat cu succes!',
      'confirm_logout': 'Confirmă Deconectarea',
      'logout_confirmation': 'Sigur doriți să vă deconectați?',

      // Points and Balance
      'error_loading_points': 'Eroare la încărcarea punctelor',
      'loading_text': 'Se încarcă...',
      'points_text': 'Puncte',
      'my_balance_text': 'Balanta mea',

      // Permissions
      'phone_permission_message':
          'Permisiunea de telefon ajută la verificarea dispozitivului dvs. O puteți activa în setări',

      // General UI Elements
      'enter': 'Introduceți',
      'not_available': 'Indisponibil',
      'feature_coming_soon': 'Funcționalitatea va fi disponibilă în curând',
      'developed_by': 'Dezvoltat de',
      'sku': 'Cod Produs',
      'none_text': 'Niciunul',

      // Debug Information
      'show_debug_info': 'Afișează Informații Debug',
      'debug_information': 'Informații Debug',
      'last_error': 'Ultima Eroare',
      'company_url_debug': 'URL Companie (Debug)',
      'software_type_debug': 'Tip Software (Debug)',
      'client_id_debug': 'ID Client (Debug)',
      'trdr_debug': 'TRDR (Debug)',
      'shared_preferences_debug': 'SharedPreferences (Debug)',
      'missing_shared_preferences_values': 'Lipsesc valorile SharedPreferences',
      'missing_shared_preferences_values_detailed':
          'Lipsesc valorile detaliate SharedPreferences',
      'response_status_debug': 'Status Răspuns (Debug)',
      'response_body_debug': 'Corp Răspuns (Debug)',
      'response_headers_debug': 'Headere Răspuns (Debug)',
      'api_call_debug_uri': 'URI Apel API (Debug)',
      'request_body_debug': 'Corp Cerere (Debug)',
      'access_denied_403': 'Acces interzis (403)',
      'service_not_found_404': 'Serviciul nu a fost găsit (404)',
      'server_error_500': 'Eroare server (500)',

      // URL and Link Handling
      'no_url_available': 'Nicio adresă URL disponibilă',
      'attempting_to_launch_url': 'Încercare lansare URL',
      'parsed_uri_debug': 'URI Analizat (Debug)',
      'successfully_launched_url': 'URL lansat cu succes',
      'failed_to_launch_url': 'Eșec la lansarea URL',
      'error_launching_url': 'Eroare la lansarea URL',
      'failed_to_open_link': 'Eșec la deschiderea linkului',

      // UI Labels for Debug/Admin
      'company_url_label': 'URL Companie',
      'software_type_label': 'Tip Software',
      'client_id_label': 'ID Client',
      'trdr_label': 'TRDR',
      'last_error_label': 'Ultima Eroare',
      'retry_text': 'Reîncercare',
      'refresh_text': 'Reîmprospătare',
      'close_text': 'Închide',
      'shop_now_text': 'Cumpără Acum',
      'load_more_products_text': 'Încarcă Mai Multe Produse',
      'debug_information_text': 'Informații Debug',
      'show_debug_info_text': 'Afișează Info Debug',
      'sku_text': 'SKU',

      'deleteAccount': 'Ștergere Cont ?',
      'deleteAccountWarning': 'Sigur doriți să vă ștergeți contul?',
      'deleteAccountNote':
          '⚠️ Această acțiune nu poate fi anulată. Contul dvs. va fi șters definitiv.',
      'accountDeletionScheduled': 'Ștergere Programată',
      'accountWillBeDeleted':
          'Contul dvs. va fi șters definitiv în 7 zile. Puteți anula acest lucru contactând suportul înainte de data ștergerii.',
      'failedDeleteAccount': 'Ștergerea contului a eșuat',
      'okay': 'Bine',
    },
  };

  String translate(String key) {
    return _localizedStrings[locale.languageCode]?[key] ??
        _localizedStrings['el']![key] ??
        key;
  }

  // Core getters
  String get appTitle => translate('app_title');
  String get appSubtitle => translate('app_subtitle');
  String get signIn => translate('sign_in');
  String get welcome => translate('welcome');
  String get myBalance => translate('my_balance');
  String get points => translate('points');
  String get loading => translate('loading');
  String get retry => translate('retry');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get close => translate('close');
  String get confirm => translate('confirm');
  String get back => translate('back');
  String get continueText => translate('continue');
  String get refresh => translate('refresh');
  String get error => translate('error');

  // Auth & Profile
  String get signInSubtitle => translate('sign_in_subtitle');
  String get phoneNumber => translate('phone_number');
  String get enterPhone => translate('enter_phone');
  String get enterPhoneWithCountryCode =>
      translate('enter_phone_with_country_code');
  String get email => translate('email');
  String get password => translate('password');
  String get fullName => translate('full_name');
  String get enterFullName => translate('enter_full_name');
  String get phone => translate('phone');
  String get address => translate('address');
  String get city => translate('city');
  String get zip => translate('zip');
  String get signInButton => translate('sign_in_button');
  String get signUp => translate('sign_up');
  String get createAccount => translate('create_account');
  String get noAccount => translate('no_account');
  String get haveAccount => translate('have_account');
  String get acceptTerms => translate('accept_terms');
  String get iAccept => translate('i_accept');
  String get termsOfUse => translate('terms_of_use');
  String get privacyPolicy => translate('privacy_policy');
  String get and => translate('and');
  String get account => translate('account');
  String get personalDetails => translate('personal_details');
  String get accountDetails => translate('account_details');
  String get accountCreated => translate('account_created');
  String get pointsEarned => translate('points_earned');
  String get pointsRedeemed => translate('points_redeemed');
  String get edit => translate('edit');
  String get updateProfile => translate('update_profile');
  String get logout => translate('logout');

  // OTP and Phone Verification
  String get sendOtp => translate('send_otp');
  String get verifyOtp => translate('verify_otp');
  String get enterOtp => translate('enter_otp');
  String get enterSixDigitOtp => translate('enter_six_digit_otp');
  String get enterSixDigitCode => translate('enter_six_digit_code');
  String get sentTo => translate('sent_to');
  String get resendOtp => translate('resend_otp');
  String get resendIn => translate('resend_in');
  String get otpSent => translate('otp_sent');
  String get otpResent => translate('otp_resent');
  String get sendingOtp => translate('sending_otp');
  String get verifyingOtp => translate('verifying_otp');
  String get creatingAccount => translate('creating_account');
  String get phoneVerifiedSuccess => translate('phone_verified_success');
  String get phoneVerifiedAuto => translate('phone_verified_auto');
  String get phoneVerifiedCreating => translate('phone_verified_creating');
  String get requestTimeoutServer => translate('phone_verified_creating');

  // Navigation
  String get home => translate('home');
  String get rewards => translate('rewards');
  String get scan => translate('scan');
  String get alerts => translate('alerts');
  String get notifications => translate('notifications');

  // Home Screen
  String get goodMorning => translate('good_morning');
  String get goodAfternoon => translate('good_afternoon');
  String get goodEvening => translate('good_evening');
  String get welcomeText => translate('welcome_text');
  String get glowMoreEarnMore => translate('glow_more_earn_more');
  String get dailyBeautyRewards => translate('daily_beauty_rewards');
  String get discoverBeautyServices => translate('discover_beauty_services');
  String get discoverMore => translate('discover_more');
  String get specialOffers => translate('special_offers');
  String get shopNow => translate('shop_now');
  String get welcomeToLoyaltyRewards => translate('welcome_to_loyalty_rewards');

  // Scan & QR
  String get scanReceipt => translate('scan_receipt');
  String get scanYourReceipt => translate('scan_your_receipt');
  String get earnPoints => translate('earn_points');
  String get earnPointsInstantly => translate('earn_points_instantly');
  String get startScanning => translate('start_scanning');
  String get scanSuccessful => translate('scan_successful');
  String get processing => translate('processing');
  String get positionQR => translate('position_qr');
  String get positionQrCode => translate('position_qr_code');
  String get gotIt => translate('got_it');
  String get qrScanner => translate('qr_scanner');
  String get scanned => translate('scanned');
  String get qrNotSupportedWeb => translate('qr_not_supported_web');
  String get qrScannerNotAvailableWeb =>
      translate('qr_scanner_not_available_web');

  // Notifications
  String get noNotifications => translate('no_notifications');
  String get notificationDetails => translate('notification_details');
  String get messageDetails => translate('message_details');
  String get noMessageContent => translate('no_message_content');
  String get noMessageContentAvailable =>
      translate('no_message_content_available');
  String get noTitle => translate('no_title');
  String get read => translate('read');
  String get unread => translate('unread');
  String get newRewardsAdded => translate('new_rewards_added');
  String get successfulRedemption => translate('successful_redemption');
  String get newsletterTitle => translate('newsletter_title');
  String get failedLoadNotifications => translate('failed_load_notifications');
  String get allNotificationsMarkedRead =>
      translate('all_notifications_marked_read');
  String get errorMarkingRead => translate('error_marking_read');
  String get failedMarkRead => translate('failed_mark_read');

  // Language
  String get languageSelection => translate('language_selection');
  String get chooseLanguage => translate('choose_language');
  String get changeLanguage => translate('change_language');
  String get languageChanged => translate('language_changed');
  String get greek => translate('greek');
  String get english => translate('english');
  String get romanian => translate('romanian');

  // Rewards & Products
  String get noRewardsAvailable => translate('no_rewards_available');
  String get errorLoadingRewards => translate('error_loading_rewards');
  String get loadingRewardsText => translate('loading_rewards_text');
  String get errorLoadingRewardsTitle =>
      translate('error_loading_rewards_title');
  String get loadMoreProducts => translate('load_more_products');
  String get failedToLoadImage => translate('failed_to_load_image');
  String get imageNotFound => translate('image_not_found');
  String get imageNotAvailable => translate('image_not_available');
  String get go_back => translate('go_back');

  // Form Validation
  String get phoneRequired => translate('phone_required');
  String get phoneMinLength => translate('phone_min_length');
  String get phoneTooLong => translate('phone_too_long');
  String get phoneDigitsOnly => translate('phone_digits_only');
  String get invalidPhoneFormat => translate('invalid_phone_format');
  String get invalidPhoneFormatCountry =>
      translate('invalid_phone_format_country');
  String get includeCountryCode => translate('include_country_code');
  String get nameRequired => translate('name_required');
  String get nameMinLength => translate('name_min_length');
  String get nameLettersOnly => translate('name_letters_only');
  String get acceptTermsError => translate('accept_terms_error');
  String get fixErrors => translate('fix_errors');

  // OTP Validation
  String get otpRequired => translate('otp_required');
  String get otpMustBeSixDigits => translate('otp_must_be_six_digits');
  String get otpDigitsOnly => translate('otp_digits_only');
  String get invalidOtp => translate('invalid_otp');
  String get invalidOtpCheck => translate('invalid_otp_check');
  String get otpExpired => translate('otp_expired');
  String get requestOtpFirst => translate('request_otp_first');

  // Receipt Processing
  String get noReceiptFound => translate('no_receipt_found');
  String get bonusApplied => translate('bonus_applied');
  String get bonusSuccessfullyApplied =>
      translate('bonus_successfully_applied');
  String get failedApplyBonus => translate('failed_apply_bonus');
  String get failedToApplyBonus => translate('failed_to_apply_bonus');
  String get errorApplyingBonus => translate('error_applying_bonus');
  String get failedCheckReceipt => translate('failed_check_receipt');
  String get failedToCheckReceiptCode =>
      translate('failed_to_check_receipt_code');
  String get errorCheckingReceipt => translate('error_checking_receipt');

  // Error Messages
  String get userNotExist => translate('user_not_exist');
  String get userAlreadyExists => translate('user_already_exists');
  String get configurationError => translate('configuration_error');
  String get missingConfig => translate('missing_config');
  String get missingConfiguration => translate('missing_configuration');
  String get licenseFailed => translate('license_failed');
  String get loginFailed => translate('login_failed');
  String get loginError => translate('login_error');
  String get signupFailed => translate('signup_failed');
  String get signupError => translate('signup_error');
  String get connectionError => translate('connection_error');
  String get processingReceipt => translate('processingReceipt');
  String get pleaseWaitDoNotClose => translate('pleaseWaitDoNotClose');
  String get serverError => translate('server_error');
  String get networkError => translate('network_error');
  String get unknownError => translate('unknown_error');
  String get requestTimeout => translate('request_timeout');
  String get invalidResponseFormat => translate('invalid_response_format');

  // Phone and OTP API Errors
  String get failedSendOtp => translate('failed_send_otp');
  String get failedSendOtpTryAgain => translate('failed_send_otp_try_again');
  String get failedResendOtp => translate('failed_resend_otp');
  String get errorSendingOtp => translate('error_sending_otp');
  String get tooManyAttempts => translate('too_many_attempts');
  String get smsQuotaExceeded => translate('sms_quota_exceeded');
  String get appNotAuthorized => translate('app_not_authorized');
  String get recaptchaFailed => translate('recaptcha_failed');

  // User Management
  String get failedCheckUser => translate('failed_check_user');
  String get errorCheckingUser => translate('error_checking_user');
  String get checkingUser => translate('checking_user');
  String get signingIn => translate('signing_in');
  String get missingUserCredentials => translate('missing_user_credentials');
  String get failedLoadUserData => translate('failed_load_user_data');
  String get errorLoadingUserName => translate('error_loading_user_name');

  // Profile Management
  String get selectProfilePicture => translate('select_profile_picture');
  String get camera => translate('camera');
  String get gallery => translate('gallery');
  String get remove => translate('remove');
  String get processingImage => translate('processing_image');
  String get profilePictureUpdated => translate('profile_picture_updated');
  String get profilePictureRemoved => translate('profile_picture_removed');
  String get profileUpdatedSuccessfully =>
      translate('profile_updated_successfully');
  String get failedUpdateProfile => translate('failed_update_profile');
  String get imageSizeTooLarge => translate('image_size_too_large');
  String get imageEncodingFailed => translate('image_encoding_failed');
  String get failedSaveImage => translate('failed_save_image');
  String get imageFileNotFound => translate('image_file_not_found');

  // Logout
  String get loggedOutSuccessfully => translate('logged_out_successfully');
  String get confirmLogout => translate('confirm_logout');
  String get logoutConfirmation => translate('logout_confirmation');

  // Points and Balance
  String get errorLoadingPoints => translate('error_loading_points');
  String get loadingText => translate('loading_text');
  String get pointsText => translate('points_text');
  String get myBalanceText => translate('my_balance_text');

  // Permissions
  String get phonePermissionMessage => translate('phone_permission_message');

  // General UI Elements
  String get enter => translate('enter');
  String get notAvailable => translate('not_available');
  String get featureComingSoon => translate('feature_coming_soon');
  String get developedBy => translate('developed_by');
  String get sku => translate('sku');
  String get noneText => translate('none_text');

  // Debug Information
  String get showDebugInfo => translate('show_debug_info');
  String get debugInformation => translate('debug_information');
  String get lastError => translate('last_error');
  String get companyUrlDebug => translate('company_url_debug');
  String get softwareTypeDebug => translate('software_type_debug');
  String get clientIdDebug => translate('client_id_debug');
  String get trdrDebug => translate('trdr_debug');
  String get sharedPreferencesDebug => translate('shared_preferences_debug');
  String get missingSharedPreferencesValues =>
      translate('missing_shared_preferences_values');
  String get missingSharedPreferencesValuesDetailed =>
      translate('missing_shared_preferences_values_detailed');
  String get responseStatusDebug => translate('response_status_debug');
  String get responseBodyDebug => translate('response_body_debug');
  String get responseHeadersDebug => translate('response_headers_debug');
  String get apiCallDebugUri => translate('api_call_debug_uri');
  String get requestBodyDebug => translate('request_body_debug');
  String get accessDenied403 => translate('access_denied_403');
  String get serviceNotFound404 => translate('service_not_found_404');
  String get serverError500 => translate('server_error_500');

  // URL and Link Handling
  String get noUrlAvailable => translate('no_url_available');
  String get attemptingToLaunchUrl => translate('attempting_to_launch_url');
  String get parsedUriDebug => translate('parsed_uri_debug');
  String get successfullyLaunchedUrl => translate('successfully_launched_url');
  String get failedToLaunchUrl => translate('failed_to_launch_url');
  String get errorLaunchingUrl => translate('error_launching_url');
  String get failedToOpenLink => translate('failed_to_open_link');

  // UI Labels for Debug/Admin
  String get companyUrlLabel => translate('company_url_label');
  String get softwareTypeLabel => translate('software_type_label');
  String get clientIdLabel => translate('client_id_label');
  String get trdrLabel => translate('trdr_label');
  String get lastErrorLabel => translate('last_error_label');
  String get retryText => translate('retry_text');
  String get refreshText => translate('refresh_text');
  String get closeText => translate('close_text');
  String get shopNowText => translate('shop_now_text');
  String get loadMoreProductsText => translate('load_more_products_text');
  String get debugInformationText => translate('debug_information_text');
  String get showDebugInfoText => translate('show_debug_info_text');
  String get skuText => translate('sku_text');
  // Account Deletion
  String get deleteAccount => translate('deleteAccount');
  String get deleteAccountWarning => translate('deleteAccountWarning');
  String get deleteAccountNote => translate('deleteAccountNote');
  String get accountDeletionScheduled => translate('accountDeletionScheduled');
  String get accountWillBeDeleted => translate('accountWillBeDeleted');
  String get failedDeleteAccount => translate('failedDeleteAccount');
  String get okay => translate('okay');

  // In your AppLocalizations class, add these getters:

  // Dynamic greeting based on time
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return goodMorning;
    if (hour < 17) return goodAfternoon;
    return goodEvening;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['el', 'en', 'ro'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
