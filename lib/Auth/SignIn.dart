import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loyalty_app/Auth/TermsConditionsScreen.dart';
import 'package:loyalty_app/Auth/signup2.dart';
import 'package:loyalty_app/screen/MainScreen.dart';
import 'package:loyalty_app/utils/api_constants.dart';
import 'package:loyalty_app/utils/language_decoder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:loyalty_app/Services/language_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/foundation.dart';
import 'package:charset_converter/charset_converter.dart';

// 👇 Global license data usable everywhere
Map<String, dynamic>? globalLiscence;

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isCheckingUser = false;
  String? _fcmToken;
  String _completePhoneNumber = ''; // Store full phone with country code
  String _countryCode = '30';
  // Existing variables ke baad add karo
  final FocusNode _phoneFocusNode = FocusNode();
  // Language mapping for display
  final Map<String, String> languageCodeMap = {
    'GR': 'el',
    'EN': 'en',
    'RO': 'ro',
  };

  final Map<String, String> displayLanguageMap = {
    'el': 'GR',
    'en': 'EN',
    'ro': 'RO',
  };

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission(); // ✅ Pehle permission, phir token

    _getPhoneNumber();
    _getFCMToken();
  }

  @override
  void dispose() {
    phoneController.dispose();
    _phoneFocusNode.dispose(); // ✅ YE ADD KARO
    super.dispose();
  }

  // Show custom snackbar at top with app color
  void _showCustomSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.shade600
                  : isSuccess
                  ? Colors.green.shade600
                  : Colors.orange.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline
                      : isSuccess
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  // Notification permission request karne ka function
  Future<void> _requestNotificationPermission() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 Notification Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // ✅ iOS-specific: Wait for APNS token
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          debugPrint('⏳ Waiting for APNS token...');

          // Wait up to 10 seconds for APNS token
          int attempts = 0;
          while (attempts < 10) {
            try {
              String? apnsToken = await messaging.getAPNSToken();
              debugPrint('✅ APNS Token received: $apnsToken');
              break;
            } catch (e) {
              debugPrint(
                '⏳ APNS token not ready yet, attempt ${attempts + 1}/10',
              );
            }

            await Future.delayed(Duration(seconds: 1));
            attempts++;
          }
        }

        // Now get FCM token
        await _getFCMToken();
      } else {
        debugPrint('❌ Notification Permission Denied');
        if (mounted) {
          _showCustomSnackBar(
            'Please enable notifications in Settings',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('❗ Permission Request Error: $e');
    }
  }

  // Phone number auto-fill function
  Future<void> _getPhoneNumber() async {
    try {
      var permissionStatus = await Permission.phone.request();

      if (permissionStatus.isGranted) {
        // Phone permission granted
      } else {
        final localizations = AppLocalizations.of(context)!;
        _showCustomSnackBar(localizations.phonePermissionMessage);
      }
    } catch (e) {
      debugPrint('Error getting phone permission: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        setState(() {
          _fcmToken = token;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);

        debugPrint('✅ FCM Token: $token');
      }
    } catch (e) {
      debugPrint('❗ FCM Token Error: $e');
    }
  }

  // Send token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientID = prefs.getString('clientID');
      final phone = prefs.getString('PHONE');

      if (clientID == null || globalLiscence == null) return;

      final uri = Uri.parse(
        // "${ApiConstants.baseUrl}https://${globalLiscence!['company_url']}/s1services",
        "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?",
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "service": "updateNotificationToken",
          "clientID": clientID,
          "appId": "1001",
          "phone": phone,
          "fcm_token": token,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM Token sent to backend successfully');
      } else {
        debugPrint('❌ Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❗ Error sending FCM token: $e');
    }
  }

  // Form validation
  String? _validatePhone(String? value) {
    final localizations = AppLocalizations.of(context)!;

    if (value == null || value.isEmpty) {
      return localizations.phoneRequired;
    }
    if (value.length < 10) {
      return localizations.phoneMinLength;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return localizations.phoneDigitsOnly;
    }
    return null;
  }

  Future<void> hitLicenseApiAndSave() async {
    final localizations = AppLocalizations.of(context)!;
    final uri = '${ApiConstants.baseUrl}https://webapp.xit.gr/service/license';
    // "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?";

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        String responseBody = await decodeGreekResponseBytes(
          response.bodyBytes,
        );
        final data = jsonDecode(responseBody);
        final prefs = await SharedPreferences.getInstance();

        await Future.wait([
          prefs.setString('token_type', data['token_type']),
          prefs.setInt('iat', data['iat']),
          prefs.setInt('expires_in', data['expires_in']),
          prefs.setString('jwt_token', data['jwt_token']),
        ]);

        debugPrint('✅ Token saved in SharedPreferences');
      } else {
        debugPrint('❌ License Error ${response.statusCode}: ${response.body}');
        _showCustomSnackBar(localizations.licenseFailed, isError: true);
      }
    } catch (e) {
      debugPrint('❗ License Exception: $e');
      _showCustomSnackBar(localizations.networkError, isError: true);
    }
  }

  Future<Map<String, dynamic>?> _getLicenseDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');

    if (jwtToken == null) return null;

    final uri =
        "${ApiConstants.baseUrl}https://license.xit.gr/wp-json/wp/v2/users/?slug=loyaltyangelop";

    try {
      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        String responseBody = await decodeGreekResponseBytes(
          response.bodyBytes,
        );
        final data = jsonDecode(responseBody);
        if (data.isNotEmpty) {
          return {
            "company_url": data[0]["acf"]["company_url"],
            "appid": data[0]["acf"]["app_id"],
            "company_id": data[0]["acf"]["company_id"],
            "branch": data[0]["acf"]["branch"],
            "refid": data[0]["acf"]["refid"],
            "software_type": data[0]["acf"]["software_type"],
          };
        }
      } else {
        debugPrint('❌ License fetch failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❗ License fetch exception: $e');
    }

    return null;
  }
// Future<void> _checkMemberAndSaveTrdr({
//   required String clientID,
//   required String phone,
// }) async {
//   final localizations = AppLocalizations.of(context)!;

//   try {
//     final uri = Uri.parse(
//       "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?",
//     );

//     // ✅ Naya API call with SqlData service
//     final response = await http.post(
//       uri,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         "service": "SqlData",
//         "clientID": clientID,
//         "appId": "1001",
//         "SqlName": "9706",
//         "phone": phone,  // ✅ Bina country code ke phone
//       }),
//     );

//     if (response.statusCode == 200) {
//       String responseBody = await decodeGreekResponseBytes(
//         response.bodyBytes,
//       );
//       final data = jsonDecode(responseBody);
      
//       // ✅ Response structure check karo (according to your API)
//       if (data['success'] == true && data['rows'] != null && data['rows'].isNotEmpty) {
//         final rows = data['rows'];
//         final String zoomInfo = rows[0][0]; // "CUSTOMER;24360"
//         final String trdr = zoomInfo.split(';')[1];
//         final String name = rows[0][3]; 
//         final String phone = rows[0][2]; 
//         final String upddate = data['upddate'] ?? "";

//         // 🔐 Save to SharedPreferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('TRDR', trdr);
//         await prefs.setString('NAME', name);
//         await prefs.setString('PHONE', phone);
//         await prefs.setString('UPDDATE', upddate);

//         debugPrint('✅ TRDR saved: $trdr');
        
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => MainScreen()),
//         );
//       } else {
//         _showCustomSnackBar(localizations.userNotExist, isError: true);
//       }
//     } else {
//       _showCustomSnackBar(localizations.serverError, isError: true);
//     }
//   } catch (e) {
//     debugPrint('❗ Error in _checkMemberAndSaveTrdr: $e');
//     _showCustomSnackBar(localizations.connectionError, isError: true);
//   }
// }
  
  Future<void> _checkMemberAndSaveTrdr({
  required String clientID,
  required String phone,
}) async {
  final localizations = AppLocalizations.of(context)!;

  try {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?",
    );

    // ✅ NAYA API CALL
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "service": "SqlData",
        "clientID": clientID,
        "appId": "1001",
        "SqlName": "9706",
        "phone": phone,
      }),
    );

    if (response.statusCode == 200) {
      String responseBody = await decodeGreekResponseBytes(
        response.bodyBytes,
      );
      final data = jsonDecode(responseBody);
      
      // ✅ NAYA RESPONSE PARSING
      if (data['success'] == true && 
          data['totalcount'] != null && 
          data['totalcount'] > 0 &&
          data['rows'] != null && 
          data['rows'].isNotEmpty) {
        
        final customerData = data['rows'][0];
        final String trdr = customerData['result']?.toString() ?? '';
        final String name = customerData['name']?.toString() ?? '';
        final String phone = customerData['phone01']?.toString() ?? '';

        // 🔐 Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('TRDR', trdr);
        await prefs.setString('NAME', name);
        await prefs.setString('PHONE', phone);
        
        // Optional fields agar hain to save karo
        if (customerData['address'] != null) {
          await prefs.setString('ADDRESS', customerData['address']);
        }
        if (customerData['city'] != null) {
          await prefs.setString('CITY', customerData['city']);
        }
        if (customerData['zip'] != null) {
          await prefs.setString('ZIP', customerData['zip']);
        }
        if (customerData['email'] != null) {
          await prefs.setString('EMAIL', customerData['email']);
        }

        debugPrint('✅ TRDR saved: $trdr');
        debugPrint('✅ NAME saved: $name');
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        _showCustomSnackBar(localizations.userNotExist, isError: true);
      }
    } else {
      _showCustomSnackBar(localizations.serverError, isError: true);
    }
  } catch (e) {
    debugPrint('❗ Error in _checkMemberAndSaveTrdr: $e');
    _showCustomSnackBar(localizations.connectionError, isError: true);
  }
}
  // Future<void> _checkMemberAndSaveTrdr({
  //   required String clientID,
  //   required String phone,
  // }) async {
  //   final localizations = AppLocalizations.of(context)!;

  //   try {
  //     final uri = Uri.parse(
  //       // "${ApiConstants.baseUrl}https://${globalLiscence!['company_url']}/s1services",
  //       "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?",
  //     );

  //     final response = await http.post(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         "service": "getBrowserInfo",
  //         "clientID": clientID,
  //         "appId": "1001",
  //         "OBJECT": "CUSTOMER",
  //         "LIST": "",
  //         "VERSION": 2,
  //         "LIMIT": 1,
  //         "FILTERS": "CUSTOMER.PHONE01=$phone",
  //       }),
  //     );

  //     if (response.statusCode == 200) {
  //       String responseBody = await decodeGreekResponseBytes(
  //         response.bodyBytes,
  //       );
  //       final data = jsonDecode(responseBody);
  //       final totalCount = data['totalcount'] ?? 0;
  //       if (totalCount == 0) {
  //         _showCustomSnackBar(localizations.userNotExist, isError: true);
  //       } else {
  //         final rows = data['rows'];
  //         final String zoomInfo = rows[0][0]; // "CUSTOMER;24360"
  //         final String trdr = zoomInfo.split(';')[1];
  //         final String name = rows[0][3]; // "malik"
  //         final String phone = rows[0][2]; // "1234567890"
  //         final String upddate = data['upddate'] ?? "";

  //         // 🔐 Save to SharedPreferences
  //         final prefs = await SharedPreferences.getInstance();
  //         await prefs.setString('TRDR', trdr);
  //         await prefs.setString('NAME', name);
  //         await prefs.setString('PHONE', phone);
  //         await prefs.setString('UPDDATE', upddate);

  //         debugPrint('✅ TRDR saved: $trdr');
  //         debugPrint('✅ NAME saved: $name');
  //         debugPrint('✅ PHONE saved: $phone');
  //         debugPrint('✅ UPDDATE saved: $upddate');

  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => MainScreen()),
  //         );
  //       }
  //     } else {
  //       _showCustomSnackBar(localizations.serverError, isError: true);
  //     }
  //   } catch (e) {
  //     debugPrint('❗ Error in _checkMemberAndSaveTrdr: $e');
  //     _showCustomSnackBar(localizations.connectionError, isError: true);
  //   }
  // }

  // Check if user exists and sign in
Future<void> _handleSignIn() async {
  final localizations = AppLocalizations.of(context)!;

  if (!_formKey.currentState!.validate()) {
    _showCustomSnackBar(localizations.phoneRequired, isError: true);
    return;
  }

  if (!_rememberMe) {
    _showCustomSnackBar(localizations.acceptTermsError, isError: true);
    return;
  }

  setState(() => _isCheckingUser = true);

  await hitLicenseApiAndSave();
  await gettingClientID();
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final clientID = prefs.getString('clientID');

    if (clientID == null) {
      _showCustomSnackBar(localizations.configurationError, isError: true);
      return;
    }

    // ✅ Country code ke hisaab se phone number format karo
    String phoneToSend = _completePhoneNumber.isNotEmpty 
        ? _completePhoneNumber.replaceAll('+', '')
        : phoneController.text.trim();

    // ✅ Agar Greek country code (30) hai to usse remove karo
    if (_countryCode == '30' && phoneToSend.startsWith('30')) {
      phoneToSend = phoneToSend.replaceFirst('30', '');
    }

    print('📞 Original phone: $_completePhoneNumber');
    print('📞 Country code: $_countryCode');
    print('📞 Final phone to send: $phoneToSend');

    await _checkMemberAndSaveTrdr(
      clientID: clientID,
      phone: phoneToSend,
    );

  } catch (e) {
    debugPrint('❗ Sign in exception: $e');
    _showCustomSnackBar(localizations.connectionError, isError: true);
  } finally {
    setState(() => _isCheckingUser = false);
  }
}
  // Future<void> _handleSignIn() async {
  //   final localizations = AppLocalizations.of(context)!;

  //   if (!_formKey.currentState!.validate()) {
  //     _showCustomSnackBar(localizations.phoneRequired, isError: true);
  //     return;
  //   }

  //   if (!_rememberMe) {
  //     _showCustomSnackBar(localizations.acceptTermsError, isError: true);
  //     return;
  //   }

  //   setState(() => _isCheckingUser = true);

  //   await hitLicenseApiAndSave();
  //   await gettingClientID();
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final clientID = prefs.getString('clientID');

  //     if (clientID == null) {
  //       _showCustomSnackBar(localizations.configurationError, isError: true);
  //       return;
  //     }

  //     // ✅ YE LINE CHANGE KARO - phoneController.text ki jagah _completePhoneNumber use karo
  //     await _checkMemberAndSaveTrdr(
  //       clientID: clientID,
  //       phone: _completePhoneNumber.isNotEmpty
  //           ? _completePhoneNumber
  //           : '$_countryCode${phoneController.text.trim()}',
  //     );

  //     print('phoneeee1 $_completePhoneNumber');
  //     print('phoneeee2 $_countryCode');
  //     print(phoneController.text);
  //   } catch (e) {
  //     debugPrint('❗ Sign in exception: $e');
  //     _showCustomSnackBar(localizations.connectionError, isError: true);
  //   } finally {
  //     setState(() => _isCheckingUser = false);
  //   }
  // }

  Future<void> gettingClientID() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final license = await _getLicenseDetails();
      if (license == null) {
        _showCustomSnackBar(localizations.licenseFailed, isError: true);
        return;
      }

      globalLiscence = license;

      final servicePath = license["software_type"] == "TESAE"
          ? "/pegasus/a_xit/connector.php"
          : "/s1services";

      final uri = Uri.parse(
        // "${ApiConstants.baseUrl}https://${license["company_url"]}$servicePath",
        "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?",
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "service": "login",
          "username": "loyaltyangelop",
          // Option B: raw string (no interpolation)
          "password": r'@ng3l0pul0!$',
          "appId": "1001",
          "COMPANY": "1001",
          "BRANCH": "10",
          "MODULE": "0",
          "REFID": "998",
        }),
      );

      if (response.statusCode == 200) {
        String responseBody = await decodeGreekResponseBytes(
          response.bodyBytes,
        );
        final data = jsonDecode(responseBody);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          final clientID = data['clientID'];

          await Future.wait([
            prefs.setString('clientID', clientID),
            prefs.setString('company', data['companyinfo'].split('|')[0]),
            prefs.setString('company_url', license['company_url']),
            prefs.setString('software_type', license['software_type']),
          ]);

          debugPrint('✅ Client login successful');
        } else {
          _showCustomSnackBar(localizations.loginFailed, isError: true);
        }
      } else {
        _showCustomSnackBar(localizations.serverError, isError: true);
      }
    } catch (e) {
      debugPrint('❗ Client login exception: $e');
      _showCustomSnackBar(localizations.connectionError, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        final localizations = AppLocalizations.of(context)!;
        final currentDisplayLanguage =
            displayLanguageMap[localizationService
                .currentLocale
                .languageCode] ??
            'GR';

        // ✅ Keyboard open hai ya nahi check karo
        final bool isKeyboardOpen =
            MediaQuery.of(context).viewInsets.bottom > 0;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            behavior: HitTestBehavior
                .opaque, // ✅ Transparent areas bhi tap detect karenge
            onTap: () =>
                FocusScope.of(context).unfocus(), // ✅ Body tap = keyboard hide
            child: Stack(
              children: [
                // Background image with blur
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/auth.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(color: Colors.black.withOpacity(0.3)),

                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/images/app-logo.png',
                          height: isKeyboardOpen
                              ? 60
                              : 100, // ✅ Keyboard open = smaller logo
                          width: 600,
                        ),
                      ),
                      SizedBox(
                        height: isKeyboardOpen ? 20 : 40,
                      ), // ✅ Less spacing when keyboard open
                      // Language Selection - Hidden when keyboard open
                      if (!isKeyboardOpen) ...[
                        // ✅ Keyboard open = hide karo
                        Center(
                          child: Text(
                            localizations.chooseLanguage,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontFamily: 'NotoSans',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLanguageOption(
                              'GR',
                              localizationService,
                              currentDisplayLanguage,
                            ),
                            _separator(),
                            _buildLanguageOption(
                              'EN',
                              localizationService,
                              currentDisplayLanguage,
                            ),
                            _separator(),
                            _buildLanguageOption(
                              'RO',
                              localizationService,
                              currentDisplayLanguage,
                            ),
                          ],
                        ),
                      ],

                      Spacer(),

                      // White Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 36),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Text(
                                  localizations.signIn,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  localizations.signInSubtitle,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 11,
                                    fontFamily: 'NotoSans',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Phone field
                              const SizedBox(height: 6),
                              IntlPhoneField(
                                controller: phoneController,
                                focusNode: _phoneFocusNode,
                                initialCountryCode: 'GR',
                                flagsButtonPadding: const EdgeInsets.only(
                                  left: 8,
                                ),
                                dropdownIconPosition: IconPosition.trailing,
                                showDropdownIcon: true,
                                dropdownTextStyle: const TextStyle(
                                  fontSize: 13,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'NotoSans',
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  hintText: localizations.enterPhone,
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.orange.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                onChanged: (phone) {
                                  setState(() {
                                    _completePhoneNumber = phone.completeNumber
                                        .replaceAll('+', '');
                                    _countryCode = phone.countryCode.replaceAll(
                                      '+',
                                      '',
                                    );
                                  });

                                  debugPrint(
                                    '📞 Complete Number: ${phone.completeNumber}',
                                  );
                                  debugPrint(
                                    '🌍 Country Code (without +): $_countryCode',
                                  );
                                },

                                validator: (phone) {
                                  if (phone == null || phone.number.isEmpty) {
                                    return localizations.phoneRequired;
                                  }
                                  if (phone.number.length < 7) {
                                    return localizations.phoneMinLength;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              // Terms checkbox
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val!;
                                      });
                                    },
                                    activeColor: Color(0xFFEC7103),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontFamily: 'NotoSans',
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                '${localizations.acceptTerms} ',
                                          ),
                                          TextSpan(
                                            text: localizations.termsOfUse,
                                            style: TextStyle(
                                              color: Color(0xFFEC7103),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TermsConditionsScreen(),
                                                  ),
                                                );
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Sign up text
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'NotoSans',
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${localizations.noAccount} ',
                                      ),
                                      TextSpan(
                                        text: localizations.signUp,
                                        style: TextStyle(
                                          color: Color(0xFFEC7103),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          fontSize: 14,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SignUpScreen2(),
                                              ),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Sign In button - Centered
                              Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: (_isLoading || _isCheckingUser)
                                        ? null
                                        : _handleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEC7103),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: (_isLoading || _isCheckingUser)
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            // children: [
                                            //   const SizedBox(
                                            //     width: 20,
                                            //     height: 20,
                                            //     child: CircularProgressIndicator(
                                            //       strokeWidth: 2,
                                            //       valueColor:
                                            //           AlwaysStoppedAnimation
                                            //             Color
                                            //           >(Colors.white),
                                            //     ),
                                            //   ),
                                            //   const SizedBox(width: 12),
                                            //   Text(
                                            //     _isCheckingUser
                                            //         ? localizations.checkingUser
                                            //         : localizations.signingIn,
                                            //     style: const TextStyle(
                                            //       fontWeight: FontWeight.w600,
                                            //       fontFamily: 'NotoSans',
                                            //       fontSize: 16,
                                            //     ),
                                            //     textAlign: TextAlign.center,
                                            //   ),
                                            // ],
                                            children: [
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                _isCheckingUser
                                                    ? localizations.checkingUser
                                                    : localizations.signingIn,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'NotoSans',
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          )
                                        : Text(
                                            localizations.signInButton,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'NotoSans',
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Consumer<LocalizationService>(
  //     builder: (context, localizationService, child) {
  //       final localizations = AppLocalizations.of(context)!;
  //       final currentDisplayLanguage =
  //           displayLanguageMap[localizationService
  //               .currentLocale
  //               .languageCode] ??
  //           'GR';

  //       return Scaffold(
  //         resizeToAvoidBottomInset: true,
  //         body: GestureDetector(
  //           onTap: () =>
  //               FocusScope.of(context).unfocus(), // ✅ Body tap = keyboard hide
  //           child: Stack(
  //             children: [
  //               // Background image with blur
  //               Container(
  //                 decoration: const BoxDecoration(
  //                   image: DecorationImage(
  //                     image: AssetImage("assets/images/auth.jpg"),
  //                     fit: BoxFit.cover,
  //                   ),
  //                 ),
  //               ),
  //               Container(color: Colors.black.withOpacity(0.3)),

  //               SafeArea(
  //                 child: Column(
  //                   children: [
  //                     const SizedBox(height: 20),
  //                     // Logo
  //                     Center(
  //                       child: Image.asset(
  //                         'assets/images/app-logo.png',
  //                         height: 100,
  //                         width: 600,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 40),

  //                     // Language Selection - Centered
  //                     Center(
  //                       child: Text(
  //                         localizations.chooseLanguage,
  //                         style: TextStyle(
  //                           fontSize: 20,
  //                           color: Colors.white,
  //                           fontFamily: 'NotoSans',
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         _buildLanguageOption(
  //                           'GR',
  //                           localizationService,
  //                           currentDisplayLanguage,
  //                         ),
  //                         _separator(),
  //                         _buildLanguageOption(
  //                           'EN',
  //                           localizationService,
  //                           currentDisplayLanguage,
  //                         ),
  //                         _separator(),
  //                         _buildLanguageOption(
  //                           'RO',
  //                           localizationService,
  //                           currentDisplayLanguage,
  //                         ),
  //                       ],
  //                     ),

  //                     Spacer(),

  //                     // White Card
  //                     Container(
  //                       width: double.infinity,
  //                       margin: const EdgeInsets.symmetric(horizontal: 36),
  //                       padding: const EdgeInsets.all(24),
  //                       decoration: BoxDecoration(
  //                         color: Colors.white,
  //                         borderRadius: BorderRadius.circular(30),
  //                       ),
  //                       child: Form(
  //                         key: _formKey,
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             Center(
  //                               child: Text(
  //                                 localizations.signIn,
  //                                 style: TextStyle(
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 22,
  //                                   fontFamily: 'NotoSans',
  //                                 ),
  //                               ),
  //                             ),
  //                             const SizedBox(height: 10),
  //                             Center(
  //                               child: Text(
  //                                 localizations.signInSubtitle,
  //                                 style: TextStyle(
  //                                   color: Colors.grey[700],
  //                                   fontSize: 11,
  //                                   fontFamily: 'NotoSans',
  //                                 ),
  //                                 textAlign: TextAlign.center,
  //                               ),
  //                             ),
  //                             const SizedBox(height: 10),

  //                             // Phone field
  //                             const SizedBox(height: 6),
  //                             // Line 722-773 ke beech - IntlPhoneField widget
  //                             IntlPhoneField(
  //                               controller: phoneController,
  //                               focusNode: _phoneFocusNode, // ✅ YE ADD KARO
  //                               initialCountryCode: 'GR', // Greek default
  //                               flagsButtonPadding: const EdgeInsets.only(
  //                                 left: 8,
  //                               ),
  //                               dropdownIconPosition: IconPosition.trailing,
  //                               showDropdownIcon: true,
  //                               dropdownTextStyle: const TextStyle(
  //                                 fontSize: 13,
  //                               ),
  //                               style: const TextStyle(
  //                                 fontSize: 14,
  //                                 fontFamily: 'NotoSans',
  //                               ),
  //                               decoration: InputDecoration(
  //                                 filled: true,
  //                                 fillColor: Colors.grey[200],
  //                                 hintText: localizations.enterPhone,
  //                                 hintStyle: TextStyle(
  //                                   color: Colors.grey[500],
  //                                   fontSize: 13,
  //                                 ),
  //                                 contentPadding: const EdgeInsets.symmetric(
  //                                   vertical: 10,
  //                                   horizontal: 12,
  //                                 ),
  //                                 border: OutlineInputBorder(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                   borderSide: BorderSide.none,
  //                                 ),
  //                                 enabledBorder: OutlineInputBorder(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                   borderSide: BorderSide(
  //                                     color: Colors.grey[300]!,
  //                                   ),
  //                                 ),
  //                                 focusedBorder: OutlineInputBorder(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                   borderSide: BorderSide(
  //                                     color: Colors.orange.shade400,
  //                                     width: 2,
  //                                   ),
  //                                 ),
  //                                 errorBorder: OutlineInputBorder(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                   borderSide: const BorderSide(
  //                                     color: Colors.red,
  //                                     width: 1,
  //                                   ),
  //                                 ),
  //                               ),
  //                               onChanged: (phone) {
  //                                 setState(() {
  //                                   _completePhoneNumber = phone.completeNumber
  //                                       .replaceAll('+', ''); // +30XXXXXXXXXX
  //                                   _countryCode = phone.countryCode.replaceAll(
  //                                     '+',
  //                                     '',
  //                                   ); // remove +
  //                                 });

  //                                 debugPrint(
  //                                   '📞 Complete Number: ${phone.completeNumber}',
  //                                 );
  //                                 debugPrint(
  //                                   '🌍 Country Code (without +): $_countryCode',
  //                                 );
  //                               },

  //                               validator: (phone) {
  //                                 if (phone == null || phone.number.isEmpty) {
  //                                   return localizations.phoneRequired;
  //                                 }
  //                                 if (phone.number.length < 7) {
  //                                   return localizations.phoneMinLength;
  //                                 }
  //                                 return null;
  //                               },
  //                             ),
  //                             const SizedBox(height: 12),
  //                             // Terms checkbox
  //                             Row(
  //                               children: [
  //                                 Checkbox(
  //                                   value: _rememberMe,
  //                                   onChanged: (val) {
  //                                     setState(() {
  //                                       _rememberMe = val!;
  //                                     });
  //                                   },
  //                                   activeColor: Color(0xFFEC7103),
  //                                 ),
  //                                 Expanded(
  //                                   child: RichText(
  //                                     text: TextSpan(
  //                                       style: TextStyle(
  //                                         color: Colors.black87,
  //                                         fontFamily: 'NotoSans',
  //                                       ),
  //                                       children: [
  //                                         TextSpan(
  //                                           text:
  //                                               '${localizations.acceptTerms} ',
  //                                         ),
  //                                         TextSpan(
  //                                           text: localizations.termsOfUse,
  //                                           style: TextStyle(
  //                                             color: Color(0xFFEC7103),
  //                                             decoration:
  //                                                 TextDecoration.underline,
  //                                           ),
  //                                           recognizer: TapGestureRecognizer()
  //                                             ..onTap = () {
  //                                               Navigator.push(
  //                                                 context,
  //                                                 MaterialPageRoute(
  //                                                   builder: (context) =>
  //                                                       TermsConditionsScreen(),
  //                                                 ),
  //                                               );
  //                                             },
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),

  //                             // Sign up text
  //                             Center(
  //                               child: RichText(
  //                                 text: TextSpan(
  //                                   style: TextStyle(
  //                                     color: Colors.black87,
  //                                     fontFamily: 'NotoSans',
  //                                     fontSize: 12,
  //                                   ),
  //                                   children: [
  //                                     TextSpan(
  //                                       text: '${localizations.noAccount} ',
  //                                     ),
  //                                     TextSpan(
  //                                       text: localizations.signUp,
  //                                       style: TextStyle(
  //                                         color: Color(0xFFEC7103),
  //                                         fontWeight: FontWeight.bold,
  //                                         decoration: TextDecoration.underline,
  //                                         fontSize: 14,
  //                                       ),
  //                                       recognizer: TapGestureRecognizer()
  //                                         ..onTap = () {
  //                                           Navigator.push(
  //                                             context,
  //                                             MaterialPageRoute(
  //                                               builder: (context) =>
  //                                                   SignUpScreen2(),
  //                                             ),
  //                                           );
  //                                         },
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),

  //                             const SizedBox(height: 30),

  //                             // Sign In button - Centered
  //                             Center(
  //                               child: SizedBox(
  //                                 width: double.infinity,
  //                                 child: ElevatedButton(
  //                                   onPressed: (_isLoading || _isCheckingUser)
  //                                       ? null
  //                                       : _handleSignIn,
  //                                   style: ElevatedButton.styleFrom(
  //                                     backgroundColor: const Color(0xFFEC7103),
  //                                     foregroundColor: Colors.white,
  //                                     padding: const EdgeInsets.symmetric(
  //                                       vertical: 16,
  //                                     ),
  //                                     shape: RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.circular(25),
  //                                     ),
  //                                     elevation: 2,
  //                                   ),
  //                                   child: (_isLoading || _isCheckingUser)
  //                                       ? Row(
  //                                           mainAxisAlignment:
  //                                               MainAxisAlignment.center,
  //                                           children: [
  //                                             const SizedBox(
  //                                               width: 20,
  //                                               height: 20,
  //                                               child: CircularProgressIndicator(
  //                                                 strokeWidth: 2,
  //                                                 valueColor:
  //                                                     AlwaysStoppedAnimation<
  //                                                       Color
  //                                                     >(Colors.white),
  //                                               ),
  //                                             ),
  //                                             const SizedBox(width: 12),
  //                                             Text(
  //                                               _isCheckingUser
  //                                                   ? localizations.checkingUser
  //                                                   : localizations.signingIn,
  //                                               style: const TextStyle(
  //                                                 fontWeight: FontWeight.w600,
  //                                                 fontFamily: 'NotoSans',
  //                                                 fontSize: 16,
  //                                               ),
  //                                               textAlign: TextAlign.center,
  //                                             ),
  //                                           ],
  //                                         )
  //                                       : Text(
  //                                           localizations.signInButton,
  //                                           style: const TextStyle(
  //                                             fontWeight: FontWeight.w600,
  //                                             fontFamily: 'NotoSans',
  //                                             fontSize: 16,
  //                                           ),
  //                                           textAlign: TextAlign.center,
  //                                         ),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),

  //                     const SizedBox(height: 30),
  //                   ],
  //                 ),
  //               ),

  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildLanguageOption(
    String displayLang,
    LocalizationService localizationService,
    String currentDisplayLanguage,
  ) {
    bool selected = displayLang == currentDisplayLanguage;
    return GestureDetector(
      onTap: () {
        // Convert display language to language code and change language
        final languageCode = languageCodeMap[displayLang] ?? 'el';
        localizationService.changeLanguage(languageCode);
      },
      child: Text(
        displayLang,
        style: TextStyle(
          color: selected ? Color(0xFFEC7103) : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
          fontFamily: 'NotoSans',
        ),
      ),
    );
  }

  /// Enhanced Greek text decoder - handles multiple encoding scenarios
  ///
  ///
  // Replace your _decodeApiResponse method with this async version:
  Future<String> _decodeApiResponseAsync(http.Response response) async {
    try {
      // Check content type first
      String? contentType = response.headers['content-type'];

      if (contentType != null) {
        if (contentType.contains('charset=windows-1253')) {
          return _convertWindows1253ToUtf8(
            String.fromCharCodes(response.bodyBytes),
          );
        } else if (contentType.contains('charset=iso-8859-7')) {
          return await _convertIso88597ToUtf8(
            String.fromCharCodes(response.bodyBytes),
          );
        }
      }

      // Try UTF-8 first
      try {
        String responseBody = utf8.decode(response.bodyBytes);
        if (_containsGreekUnicode(responseBody) ||
            !_containsLatinExtended(responseBody)) {
          return responseBody;
        }
      } catch (e) {
        debugPrint('UTF-8 decoding failed: $e');
      }

      // Fallback to Latin-1 then convert
      try {
        String latin1Decoded = latin1.decode(response.bodyBytes);
        String converted = _decodeGreekText(latin1Decoded);
        if (_containsGreekUnicode(converted)) {
          return converted;
        }
      } catch (e) {
        debugPrint('Latin-1 decoding failed: $e');
      }

      // Ultimate fallback
      return _decodeGreekText(response.body);
    } catch (e) {
      return response.body;
    }
  }

  String _decodeGreekText(dynamic value) {
    if (value == null) return '';

    String text = value.toString().trim();
    if (text.isEmpty) return '';

    try {
      // Method 1: Check if text contains Greek Unicode characters (properly encoded)
      if (_containsGreekUnicode(text)) {
        return text; // Already properly encoded
      }

      // Method 2: Handle Windows-1253 to UTF-8 conversion (most common case)
      if (_isWindows1253Encoded(text)) {
        return _convertWindows1253ToUtf8(text);
      }

      // Method 3: Try byte-level Windows-1253 conversion
      String converted = _convertBytesToGreek(text);
      if (_containsGreekUnicode(converted)) {
        return converted;
      }

      // Method 4: Handle HTML entities and numeric character references
      text = _decodeHtmlEntities(text);
      text = _decodeNumericEntities(text);

      return text;
    } catch (e) {
      if (kDebugMode) {
        print('Greek text decoding error: $e');
        print('Original text: $text');
      }
      return text; // Return original if all methods fail
    }
  }

  /// Enhanced Windows-1253 detection
  bool _isWindows1253Encoded(String text) {
    // Check for common Windows-1253 Greek character patterns
    final windows1253Patterns = [
      'Áí',
      'ìï',
      'êÝ',
      'ðñ',
      'óå',
      'ôá',
      'êá',
      'Üò',
      'íô',
      'Þò',
      'ýø',
      'ôå',
      'ñÝ',
      'óö',
      'ïñ',
      'ëë',
      'õí',
      'éê',
      'ðþ',
      'íõ',
    ];

    return windows1253Patterns.any((pattern) => text.contains(pattern)) ||
        text.codeUnits.any((unit) => unit >= 0xC0 && unit <= 0xFF);
  }

  /// Enhanced Windows-1253 to Greek Unicode conversion
  String _convertWindows1253ToUtf8(String text) {
    // Complete Windows-1253 to Greek Unicode mapping table
    final Map<int, String> windows1253ToGreek = {
      // Greek uppercase letters (0xC1-0xD9)
      0xC1: 'Α',
      0xC2: 'Β',
      0xC3: 'Γ',
      0xC4: 'Δ',
      0xC5: 'Ε',
      0xC6: 'Ζ',
      0xC7: 'Η',
      0xC8: 'Θ',
      0xC9: 'Ι',
      0xCA: 'Κ',
      0xCB: 'Λ',
      0xCC: 'Μ',
      0xCD: 'Ν',
      0xCE: 'Ξ',
      0xCF: 'Ο',
      0xD0: 'Π',
      0xD1: 'Ρ',
      0xD3: 'Σ',
      0xD4: 'Τ',
      0xD5: 'Υ',
      0xD6: 'Φ',
      0xD7: 'Χ',
      0xD8: 'Ψ',
      0xD9: 'Ω',

      // Greek lowercase letters (0xE1-0xF9)
      0xE1: 'α',
      0xE2: 'β',
      0xE3: 'γ',
      0xE4: 'δ',
      0xE5: 'ε',
      0xE6: 'ζ',
      0xE7: 'η',
      0xE8: 'θ',
      0xE9: 'ι',
      0xEA: 'κ',
      0xEB: 'λ',
      0xEC: 'μ',
      0xED: 'ν',
      0xEE: 'ξ',
      0xEF: 'ο',
      0xF0: 'π',
      0xF1: 'ρ',
      0xF2: 'ς',
      0xF3: 'σ',
      0xF4: 'τ',
      0xF5: 'υ',
      0xF6: 'φ',
      0xF7: 'χ',
      0xF8: 'ψ',
      0xF9: 'ω',

      // Greek accented characters
      0xAA: 'Ί', 0xBA: 'Ό', 0xDA: 'Ύ', 0xDB: 'Ώ', 0xDC: 'ΐ', 0xDD: 'ΰ',
      0xFD: 'ύ', 0xFC: 'ό', 0xFE: 'ώ', 0xFB: 'ή', 0xFA: 'ί', 0xDF: 'ϊ',

      // Additional accented vowels
      0xB6: 'Ά', 0xB8: 'Έ', 0xB9: 'Ή', 0xBC: 'Ό', 0xBE: 'Ύ', 0xBF: 'Ώ',
      0xDC: 'ά',
      0xDD: 'έ',
      0xDE: 'ή',
      0xDF: 'ί',
      0xE0: 'ό',
      0xFC: 'ύ',
      0xFD: 'ώ',
    };

    String converted = '';
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      if (windows1253ToGreek.containsKey(charCode)) {
        converted += windows1253ToGreek[charCode]!;
      } else {
        converted += text[i];
      }
    }

    return converted;
  }

  /// Byte-level conversion for stubborn encoding issues
  String _convertBytesToGreek(String text) {
    try {
      List<int> bytes = text.codeUnits;
      String result = '';

      for (int byte in bytes) {
        // Windows-1253 Greek range conversion
        if (byte >= 0xC1 && byte <= 0xD9) {
          // Uppercase Greek letters
          int greekCode = 0x0391 + (byte - 0xC1);
          if (byte == 0xD2) greekCode = 0x03A3; // Sigma special case
          result += String.fromCharCode(greekCode);
        } else if (byte >= 0xE1 && byte <= 0xF9) {
          // Lowercase Greek letters
          int greekCode = 0x03B1 + (byte - 0xE1);
          if (byte == 0xF2) greekCode = 0x03C2; // Final sigma
          result += String.fromCharCode(greekCode);
        } else if (byte == 0xB6) {
          result += 'Ά'; // Alpha with tonos
        } else if (byte == 0xB8) {
          result += 'Έ'; // Epsilon with tonos
        } else if (byte == 0xB9) {
          result += 'Ή'; // Eta with tonos
        } else if (byte == 0xBC) {
          result += 'Ό'; // Omicron with tonos
        } else if (byte == 0xBE) {
          result += 'Ύ'; // Upsilon with tonos
        } else if (byte == 0xBF) {
          result += 'Ώ'; // Omega with tonos
        } else if (byte == 0xDC) {
          result += 'ά'; // alpha with tonos
        } else if (byte == 0xDD) {
          result += 'έ'; // epsilon with tonos
        } else if (byte == 0xDE) {
          result += 'ή'; // eta with tonos
        } else if (byte == 0xDF) {
          result += 'ί'; // iota with tonos
        } else if (byte == 0xFC) {
          result += 'ό'; // omicron with tonos
        } else if (byte == 0xFD) {
          result += 'ύ'; // upsilon with tonos
        } else if (byte == 0xFE) {
          result += 'ώ'; // omega with tonos
        } else {
          result += String.fromCharCode(byte);
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('Byte conversion failed: $e');
      return text;
    }
  }

  /// Check if text contains properly encoded Greek Unicode characters
  bool _containsGreekUnicode(String text) {
    // Greek Unicode range: U+0370–U+03FF and U+1F00–U+1FFF
    return text.runes.any(
      (rune) =>
          (rune >= 0x0370 && rune <= 0x03FF) ||
          (rune >= 0x1F00 && rune <= 0x1FFF),
    );
  }

  /// Check if text is ISO-8859-7 encoded
  bool _isIso88597Encoded(String text) {
    // ISO-8859-7 has specific byte patterns for Greek
    try {
      List<int> bytes = text.codeUnits;
      return bytes.any((byte) => byte >= 0xB6 && byte <= 0xFF);
    } catch (e) {
      return false;
    }
  }

  /// Convert ISO-8859-7 to UTF-8
  Future<String> _convertIso88597ToUtf8(String text) async {
    try {
      // Convert List<int> → Uint8List
      final bytes = Uint8List.fromList(text.codeUnits);

      // Decode from ISO-8859-7 to UTF-8
      return await CharsetConverter.decode('iso-8859-7', bytes);
    } catch (e) {
      if (kDebugMode) print('ISO-8859-7 conversion failed: $e');
      return text;
    }
  }

  /// Check if text contains Latin extended characters
  bool _containsLatinExtended(String text) {
    return text.codeUnits.any((unit) => unit > 127 && unit < 256);
  }

  /// Decode HTML entities
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&hellip;', '…')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™');
  }

  /// Decode numeric character references (&#xxx; format)
  String _decodeNumericEntities(String text) {
    return text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      try {
        int charCode = int.parse(match.group(1)!);
        return String.fromCharCode(charCode);
      } catch (e) {
        return match.group(0)!; // Return original if conversion fails
      }
    });
  }

  /// Enhanced API response decoder for Greek content
  Future<String> _decodeApiResponse(http.Response response) async {
    String responseBody;

    try {
      // Method 1: Check if response has charset info in headers
      String? contentType = response.headers['content-type'];
      if (contentType != null) {
        if (contentType.contains('charset=windows-1253')) {
          // Decode as Windows-1253
          responseBody = _convertWindows1253ToUtf8(
            String.fromCharCodes(response.bodyBytes),
          );
          return responseBody;
        } else if (contentType.contains('charset=iso-8859-7')) {
          // Decode as ISO-8859-7
          responseBody = await _convertIso88597ToUtf8(
            String.fromCharCodes(response.bodyBytes),
          );
          return responseBody;
        }
      }

      // Method 2: Try UTF-8 decoding first
      try {
        responseBody = utf8.decode(response.bodyBytes);
        if (_containsGreekUnicode(responseBody) ||
            !_containsLatinExtended(responseBody)) {
          return responseBody;
        }
      } catch (e) {
        if (kDebugMode) print('UTF-8 decoding failed: $e');
      }

      // Method 3: Try Latin-1 then convert to UTF-8
      try {
        String latin1Decoded = latin1.decode(response.bodyBytes);
        responseBody = _decodeGreekText(latin1Decoded);
        if (_containsGreekUnicode(responseBody)) {
          return responseBody;
        }
      } catch (e) {
        if (kDebugMode) print('Latin-1 decoding failed: $e');
      }

      // Method 4: Fallback to response.body
      responseBody = response.body;
      responseBody = _decodeGreekText(responseBody);

      return responseBody;
    } catch (e) {
      return response.body; // Ultimate fallback
    }
  }

  Widget _separator() => Container(
    height: 20,
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white.withOpacity(0.6),
  );
}
