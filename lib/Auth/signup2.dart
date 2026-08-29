import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:loyalty_app/Auth/SignIn.dart';
import 'package:loyalty_app/Auth/TermsConditionsScreen.dart';
import 'package:loyalty_app/utils/api_constants.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/Services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

Map<String, dynamic>? globalLiscence;

class SignUpScreen2 extends StatefulWidget {
  const SignUpScreen2({super.key});

  @override
  State<SignUpScreen2> createState() => _SignUpScreen2State();
}

class _SignUpScreen2State extends State<SignUpScreen2> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _acceptTerms = false;
  final bool _obscurePassword = true;
  String _selectedLanguage = 'GR';
  bool _isLoading = false;
  bool _isCheckingUser = false;
  final bool _isSendingOtp = false; // ✅ Naya variable OTP sending ke liye

  String _completePhoneNumber = ''; // Store full phone with country code
  String _countryCode = '30'; // Store country code separately
  // Firebase OTP related variables
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  bool _otpSent = false;
  bool _isVerifyingOtp = false;
  bool _phoneVerified = false;
  int _resendToken = 0;
  bool _canResend = true;
  int _resendCountdown = 0;
  // Existing controllers ke baad add karo
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    _nameFocusNode.dispose(); // ✅ YE ADD KARO
    _phoneFocusNode.dispose(); // ✅ YE ADD KARO
    _otpFocusNode.dispose(); // ✅ YE ADD KARO
    super.dispose();
  }

  // Show custom snackbar at top with app color
  // Replace your existing _showCustomSnackBar method with this one:
void _showCustomSnackBar(
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  if (!mounted) return;

  // ✅ Use ScaffoldMessenger for reliable snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
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
      backgroundColor: isError
          ? Colors.red.shade600
          : isSuccess
          ? Colors.green.shade600
          : Colors.orange.shade600,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150,
        left: 20,
        right: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
  // void _showCustomSnackBar(
  //   String message, {
  //   bool isError = false,
  //   bool isSuccess = false,
  // }) {
  //   // ✅ Check if widget is still mounted
  //   if (!mounted) return;

  //   final overlay = Overlay.of(context);
  //   late OverlayEntry overlayEntry;

  //   overlayEntry = OverlayEntry(
  //     builder: (context) => Positioned(
  //       top: MediaQuery.of(context).padding.top + 10,
  //       left: 20,
  //       right: 20,
  //       child: Material(
  //         color: Colors.transparent,
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //           decoration: BoxDecoration(
  //             color: isError
  //                 ? Colors.red.shade600
  //                 : isSuccess
  //                 ? Colors.green.shade600
  //                 : Colors.orange.shade600,
  //             borderRadius: BorderRadius.circular(12),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.2),
  //                 blurRadius: 8,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 isError
  //                     ? Icons.error_outline
  //                     : isSuccess
  //                     ? Icons.check_circle_outline
  //                     : Icons.info_outline,
  //                 color: Colors.white,
  //                 size: 20,
  //               ),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(
  //                   message,
  //                   style: const TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.w500,
  //                     fontFamily: 'NotoSans',
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   overlay.insert(overlayEntry);

  //   // ✅ Mounted check ke saath remove karo
  //   Future.delayed(const Duration(seconds: 3), () {
  //     if (mounted) {
  //       overlayEntry.remove();
  //     }
  //   });
  // }

  // void _showCustomSnackBar(
  //   String message, {
  //   bool isError = false,
  //   bool isSuccess = false,
  // }) {
  //   final overlay = Overlay.of(context);
  //   late OverlayEntry overlayEntry;

  //   overlayEntry = OverlayEntry(
  //     builder: (context) => Positioned(
  //       top: MediaQuery.of(context).padding.top + 10,
  //       left: 20,
  //       right: 20,
  //       child: Material(
  //         color: Colors.transparent,
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //           decoration: BoxDecoration(
  //             color: isError
  //                 ? Colors.red.shade600
  //                 : isSuccess
  //                 ? Colors.green.shade600
  //                 : Colors.orange.shade600,
  //             borderRadius: BorderRadius.circular(12),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.2),
  //                 blurRadius: 8,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 isError
  //                     ? Icons.error_outline
  //                     : isSuccess
  //                     ? Icons.check_circle_outline
  //                     : Icons.info_outline,
  //                 color: Colors.white,
  //                 size: 20,
  //               ),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(
  //                   message,
  //                   style: const TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.w500,
  //                     fontFamily: 'NotoSans',
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   overlay.insert(overlayEntry);
  //   Future.delayed(const Duration(seconds: 3), () {
  //     overlayEntry.remove();
  //   });
  // }

  // Form validation
  String? _validateName(String? value) {
    final localizations = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return localizations.nameRequired;
    }
    if (value.length < 2) {
      return localizations.nameMinLength;
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final localizations = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return localizations.phoneRequired;
    }

    // Remove spaces and special characters for validation
    String cleanValue = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove leading + for length check
    String digitsOnly = cleanValue.replaceAll('+', '');

    // Check minimum length (should be at least 10 digits)
    if (digitsOnly.length < 10) {
      return localizations.phoneMinLength;
    }

    // Check maximum length (shouldn't exceed 15 digits as per E.164)
    if (digitsOnly.length > 15) {
      return localizations.phoneTooLong;
    }

    return null;
  }

  String? _validateOtp(String? value) {
    final localizations = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return localizations.otpRequired;
    }
    if (value.length != 6) {
      return localizations.otpMustBeSixDigits;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return localizations.otpDigitsOnly;
    }
    return null;
  }
// Add this helper method once — use everywhere for API calls
String _getPhoneForApi() {
  String phone = _completePhoneNumber.replaceAll('+', ''); // remove +
  String cleanCountryCode = _countryCode.replaceAll('+', ''); // "+30" → "30"
  
  // Sirf Greek numbers ke liye country code remove karo
  if (cleanCountryCode == '30' && phone.startsWith('30')) {
    phone = phone.replaceFirst('30', '');
  }
  
  debugPrint('✅ Phone for API: $phone');
  return phone;
  // Greece:  "6974123456"  ✅ (no 30)
  // Others:  "921234567899" ✅ (with their cc)
}
 
  // Firebase OTP Functions
 String _formatPhoneNumber(String phone) {
  if (_completePhoneNumber.isNotEmpty) {
    String formatted = _completePhoneNumber;
    if (!formatted.startsWith('+')) {
      formatted = '+$formatted';
    }
    debugPrint('📞 Firebase OTP: $formatted');
    return formatted;
  }
  String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
  return '+${_countryCode.replaceAll('+', '')}$cleanPhone';
}
 
  // String _formatPhoneNumber(String phone) {
  //   // IntlPhoneField se complete number mil raha hai
  //   if (_completePhoneNumber.isNotEmpty) {
  //     String formatted = _completePhoneNumber;
  //     // + sign nahi hona chahiye
  //     formatted = formatted.replaceAll('+', '');

  //     // Agar Greek number hai to country code (30) remove karo
  //     if (_countryCode == '30' && formatted.startsWith('30')) {
  //       formatted = formatted.replaceFirst('30', '');
  //     }

  //     debugPrint('📞 Final formatted phone for OTP: $_countryCode$formatted');
  //     return '+$_countryCode$formatted'; // Firebase OTP ke liye + lagao
  //   }

  //   // Fallback - old logic
  //   String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
  //   if (_countryCode == '30' && cleanPhone.startsWith('30')) {
  //     cleanPhone = cleanPhone.replaceFirst('30', '');
  //   }

  //   debugPrint('📞 Fallback formatted phone: +$_countryCode$cleanPhone');
  //   return '+$_countryCode$cleanPhone';
  // }

  // String _formatPhoneNumber(String phone) {
  //   // ✅ IntlPhoneField se complete number use karo
  //   if (_completePhoneNumber.isNotEmpty) {
  //     String formatted = _completePhoneNumber;
  //     // Ensure it starts with +
  //     if (!formatted.startsWith('+')) {
  //       formatted = '+$formatted';
  //     }
  //     debugPrint('Using IntlPhoneField number: $formatted');
  //     return formatted;
  //   }

  //   // ✅ Fallback with validation
  //   String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

  //   // ✅ Add this check to prevent empty country code
  //   if (_countryCode.isEmpty) {
  //     throw Exception('Country code is missing. Please select a country.');
  //   }

  //   if (!cleanPhone.startsWith('+')) {
  //     cleanPhone = '+$_countryCode$cleanPhone';
  //   }

  //   // ✅ Validate final format
  //   if (!cleanPhone.startsWith('+') || cleanPhone.length < 10) {
  //     throw Exception('Invalid phone number format: $cleanPhone');
  //   }

  //   debugPrint('Fallback formatted phone: $cleanPhone');
  //   return cleanPhone;
  // }

  // String _formatPhoneNumber(String phone) {
  //   // Agar IntlPhoneField se complete number mil gaya, use karo
  //   if (_completePhoneNumber.isNotEmpty) {
  //     debugPrint('Using IntlPhoneField number: $_completePhoneNumber');
  //     return _completePhoneNumber;
  //   }

  //   // Fallback: purana logic
  //   String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
  //   if (!cleanPhone.startsWith('+')) {
  //     cleanPhone = '92$cleanPhone';
  //   }
  //   debugPrint('Fallback formatted phone: $cleanPhone');
  //   return cleanPhone;
  // }
  Future<void> _manualVerifyOtp(String otp) async {
    final localizations = AppLocalizations.of(context)!;
    if (_verificationId == null) {
      _showCustomSnackBar(localizations.requestOtpFirst, isError: true);
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // ✅ Mounted check add karo
        if (!mounted) return;

        setState(() => _phoneVerified = true);
        _showCustomSnackBar(
          localizations.phoneVerifiedSuccess,
          isSuccess: true,
        );

        // Immediately sign out
        await _auth.signOut();

        // ✅ Mounted check again
        if (!mounted) return;

        // Proceed with backend signup
        await _handleBackendSignup();
      }
    } on FirebaseAuthException catch (e) {
      // ✅ Mounted check
      if (!mounted) return;

      String errorMessage = localizations.invalidOtp;

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = localizations.invalidOtpCheck;
          break;
        case 'session-expired':
          errorMessage = localizations.otpExpired;
          setState(() {
            _otpSent = false;
            _verificationId = null;
            otpController.clear();
          });
          break;
        default:
          errorMessage = e.message ?? localizations.invalidOtp;
      }

      _showCustomSnackBar(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }
  // Future<void> _manualVerifyOtp(String otp) async {
  //   final localizations = AppLocalizations.of(context)!;
  //   if (_verificationId == null) {
  //     _showCustomSnackBar(localizations.requestOtpFirst, isError: true);
  //     return;
  //   }

  //   setState(() => _isVerifyingOtp = true);

  //   try {
  //     PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //       verificationId: _verificationId!,
  //       smsCode: otp,
  //     );

  //     // Just verify the credential without signing in
  //     UserCredential userCredential = await _auth.signInWithCredential(
  //       credential,
  //     );

  //     if (userCredential.user != null) {
  //       setState(() => _phoneVerified = true);
  //       _showCustomSnackBar(
  //         localizations.phoneVerifiedSuccess,
  //         isSuccess: true,
  //       );

  //       // Immediately sign out
  //       await _auth.signOut();

  //       // Proceed with backend signup
  //       await _handleBackendSignup();
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     String errorMessage = localizations.invalidOtp;

  //     switch (e.code) {
  //       case 'invalid-verification-code':
  //         errorMessage = localizations.invalidOtpCheck;
  //         break;
  //       case 'session-expired':
  //         errorMessage = localizations.otpExpired;
  //         setState(() {
  //           _otpSent = false;
  //           _verificationId = null;
  //           otpController.clear();
  //         });
  //         break;
  //       default:
  //         errorMessage = e.message ?? localizations.invalidOtp;
  //     }

  //     _showCustomSnackBar(errorMessage, isError: true);
  //   } finally {
  //     setState(() => _isVerifyingOtp = false);
  //   }
  // }

  Future<void> _sendOtp() async {
    await _sendOtpWithRetry();
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendCountdown();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _verifyOtp() async {
    final localizations = AppLocalizations.of(context)!;
    if (otpController.text.length != 6) {
      _showCustomSnackBar(localizations.enterSixDigitOtp, isError: true);
      return;
    }

    await _manualVerifyOtp(otpController.text.trim());
  }

  Future<void> _sendOtpWithRetry() async {
    final localizations = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      _showCustomSnackBar(localizations.acceptTermsError, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedPhone = _formatPhoneNumber(phoneController.text.trim());
      debugPrint('Attempting to send OTP to: $formattedPhone');

      // ✅ iOS FIX: Add proper error handling for reCAPTCHA
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 120),

        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Auto verification completed');
          if (!mounted) return;

          setState(() {
            _phoneVerified = true;
            _isLoading = false;
          });
          _showCustomSnackBar(localizations.phoneVerifiedAuto, isSuccess: true);

          await _auth.signOut();
          await _handleBackendSignup();
        },

        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
          if (!mounted) return;

          String errorMessage = localizations.failedSendOtp;

          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = localizations.invalidPhoneFormatCountry;
              break;
            case 'too-many-requests':
              errorMessage = localizations.tooManyAttempts;
              break;
            case 'quota-exceeded':
              errorMessage = localizations.smsQuotaExceeded;
              break;
            case 'app-not-authorized':
            case 'captcha-check-failed':
              // ✅ iOS-specific fix for reCAPTCHA issues
              errorMessage =
                  'iOS verification issue. Please ensure:\n'
                  '1. Firebase iOS setup is complete\n'
                  '2. APNs (Push Notifications) are configured\n'
                  '3. App Check is enabled in Firebase Console';
              break;
            case 'network-request-failed':
              errorMessage = localizations.networkError;
              break;
            case 'missing-phone-number':
              errorMessage = localizations.phoneRequired;
              break;
            default:
              errorMessage = e.message ?? localizations.failedSendOtpTryAgain;
          }

          setState(() => _isLoading = false);
          _showCustomSnackBar(errorMessage, isError: true);
        },

        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ OTP sent successfully');
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _resendToken = resendToken ?? 0;
            _canResend = false;
            _resendCountdown = 60;
            _isLoading = false;
          });

          _showCustomSnackBar(localizations.otpSent, isSuccess: true);
          _startResendCountdown();
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ Auto retrieval timeout');
          if (!mounted) return;
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      debugPrint('❗ Send OTP exception: $e');
      if (!mounted) return;

      if (e.toString().contains('country code')) {
        _showCustomSnackBar(e.toString(), isError: true);
      } else {
        _showCustomSnackBar(localizations.errorSendingOtp, isError: true);
      }

      setState(() => _isLoading = false);
    }
  }

  // ✅ iOS-specific: Check if device can send OTP
  Future<bool> _checkiOSCapabilities() async {
    if (!mounted) return false;

    try {
      // Check if running on iOS
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        debugPrint('📱 Running on iOS - checking capabilities');

        // You can add additional iOS-specific checks here
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('❌ iOS capability check failed: $e');
      return false;
    }
  }

  // Future<void> _sendOtpWithRetry() async {
  //   final localizations = AppLocalizations.of(context)!;
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }

  //   if (!_acceptTerms) {
  //     _showCustomSnackBar(localizations.acceptTermsError, isError: true);
  //     return;
  //   }

  //   setState(() => _isLoading = true);

  //   try {
  //     final formattedPhone = _formatPhoneNumber(phoneController.text.trim());
  //     debugPrint('Attempting to send OTP to: $formattedPhone');

  //     await _auth.verifyPhoneNumber(
  //       phoneNumber: formattedPhone,
  //       timeout: const Duration(seconds: 120),

  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //         debugPrint('✅ Auto verification completed');
  //         setState(() {
  //           _phoneVerified = true;
  //           _isLoading = false; // Loading band karo
  //         });
  //         _showCustomSnackBar(localizations.phoneVerifiedAuto, isSuccess: true);

  //         // Sign out immediately and proceed
  //         await _auth.signOut();
  //         await _handleBackendSignup();
  //       },

  //       verificationFailed: (FirebaseAuthException e) {
  //         debugPrint('❌ Verification failed: ${e.code} - ${e.message}');

  //         // ✅ Mounted check add karo
  //         if (!mounted) return;

  //         String errorMessage = localizations.failedSendOtp;

  //         switch (e.code) {
  //           case 'invalid-phone-number':
  //             errorMessage = localizations.invalidPhoneFormatCountry;
  //             break;
  //           case 'too-many-requests':
  //             errorMessage = localizations.tooManyAttempts;
  //             break;
  //           case 'quota-exceeded':
  //             errorMessage = localizations.smsQuotaExceeded;
  //             break;
  //           case 'app-not-authorized':
  //             errorMessage = localizations.appNotAuthorized;
  //             break;
  //           case 'network-request-failed':
  //             errorMessage = localizations.networkError;
  //             break;
  //           case 'missing-phone-number':
  //             errorMessage = localizations.phoneRequired;
  //             break;
  //           case 'captcha-check-failed':
  //             errorMessage = localizations.recaptchaFailed;
  //             break;
  //           default:
  //             errorMessage = e.message ?? localizations.failedSendOtpTryAgain;
  //         }

  //         setState(() => _isLoading = false);
  //         _showCustomSnackBar(errorMessage, isError: true);
  //       },

  //       codeSent: (String verificationId, int? resendToken) {
  //         debugPrint('✅ OTP sent successfully');
  //         debugPrint('VerificationId: $verificationId');

  //         setState(() {
  //           _verificationId = verificationId;
  //           _otpSent = true;
  //           _resendToken = resendToken ?? 0;
  //           _canResend = false;
  //           _resendCountdown = 60;
  //           _isLoading = false; // Loading band karo
  //         });

  //         _showCustomSnackBar(localizations.otpSent, isSuccess: true);
  //         _startResendCountdown();
  //       },

  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         debugPrint('⏱️ Auto retrieval timeout');
  //         setState(() {
  //           _verificationId = verificationId;
  //         });
  //       },
  //     );
  //   } catch (e) {
  //     debugPrint('❗ Send OTP exception: $e');

  //     // Handle formatting errors specifically
  //     if (e.toString().contains('country code')) {
  //       _showCustomSnackBar(e.toString(), isError: true);
  //     } else {
  //       _showCustomSnackBar(localizations.errorSendingOtp, isError: true);
  //     }

  //     setState(() => _isLoading = false); // Loading band karo
  //   }
  // }

  // Updated text field for phone with better hint:
  Widget _buildPhoneField() {
    final localizations = AppLocalizations.of(context)!;
    return _buildTextFormField(
      controller: phoneController,
      validator: _validatePhone,
      hintText: localizations.enterPhoneWithCountryCode,
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
    );
  }

  Future<void> _resendOtp() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      final formattedPhone = _formatPhoneNumber(phoneController.text.trim());

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() => _phoneVerified = true);
          _showCustomSnackBar(localizations.phoneVerifiedAuto, isSuccess: true);
          await _auth.signOut();
          await _handleBackendSignup();
        },
        verificationFailed: (FirebaseAuthException e) {
          _showCustomSnackBar(localizations.failedResendOtp, isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken ?? 0;
            _canResend = false;
            _resendCountdown = 30;
          });

          otpController.clear();
          _showCustomSnackBar(localizations.otpResent, isSuccess: true);
          _startResendCountdown();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _showCustomSnackBar(localizations.failedResendOtp, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Backend API Functions

  Future<void> hitLicenseApiAndSave() async {
    final localizations = AppLocalizations.of(context)!;
    final uri = '${ApiConstants.baseUrl}https://webapp.xit.gr/service/license';
    // "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?";

    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
        throw Exception('License API failed');
      }
    } catch (e) {
      debugPrint('❗ License Exception: $e');
      _showCustomSnackBar(localizations.networkError, isError: true);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _getLicenseDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    if (jwtToken == null) return null;

    final uri =
        "${ApiConstants.baseUrl}https://license.xit.gr/wp-json/wp/v2/users/?slug=loyaltyangelop";
    // "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?";
    try {
      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
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

  Future<void> gettingClientID() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final license = await _getLicenseDetails();
      if (license == null) {
        _showCustomSnackBar(localizations.licenseFailed, isError: true);
        throw Exception('');
      }

      globalLiscence = license;
      final servicePath = license["software_type"] == "TESAE"
          ? "/pegasus/a_xit/connector.php"
          : "/s1services";

      final uri = Uri.parse(
        // "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?",
        "${ApiConstants.baseUrl}https://${license["company_url"]}$servicePath",
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
        final data = jsonDecode(response.body);
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
          throw Exception('Client login failed');
        }
      } else {
        _showCustomSnackBar(
          '${localizations.loginError} ${response.statusCode}',
          isError: true,
        );
        throw Exception('Login error');
      }
    } catch (e) {
      debugPrint('❗ Client login exception: $e');
      _showCustomSnackBar(localizations.connectionError, isError: true);
      rethrow;
    }
  }
Future<bool> _checkUserExists() async {
  final localizations = AppLocalizations.of(context)!;
  setState(() => _isCheckingUser = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final clientID = prefs.getString('clientID');
    final companyUrl = prefs.getString('company_url');
    final softwareType = prefs.getString('software_type');

    if (clientID == null || companyUrl == null || softwareType == null) {
      _showCustomSnackBar(localizations.missingConfiguration, isError: true);
      return true;
    }

    final servicePath = softwareType == "TESAE"
        ? "/pegasus/a_xit/connector.php"
        : "/s1services";

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
    );

   // REPLACE WITH:
String phoneToCheck = _getPhoneForApi();

    final body = {
      "service": "SqlData",
      "clientID": clientID,
      "appId": "1001",
      "SqlName": "9706",
      "phone": phoneToCheck,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ✅ NAYA RESPONSE PARSING
      if (data['success'] == true && 
          data['totalcount'] != null && 
          data['totalcount'] > 0 &&
          data['rows'] != null && 
          data['rows'].isNotEmpty) {
        _showCustomSnackBar(localizations.userAlreadyExists, isError: true);
        return true; // User exists
      } else {
        return false; // User doesn't exist
      }
    } else {
      _showCustomSnackBar(localizations.failedCheckUser, isError: true);
      return true;
    }
  } catch (e) {
    debugPrint('❗ Check user exception: $e');
    _showCustomSnackBar(
      '${localizations.errorCheckingUser} ${e.toString()}',
      isError: true,
    );
    return true;
  } finally {
    setState(() => _isCheckingUser = false);
  }
}
  // Future<bool> _checkUserExists() async {
  //   final localizations = AppLocalizations.of(context)!;
  //   setState(() => _isCheckingUser = true);

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final clientID = prefs.getString('clientID');
  //     final companyUrl = prefs.getString('company_url');
  //     final softwareType = prefs.getString('software_type');

  //     if (clientID == null || companyUrl == null || softwareType == null) {
  //       _showCustomSnackBar(localizations.missingConfiguration, isError: true);
  //       return true;
  //     }

  //     final servicePath = softwareType == "TESAE"
  //         ? "/pegasus/a_xit/connector.php"
  //         : "/s1services";

  //     final uri = Uri.parse(
  //       "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
  //     );

  //     // ✅ Phone number clean karo (country code remove karo agar Greek ho)
  //     String phoneToCheck = _completePhoneNumber.replaceAll('+', '');
  //     if (_countryCode == '30' && phoneToCheck.startsWith('30')) {
  //       phoneToCheck = phoneToCheck.replaceFirst('30', '');
  //     }

  //     final body = {
  //       "service": "SqlData", // ✅ Naya service name
  //       "clientID": clientID,
  //       "appId": "1001",
  //       "SqlName": "9706", // ✅ Naya parameter
  //       "phone": phoneToCheck, // ✅ Bina country code ke
  //     };

  //     final response = await http.post(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       // ✅ Response structure according to your API
  //       if (data['success'] == true &&
  //           data['rows'] != null &&
  //           data['rows'].isNotEmpty) {
  //         _showCustomSnackBar(localizations.userAlreadyExists, isError: true);
  //         return true; // User exists
  //       } else {
  //         return false; // User doesn't exist
  //       }
  //     } else {
  //       _showCustomSnackBar(localizations.failedCheckUser, isError: true);
  //       return true;
  //     }
  //   } catch (e) {
  //     debugPrint('❗ Check user exception: $e');
  //     _showCustomSnackBar(
  //       '${localizations.errorCheckingUser} ${e.toString()}',
  //       isError: true,
  //     );
  //     return true;
  //   } finally {
  //     setState(() => _isCheckingUser = false);
  //   }
  // }
  
  // Future<bool> _checkUserExists() async {
  //   final localizations = AppLocalizations.of(context)!;
  //   setState(() => _isCheckingUser = true);
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final clientID = prefs.getString('clientID');
  //     final companyUrl = prefs.getString('company_url');
  //     final softwareType = prefs.getString('software_type');

  //     if (clientID == null || companyUrl == null || softwareType == null) {
  //       _showCustomSnackBar(localizations.missingConfiguration, isError: true);
  //       return true;
  //     }

  //     final servicePath = softwareType == "TESAE"
  //         ? "/pegasus/a_xit/connector.php"
  //         : "/s1services";

  //     final uri = Uri.parse(
  //       // "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?",
  //       "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
  //     );
  //     String phone = _completePhoneNumber.replaceAll('+', '');
  //     final body = {
  //       "service": "getBrowserInfo",
  //       "clientID": clientID,
  //       "appId": "1001",
  //       "OBJECT": "CUSTOMER",
  //       "LIST": "",
  //       "VERSION": 2,
  //       "LIMIT": 1,
  //       "FILTERS": "CUSTOMER.CODE= ${phone.replaceAll('+', '')}",
  //     };

  //     final response = await http.post(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       final totalCount = data['totalcount'] ?? 0;

  //       if (totalCount == 0) {
  //         return false; // User doesn't exist, proceed
  //       } else {
  //         _showCustomSnackBar(localizations.userAlreadyExists, isError: true);
  //         return true; // User exists, stop
  //       }
  //     } else {
  //       _showCustomSnackBar(localizations.failedCheckUser, isError: true);
  //       return true;
  //     }
  //   } catch (e) {
  //     debugPrint('❗ Check user exception: $e');
  //     _showCustomSnackBar(
  //       '${localizations.errorCheckingUser} ${e.toString()}',
  //       isError: true,
  //     );
  //     return true;
  //   } finally {
  //     setState(() => _isCheckingUser = false);
  //   }
  // }

  Future<void> _signupCustomer() async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final clientID = prefs.getString('clientID');
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');

      if (clientID == null || companyUrl == null || softwareType == null) {
        _showCustomSnackBar(localizations.missingConfig, isError: true);
        throw Exception('Missing configuration');
      }

      final servicePath = softwareType == "TESAE"
          ? "/pegasus/a_xit/connector.php"
          : "/s1services";

      final uri = Uri.parse(
        "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
      );

      // ✅ Phone number clean karo for CODE and PHONE01
     String phoneForCode = _getPhoneForApi();


      final body = {
        "service": "setData",
        "clientID": clientID,
        "appId": "1001",
        "OBJECT": "CUSTOMER[FORM=WEB]",
        "KEY": "",
        "data": {
          "CUSTOMER": [
            {
              "CODE": phoneForCode, // ✅ Bina country code ke
              "NAME": fullNameController.text.trim(),
              "EMAIL": "", // Optional
              "PHONE01": phoneForCode, // ✅ Bina country code ke
              "PHONE02":
                  _completePhoneNumber, // ✅ Full number with country code
              "ADDRESS": "",
              "ZIP": "",
              "DISTRICT": "",
              "CCCXITUSERNAME": "",
              "CCCXITPASSWORD": "",
              "REMARKS": "Registered via App",
            },
          ],
        },
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showCustomSnackBar(localizations.accountCreated, isSuccess: true);
          _clearForm();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          );
        } else {
          _showCustomSnackBar(
            '${localizations.signupFailed}: ${data['error'] ?? localizations.unknownError}',
            isError: true,
          );
          throw Exception('Signup failed');
        }
      } else {
        _showCustomSnackBar(
          '${localizations.serverError}: ${response.statusCode}',
          isError: true,
        );
        throw Exception('Server error');
      }
    } catch (e) {
      debugPrint('❗ Signup exception: $e');
      _showCustomSnackBar(
        '${localizations.signupError} ${e.toString()}',
        isError: true,
      );
      rethrow;
    }
  }
  // Future<void> _signupCustomer() async {
  //   final localizations = AppLocalizations.of(context)!;
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final clientID = prefs.getString('clientID');
  //     final companyUrl = prefs.getString('company_url');
  //     final softwareType = prefs.getString('software_type');

  //     print('clientID =   $clientID');

  //     if (clientID == null || companyUrl == null || softwareType == null) {
  //       _showCustomSnackBar(localizations.missingConfig, isError: true);
  //       throw Exception('Missing configuration');
  //     }

  //     final servicePath = softwareType == "TESAE"
  //         ? "/pegasus/a_xit/connector.php"
  //         : "/s1services";

  //     final uri = Uri.parse(
  //       // "${ApiConstants.baseUrl}https://angelopouloshair.oncloud.gr/s1services?",
  //       "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
  //     );

  //     final body = {
  //       "service": "setData",
  //       "clientID": clientID,
  //       "appId": "1001",
  //       "OBJECT": "CUSTOMER[FORM=WEB]",
  //       "KEY": "",
  //       "data": {
  //         "CUSTOMER": [
  //           {
  //             "CODE": _completePhoneNumber.replaceAll('+', ''),
  //             "NAME": fullNameController.text.trim(),
  //             "PHONE01": _completePhoneNumber.replaceAll('+', ''),
  //           },
  //         ],
  //       },
  //     };

  //     final response = await http.post(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['success'] == true) {
  //         _showCustomSnackBar(localizations.accountCreated, isSuccess: true);
  //         _clearForm();

  //         // Navigate to SignIn after successful registration
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => SignInScreen()),
  //         );
  //       } else {
  //         _showCustomSnackBar(
  //           '${localizations.signupFailed}: ${data['error'] ?? localizations.unknownError}',
  //           isError: true,
  //         );
  //         throw Exception('Signup failed');
  //       }
  //     } else {
  //       _showCustomSnackBar(
  //         '${localizations.serverError}: ${response.statusCode}',
  //         isError: true,
  //       );
  //       throw Exception('Server error');
  //     }
  //   } catch (e) {
  //     debugPrint('❗ Signup exception: $e');
  //     _showCustomSnackBar(
  //       '${localizations.signupError} ${e.toString()}',
  //       isError: true,
  //     );
  //     rethrow;
  //   }
  // }

  void _clearForm() {
    fullNameController.clear();
    phoneController.clear();
    passwordController.clear();
    otpController.clear();
    setState(() {
      _acceptTerms = false;
      _otpSent = false;
      _phoneVerified = false;
      _verificationId = null;
      _completePhoneNumber = ''; // Add this
      _countryCode = '30'; // Add this
    });
  }

  // Main backend signup handler - Only called after phone verification
  Future<void> _handleBackendSignup() async {
    final localizations = AppLocalizations.of(context)!;

    // ✅ Mounted check
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await hitLicenseApiAndSave();
      if (!mounted) return; // ✅ Check after each async call

      await gettingClientID();
      if (!mounted) return;

      final userExists = await _checkUserExists();
      if (!mounted) return;

      if (userExists) {
        return;
      }

      await _signupCustomer();
    } catch (e) {
      debugPrint('Backend signup failed: $e');
      if (!mounted) return;

      _showCustomSnackBar(
        '${localizations.signupFailed} ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Future<void> _handleBackendSignup() async {
  //   final localizations = AppLocalizations.of(context)!;
  //   setState(() => _isLoading = true);

  //   try {
  //     // Step 1: Get license and save tokens
  //     await hitLicenseApiAndSave();

  //     // Step 2: Get client ID
  //     await gettingClientID();

  //     // Step 3: Check if user already exists
  //     final userExists = await _checkUserExists();
  //     if (userExists) {
  //       return; // Stop if user exists
  //     }

  //     // Step 4: Create new user
  //     await _signupCustomer();
  //   } catch (e) {
  //     debugPrint('Backend signup failed: $e');
  //     _showCustomSnackBar(
  //       '${localizations.signupFailed} ${e.toString()}',
  //       isError: true,
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  // Main signup handler
  // Main signup handler
  Future<void> _handleSignup() async {
    final localizations = AppLocalizations.of(context)!;

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      _showCustomSnackBar(localizations.fixErrors, isError: true);
      return;
    }

    if (!_acceptTerms) {
      _showCustomSnackBar(localizations.acceptTermsError, isError: true);
      return;
    }

    // If OTP not sent yet, send OTP first
    if (!_otpSent) {
      await _sendOtp();
      return;
    }

    // If OTP sent but not verified, verify OTP
    if (_otpSent && !_phoneVerified) {
      await _verifyOtp();
      return;
    }

    // ✅ Ab yahan create account call karo
    if (_otpSent && _phoneVerified) {
      await _signupCustomer();
    }
  }

  final Map<String, String> displayLanguageMap = {
    'el': 'GR',
    'en': 'EN',
    'ro': 'RO',
  };

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
            onTap: () => FocusScope.of(context).unfocus(), // ✅ Keyboard hide
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                SizedBox(height: 20),

                                /// Logo
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
                                // Language Section - Hidden when keyboard open
                                if (!isKeyboardOpen) ...[
                                  // ✅ Keyboard open = hide karo
                                  /// Language text
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

                                  SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLanguageOption('GR'),
                                      _separator(),
                                      _buildLanguageOption('en'),
                                      _separator(),
                                      _buildLanguageOption('ro'),
                                    ],
                                  ),
                                  SizedBox(height: 30),
                                ],

                                Spacer(),

                                /// White Card (Bottom)
                                Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.symmetric(horizontal: 36),
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Center(
                                          child: Text(
                                            localizations.signUp,
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
                                            _phoneVerified
                                                ? localizations
                                                      .phoneVerifiedCreating
                                                : _otpSent
                                                ? localizations
                                                      .enterSixDigitCode
                                                : localizations.createAccount,
                                            style: TextStyle(
                                              color: _phoneVerified
                                                  ? Colors.green[600]
                                                  : Colors.grey[700],
                                              fontSize: 11,
                                              fontFamily: 'NotoSans',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Form fields section
                                        if (!_otpSent) ...[
                                          // Full Name field
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: fullNameController,
                                            focusNode: _nameFocusNode,
                                            validator: _validateName,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.grey[200],
                                              hintText:
                                                  localizations.enterFullName,
                                              hintStyle: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 13,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.person_outline,
                                                color: Colors.grey[600],
                                                size: 20,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.orange.shade400,
                                                  width: 2,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.red,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'NotoSans',
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          // Phone Number field
                                          IntlPhoneField(
                                            controller: phoneController,
                                            focusNode:
                                                _phoneFocusNode, // ✅ FIX: _phoneFocusNode use karo
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.grey[200],
                                              hintText:
                                                  localizations.enterPhone,
                                              hintStyle: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 13,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.orange.shade400,
                                                  width: 2,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.red,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'NotoSans',
                                            ),
                                            initialCountryCode: 'GR',
                                            dropdownIconPosition:
                                                IconPosition.trailing,
                                            flagsButtonPadding: EdgeInsets.only(
                                              left: 8,
                                            ),
                                            showDropdownIcon: true,
                                            dropdownTextStyle: TextStyle(
                                              fontSize: 13,
                                            ),
                                            onChanged: (phone) {
                                              setState(() {
                                                _completePhoneNumber =
                                                    phone.completeNumber;
                                                _countryCode =
                                                    phone.countryCode;
                                              });
                                            },
                                            validator: (phone) {
                                              if (phone == null ||
                                                  phone.number.isEmpty) {
                                                return localizations
                                                    .phoneRequired;
                                              }
                                              if (phone.number.length < 7) {
                                                return localizations
                                                    .phoneMinLength;
                                              }
                                              return null;
                                            },
                                          ),
                                        ] else if (!_phoneVerified) ...[
                                          // OTP Verification Section
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: otpController,
                                            focusNode:
                                                _otpFocusNode, // ✅ FIX: _otpFocusNode use karo
                                            validator: _validateOtp,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                6,
                                              ),
                                            ],
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.grey[200],
                                              hintText: localizations
                                                  .enterSixDigitOtp,
                                              hintStyle: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 13,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.security,
                                                color: Colors.grey[600],
                                                size: 20,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.orange.shade400,
                                                  width: 2,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.red,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'NotoSans',
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  '${localizations.sentTo}: ${phoneController.text}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 11,
                                                    fontFamily: 'NotoSans',
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: _canResend
                                                    ? _resendOtp
                                                    : null,
                                                child: Text(
                                                  _canResend
                                                      ? localizations.resendOtp
                                                      : '${localizations.resendIn} ${_resendCountdown}s',
                                                  style: TextStyle(
                                                    color: _canResend
                                                        ? Colors.orange
                                                        : Colors.grey,
                                                    fontSize: 11,
                                                    fontFamily: 'NotoSans',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          // Success message when phone verified
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.green[200]!,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green[600],
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    localizations
                                                        .phoneVerifiedCreating,
                                                    style: TextStyle(
                                                      color: Colors.green[700],
                                                      fontSize: 12,
                                                      fontFamily: 'NotoSans',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 12),
                                        // Terms checkbox
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _acceptTerms,
                                              onChanged: (val) {
                                                setState(() {
                                                  _acceptTerms = val!;
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
                                                          '${localizations.iAccept} ',
                                                    ),
                                                    TextSpan(
                                                      text: localizations
                                                          .termsOfUse,
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFFEC7103,
                                                        ),
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                      recognizer:
                                                          TapGestureRecognizer()
                                                            ..onTap = () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) =>
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

                                        // Sign in text
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
                                                  text:
                                                      '${localizations.haveAccount} ',
                                                ),
                                                TextSpan(
                                                  text: localizations.signIn,
                                                  style: TextStyle(
                                                    color: Color(0xFFEC7103),
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    fontSize: 14,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              SignInScreen(),
                                                        ),
                                                      );
                                                    },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 30),

                                        // Sign Up button - Centered
                                        Center(
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed:
                                                  (_isLoading ||
                                                      _isCheckingUser ||
                                                      _isVerifyingOtp)
                                                  ? null
                                                  : _handleSignup,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFEC7103,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                ),
                                                elevation: 2,
                                              ),
                                              child:
                                                  (_isLoading ||
                                                      _isCheckingUser ||
                                                      _isVerifyingOtp)
                                                  ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
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
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          _isCheckingUser
                                                              ? localizations
                                                                    .checkingUser
                                                              : _isVerifyingOtp
                                                              ? localizations
                                                                    .verifyingOtp
                                                              : !_otpSent
                                                              ? localizations
                                                                    .sendingOtp
                                                              : _phoneVerified
                                                              ? localizations
                                                                    .creatingAccount
                                                              : localizations
                                                                    .verifyingOtp,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontFamily:
                                                                    'NotoSans',
                                                                fontSize: 16,
                                                              ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      !_otpSent
                                                          ? localizations
                                                                .sendOtp
                                                          : !_phoneVerified
                                                          ? localizations
                                                                .verifyOtp
                                                          : localizations
                                                                .createAccount,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily: 'NotoSans',
                                                        fontSize: 16,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
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
                        ),
                      );
                    },
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
  //           behavior: HitTestBehavior
  //               .opaque, // ✅ Transparent areas bhi tap detect karenge
  //           onTap: () => FocusScope.of(context).unfocus(), // ✅ Keyboard hide
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
  //                 // child: GestureDetector(
  //                 //   onTap: () =>
  //                 //       FocusScope.of(context).unfocus(), // ✅ YE ADD KARO
  //                 child: LayoutBuilder(
  //                   builder: (context, constraints) {
  //                     return SingleChildScrollView(
  //                       padding: EdgeInsets.zero,
  //                       child: ConstrainedBox(
  //                         constraints: BoxConstraints(
  //                           minHeight: constraints.maxHeight,
  //                         ),
  //                         child: IntrinsicHeight(
  //                           child: Column(
  //                             children: [
  //                               SizedBox(height: 20),

  //                               /// Logo
  //                               Center(
  //                                 child: Image.asset(
  //                                   'assets/images/app-logo.png',
  //                                   height: 100,
  //                                   width: 600,
  //                                 ),
  //                               ),

  //                               SizedBox(height: 40),

  //                               /// Language text
  //                               Center(
  //                                 child: Text(
  //                                   localizations.chooseLanguage,
  //                                   style: TextStyle(
  //                                     fontSize: 20,
  //                                     color: Colors.white,
  //                                     fontFamily: 'NotoSans',
  //                                   ),
  //                                 ),
  //                               ),

  //                               SizedBox(height: 10),

  //                               Row(
  //                                 mainAxisAlignment: MainAxisAlignment.center,
  //                                 children: [
  //                                   _buildLanguageOption('GR'),
  //                                   _separator(),
  //                                   _buildLanguageOption('en'),
  //                                   _separator(),
  //                                   _buildLanguageOption('ro'),
  //                                 ],
  //                               ),
  //                               SizedBox(height: 30),

  //                               /// Yahan Spacer ki jagah Expanded nahi use kar sakte scroll view me.
  //                               /// So use: Expanded → REMOVED
  //                               /// We use IntrinsicHeight + minHeight constraints.
  //                               Spacer(), // <- YE AB SIRF Tab kaam karega jab jagah bachi ho
  //                               /// White Card (Bottom)
  //                               Container(
  //                                 width: double.infinity,
  //                                 margin: EdgeInsets.symmetric(horizontal: 36),
  //                                 padding: EdgeInsets.all(24),
  //                                 decoration: BoxDecoration(
  //                                   color: Colors.white,
  //                                   borderRadius: BorderRadius.circular(30),
  //                                 ),
  //                                 child: Form(
  //                                   key: _formKey,
  //                                   child: Column(
  //                                     mainAxisSize: MainAxisSize.min,
  //                                     children: [
  //                                       Center(
  //                                         child: Text(
  //                                           localizations.signUp,
  //                                           style: TextStyle(
  //                                             fontWeight: FontWeight.bold,
  //                                             fontSize: 22,
  //                                             fontFamily: 'NotoSans',
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(height: 10),
  //                                       Center(
  //                                         child: Text(
  //                                           _phoneVerified
  //                                               ? localizations
  //                                                     .phoneVerifiedCreating
  //                                               : _otpSent
  //                                               ? localizations
  //                                                     .enterSixDigitCode
  //                                               : localizations.createAccount,
  //                                           style: TextStyle(
  //                                             color: _phoneVerified
  //                                                 ? Colors.green[600]
  //                                                 : Colors.grey[700],
  //                                             fontSize: 11,
  //                                             fontFamily: 'NotoSans',
  //                                           ),
  //                                           textAlign: TextAlign.center,
  //                                         ),
  //                                       ),
  //                                       const SizedBox(height: 10),

  //                                       // Form fields section
  //                                       if (!_otpSent) ...[
  //                                         // Full Name field
  //                                         const SizedBox(height: 6),
  //                                         TextFormField(
  //                                           controller: fullNameController,
  //                                           focusNode:
  //                                               _nameFocusNode, // ✅ YE ADD KARO

  //                                           validator: _validateName,
  //                                           decoration: InputDecoration(
  //                                             filled: true,
  //                                             fillColor: Colors.grey[200],
  //                                             hintText:
  //                                                 localizations.enterFullName,
  //                                             hintStyle: TextStyle(
  //                                               color: Colors.grey[500],
  //                                               fontSize: 13,
  //                                             ),
  //                                             prefixIcon: Icon(
  //                                               Icons.person_outline,
  //                                               color: Colors.grey[600],
  //                                               size: 20,
  //                                             ),
  //                                             contentPadding:
  //                                                 EdgeInsets.symmetric(
  //                                                   vertical: 10,
  //                                                   horizontal: 12,
  //                                                 ),
  //                                             border: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide.none,
  //                                             ),
  //                                             enabledBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide(
  //                                                 color: Colors.grey[300]!,
  //                                               ),
  //                                             ),
  //                                             focusedBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide(
  //                                                 color: Colors.orange.shade400,
  //                                                 width: 2,
  //                                               ),
  //                                             ),
  //                                             errorBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: const BorderSide(
  //                                                 color: Colors.red,
  //                                                 width: 1,
  //                                               ),
  //                                             ),
  //                                           ),
  //                                           style: TextStyle(
  //                                             fontSize: 14,
  //                                             fontFamily: 'NotoSans',
  //                                           ),
  //                                         ),

  //                                         const SizedBox(height: 12),

  //                                         // Phone Number field
  //                                         IntlPhoneField(
  //                                           controller: phoneController,
  //                                           focusNode:
  //                                               _nameFocusNode, // ✅ YE ADD KARO

  //                                           decoration: InputDecoration(
  //                                             filled: true,
  //                                             fillColor: Colors.grey[200],
  //                                             hintText:
  //                                                 localizations.enterPhone,
  //                                             hintStyle: TextStyle(
  //                                               color: Colors.grey[500],
  //                                               fontSize: 13,
  //                                             ),
  //                                             contentPadding:
  //                                                 EdgeInsets.symmetric(
  //                                                   vertical: 10,
  //                                                   horizontal: 12,
  //                                                 ),
  //                                             border: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide.none,
  //                                             ),
  //                                             enabledBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide(
  //                                                 color: Colors.grey[300]!,
  //                                               ),
  //                                             ),
  //                                             focusedBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide(
  //                                                 color: Colors.orange.shade400,
  //                                                 width: 2,
  //                                               ),
  //                                             ),
  //                                             errorBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: const BorderSide(
  //                                                 color: Colors.red,
  //                                                 width: 1,
  //                                               ),
  //                                             ),
  //                                           ),
  //                                           style: TextStyle(
  //                                             fontSize: 14,
  //                                             fontFamily: 'NotoSans',
  //                                           ),
  //                                           initialCountryCode: 'GR',
  //                                           dropdownIconPosition:
  //                                               IconPosition.trailing,
  //                                           flagsButtonPadding: EdgeInsets.only(
  //                                             left: 8,
  //                                           ),
  //                                           showDropdownIcon: true,
  //                                           dropdownTextStyle: TextStyle(
  //                                             fontSize: 13,
  //                                           ),
  //                                           onChanged: (phone) {
  //                                             setState(() {
  //                                               _completePhoneNumber =
  //                                                   phone.completeNumber;
  //                                               _countryCode =
  //                                                   phone.countryCode;
  //                                             });
  //                                           },
  //                                           validator: (phone) {
  //                                             if (phone == null ||
  //                                                 phone.number.isEmpty) {
  //                                               return localizations
  //                                                   .phoneRequired;
  //                                             }
  //                                             if (phone.number.length < 7) {
  //                                               return localizations
  //                                                   .phoneMinLength;
  //                                             }
  //                                             return null;
  //                                           },
  //                                         ),
  //                                       ] else if (!_phoneVerified) ...[
  //                                         // OTP Verification Section
  //                                         const SizedBox(height: 6),
  //                                         TextFormField(
  //                                           controller: otpController,
  //                                           focusNode:
  //                                               _nameFocusNode, // ✅ YE ADD KARO

  //                                           validator: _validateOtp,
  //                                           keyboardType: TextInputType.number,
  //                                           inputFormatters: [
  //                                             FilteringTextInputFormatter
  //                                                 .digitsOnly,
  //                                             LengthLimitingTextInputFormatter(
  //                                               6,
  //                                             ),
  //                                           ],
  //                                           decoration: InputDecoration(
  //                                             filled: true,
  //                                             fillColor: Colors.grey[200],
  //                                             hintText: localizations
  //                                                 .enterSixDigitOtp,
  //                                             hintStyle: TextStyle(
  //                                               color: Colors.grey[500],
  //                                               fontSize: 13,
  //                                             ),
  //                                             prefixIcon: Icon(
  //                                               Icons.security,
  //                                               color: Colors.grey[600],
  //                                               size: 20,
  //                                             ),
  //                                             contentPadding:
  //                                                 EdgeInsets.symmetric(
  //                                                   vertical: 10,
  //                                                   horizontal: 12,
  //                                                 ),
  //                                             border: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide.none,
  //                                             ),
  //                                             enabledBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide(
  //                                                 color: Colors.grey[300]!,
  //                                               ),
  //                                             ),
  //                                             focusedBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: BorderSide(
  //                                                 color: Colors.orange.shade400,
  //                                                 width: 2,
  //                                               ),
  //                                             ),
  //                                             errorBorder: OutlineInputBorder(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(12),
  //                                               borderSide: const BorderSide(
  //                                                 color: Colors.red,
  //                                                 width: 1,
  //                                               ),
  //                                             ),
  //                                           ),
  //                                           style: TextStyle(
  //                                             fontSize: 14,
  //                                             fontFamily: 'NotoSans',
  //                                           ),
  //                                         ),
  //                                         const SizedBox(height: 10),
  //                                         Row(
  //                                           mainAxisAlignment:
  //                                               MainAxisAlignment.spaceBetween,
  //                                           children: [
  //                                             Flexible(
  //                                               child: Text(
  //                                                 '${localizations.sentTo}: ${phoneController.text}',
  //                                                 style: TextStyle(
  //                                                   color: Colors.grey[600],
  //                                                   fontSize: 11,
  //                                                   fontFamily: 'NotoSans',
  //                                                 ),
  //                                                 overflow:
  //                                                     TextOverflow.ellipsis,
  //                                               ),
  //                                             ),
  //                                             TextButton(
  //                                               onPressed: _canResend
  //                                                   ? _resendOtp
  //                                                   : null,
  //                                               child: Text(
  //                                                 _canResend
  //                                                     ? localizations.resendOtp
  //                                                     : '${localizations.resendIn} ${_resendCountdown}s',
  //                                                 style: TextStyle(
  //                                                   color: _canResend
  //                                                       ? Colors.orange
  //                                                       : Colors.grey,
  //                                                   fontSize: 11,
  //                                                   fontFamily: 'NotoSans',
  //                                                   fontWeight: FontWeight.w500,
  //                                                 ),
  //                                               ),
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       ] else ...[
  //                                         // Success message when phone verified
  //                                         Container(
  //                                           padding: const EdgeInsets.all(12),
  //                                           decoration: BoxDecoration(
  //                                             color: Colors.green[50],
  //                                             borderRadius:
  //                                                 BorderRadius.circular(12),
  //                                             border: Border.all(
  //                                               color: Colors.green[200]!,
  //                                             ),
  //                                           ),
  //                                           child: Row(
  //                                             children: [
  //                                               Icon(
  //                                                 Icons.check_circle,
  //                                                 color: Colors.green[600],
  //                                                 size: 18,
  //                                               ),
  //                                               const SizedBox(width: 8),
  //                                               Expanded(
  //                                                 child: Text(
  //                                                   'localizations.phoneVerifiedCreating',
  //                                                   style: TextStyle(
  //                                                     color: Colors.green[700],
  //                                                     fontSize: 12,
  //                                                     fontFamily: 'NotoSans',
  //                                                     fontWeight:
  //                                                         FontWeight.w500,
  //                                                   ),
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                         ),
  //                                       ],

  //                                       const SizedBox(height: 12),
  //                                       // Terms checkbox
  //                                       Row(
  //                                         children: [
  //                                           Checkbox(
  //                                             value: _acceptTerms,
  //                                             onChanged: (val) {
  //                                               setState(() {
  //                                                 _acceptTerms = val!;
  //                                               });
  //                                             },
  //                                             activeColor: Color(0xFFEC7103),
  //                                           ),
  //                                           Expanded(
  //                                             child: RichText(
  //                                               text: TextSpan(
  //                                                 style: TextStyle(
  //                                                   color: Colors.black87,
  //                                                   fontFamily: 'NotoSans',
  //                                                 ),
  //                                                 children: [
  //                                                   TextSpan(
  //                                                     text:
  //                                                         '${localizations.iAccept} ',
  //                                                   ),
  //                                                   TextSpan(
  //                                                     text: localizations
  //                                                         .termsOfUse,
  //                                                     style: TextStyle(
  //                                                       color: Color(
  //                                                         0xFFEC7103,
  //                                                       ),
  //                                                       decoration:
  //                                                           TextDecoration
  //                                                               .underline,
  //                                                     ),
  //                                                     recognizer:
  //                                                         TapGestureRecognizer()
  //                                                           ..onTap = () {
  //                                                             Navigator.push(
  //                                                               context,
  //                                                               MaterialPageRoute(
  //                                                                 builder:
  //                                                                     (
  //                                                                       context,
  //                                                                     ) =>
  //                                                                         TermsConditionsScreen(),
  //                                                               ),
  //                                                             );
  //                                                           },
  //                                                   ),
  //                                                 ],
  //                                               ),
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       ),

  //                                       // Sign in text
  //                                       Center(
  //                                         child: RichText(
  //                                           text: TextSpan(
  //                                             style: TextStyle(
  //                                               color: Colors.black87,
  //                                               fontFamily: 'NotoSans',
  //                                               fontSize: 12,
  //                                             ),
  //                                             children: [
  //                                               TextSpan(
  //                                                 text:
  //                                                     '${localizations.haveAccount} ',
  //                                               ),
  //                                               TextSpan(
  //                                                 text: localizations.signIn,
  //                                                 style: TextStyle(
  //                                                   color: Color(0xFFEC7103),
  //                                                   fontWeight: FontWeight.bold,
  //                                                   decoration: TextDecoration
  //                                                       .underline,
  //                                                   fontSize: 14,
  //                                                 ),
  //                                                 recognizer: TapGestureRecognizer()
  //                                                   ..onTap = () {
  //                                                     Navigator.push(
  //                                                       context,
  //                                                       MaterialPageRoute(
  //                                                         builder: (context) =>
  //                                                             SignInScreen(),
  //                                                       ),
  //                                                     );
  //                                                   },
  //                                               ),
  //                                             ],
  //                                           ),
  //                                         ),
  //                                       ),

  //                                       const SizedBox(height: 30),

  //                                       // Sign Up button - Centered
  //                                       Center(
  //                                         child: SizedBox(
  //                                           width: double.infinity,
  //                                           child: ElevatedButton(
  //                                             onPressed:
  //                                                 (_isLoading ||
  //                                                     _isCheckingUser ||
  //                                                     _isVerifyingOtp)
  //                                                 ? null
  //                                                 : _handleSignup,
  //                                             style: ElevatedButton.styleFrom(
  //                                               backgroundColor: const Color(
  //                                                 0xFFEC7103,
  //                                               ),
  //                                               foregroundColor: Colors.white,
  //                                               padding:
  //                                                   const EdgeInsets.symmetric(
  //                                                     vertical: 16,
  //                                                   ),
  //                                               shape: RoundedRectangleBorder(
  //                                                 borderRadius:
  //                                                     BorderRadius.circular(25),
  //                                               ),
  //                                               elevation: 2,
  //                                             ),
  //                                             child:
  //                                                 (_isLoading ||
  //                                                     _isCheckingUser ||
  //                                                     _isVerifyingOtp)
  //                                                 ? Row(
  //                                                     mainAxisAlignment:
  //                                                         MainAxisAlignment
  //                                                             .center,
  //                                                     children: [
  //                                                       const SizedBox(
  //                                                         width: 20,
  //                                                         height: 20,
  //                                                         child: CircularProgressIndicator(
  //                                                           strokeWidth: 2,
  //                                                           valueColor:
  //                                                               AlwaysStoppedAnimation<
  //                                                                 Color
  //                                                               >(Colors.white),
  //                                                         ),
  //                                                       ),
  //                                                       const SizedBox(
  //                                                         width: 12,
  //                                                       ),
  //                                                       Text(
  //                                                         _isCheckingUser
  //                                                             ? localizations
  //                                                                   .checkingUser
  //                                                             : _isVerifyingOtp
  //                                                             ? localizations
  //                                                                   .verifyingOtp
  //                                                             : !_otpSent
  //                                                             ? localizations
  //                                                                   .sendingOtp
  //                                                             : _phoneVerified
  //                                                             ? localizations
  //                                                                   .creatingAccount
  //                                                             : localizations
  //                                                                   .verifyingOtp,
  //                                                         style:
  //                                                             const TextStyle(
  //                                                               fontWeight:
  //                                                                   FontWeight
  //                                                                       .w600,
  //                                                               fontFamily:
  //                                                                   'NotoSans',
  //                                                               fontSize: 16,
  //                                                             ),
  //                                                         textAlign:
  //                                                             TextAlign.center,
  //                                                       ),
  //                                                     ],
  //                                                   )
  //                                                 : Text(
  //                                                     !_otpSent
  //                                                         ? localizations
  //                                                               .sendOtp
  //                                                         : !_phoneVerified
  //                                                         ? localizations
  //                                                               .verifyOtp
  //                                                         : localizations
  //                                                               .createAccount,
  //                                                     style: const TextStyle(
  //                                                       fontWeight:
  //                                                           FontWeight.w600,
  //                                                       fontFamily: 'NotoSans',
  //                                                       fontSize: 16,
  //                                                     ),
  //                                                     textAlign:
  //                                                         TextAlign.center,
  //                                                   ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                               ),

  //                               const SizedBox(height: 30),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSans',
          fontSize: 14,
          color: Colors.black87,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, fontFamily: 'NotoSans'),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[600], size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(fontSize: 12, fontFamily: 'NotoSans'),
      ),
    );
  }

  Widget _buildLanguageOption(String langCode) {
    bool selected = langCode == _selectedLanguage;
    String displayText = langCode.toUpperCase();

    return GestureDetector(
      onTap: () async {
        final localizationService = Provider.of<LocalizationService>(
          context,
          listen: false,
        );
        await localizationService.changeLanguage(langCode);

        setState(() {
          _selectedLanguage = langCode;
        });

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.languageChanged),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Text(
        displayText,
        style: TextStyle(
          color: selected
              ? const Color(0xFFEC7103) // Orange for active
              : Colors.white, // White for inactive
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
          fontFamily: 'NotoSans',
        ),
      ),
    );
  }

  Widget _separator() => Container(
    height: 20,
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: const Color.fromARGB(176, 54, 54, 54),
  );
}
