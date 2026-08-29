import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loyalty_app/utils/api_constants.dart';
import 'package:loyalty_app/Services/language_service.dart';

import 'package:loyalty_app/utils/snackbar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  String stringscanedfincode = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // 🧪 TEST - 2 second baad celebration dikhao
    // PRODUCTION MEIN COMMENT OUT KARNA HAI
    // Future.delayed(const Duration(seconds: 2), () {
    //   _showSuccessMessage('Bonus successfully applied! 🎉');
    // });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slideController.reset();
    _slideController.forward();
  }

  String _cleanScanCode(String code) {
    // Check if string is URL
    final uri = Uri.tryParse(code);

    bool isUrl = uri != null && (uri.scheme == "http" || uri.scheme == "https");

    // If URL → remove : and /
    if (isUrl) {
      return code.replaceAll(RegExp(r'[:\/]'), '');
    }

    // If not URL → return original string
    return code;
  }

  /// Checks if receipt exists in the system using scanned barcode
  Future<bool> checkReceipt(String scannedFinCode) async {
    final localizations = AppLocalizations.of(context)!;
    print("chal gaya kutta ");
    print(' FINCODE $scannedFinCode');

    stringscanedfincode = _cleanScanCode(scannedFinCode);

    print(scannedFinCode.toString());
    print(' FINCODE Cleaned $stringscanedfincode');

    try {
      final localizations = AppLocalizations.of(context)!;
      final prefs = await SharedPreferences.getInstance();
      final clientID = prefs.getString('clientID');
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');
      final trdr = prefs.getString('TRDR');

      if (!_validateConfiguration(clientID, companyUrl, softwareType, trdr)) {
        return false;
      }

      final servicePath = _getServicePath(softwareType!);
      final uri = _buildApiUri(companyUrl!, servicePath);
      final int fiscalYear = DateTime.now().year;

      final requestBody = _buildReceiptCheckRequest(
        clientID: clientID!,
        scannedFinCode: _cleanScanCode(scannedFinCode),
        fiscalYear: fiscalYear,
        trdr: trdr!,
      );

      // 🔴 YAHAN PRINT KARO - PAYLOAD
      print("========== RECEIPT CHECK API PAYLOAD ==========");
      print("API URL: $uri");
      print("REQUEST BODY:");
      print(jsonEncode(requestBody));
      print("===============================================");

      final response = await _makeApiCall(uri, requestBody);

      // 🔴 YAHAN PRINT KARO - RESPONSE
      print("========== RECEIPT CHECK API RESPONSE ==========");
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY:");
      print(response.body);
      print(' chall? $response.body');
      print("================================================");

      print("9075 ayaaaa  $response");
      print("API RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        return await _processReceiptResponse(response);
      } else {
        _showErrorMessage(
          localizations.failedToCheckReceiptCode.replaceFirst(
            '%s',
            response.statusCode.toString(),
          ),
        );
        return false;
      }
    } catch (e) {
      debugPrint('❗ Exception in checkReceipt(): $e');
      _showErrorMessage(
        localizations.errorCheckingReceipt.replaceFirst('%s', e.toString()),
      );
      return false;
    }
  }
  // Future<bool> checkReceipt(String scannedFinCode) async {
  //   final localizations = AppLocalizations.of(context)!;
  //   print("chal gaya kutta ");
  //   print(' FINCODE $scannedFinCode');

  //   stringscanedfincode = _cleanScanCode(scannedFinCode);

  //   print(scannedFinCode.toString());
  //   print(' FINCODE Cleaned $stringscanedfincode');

  //   try {
  //     final localizations = AppLocalizations.of(context)!;
  //     final prefs = await SharedPreferences.getInstance();
  //     final clientID = prefs.getString('clientID');
  //     final companyUrl = prefs.getString('company_url');
  //     final softwareType = prefs.getString('software_type');
  //     final trdr = prefs.getString('TRDR');

  //     if (!_validateConfiguration(clientID, companyUrl, softwareType, trdr)) {
  //       return false;
  //     }

  //     final servicePath = _getServicePath(softwareType!);
  //     final uri = _buildApiUri(companyUrl!, servicePath);
  //     final int fiscalYear = DateTime.now().year;

  //     final requestBody = _buildReceiptCheckRequest(
  //       clientID: clientID!,
  //       // scannedFinCode: scannedFinCode,
  //       scannedFinCode: _cleanScanCode(scannedFinCode),
  //       fiscalYear: fiscalYear,
  //       trdr: trdr!,
  //     );

  //     final response = await _makeApiCall(uri, requestBody);
  //     print("9075 ayaaaa  $response");
  //     print("API RESPONSE BODY: ${response.body}");

  //     if (response.statusCode == 200) {
  //       return await _processReceiptResponse(response);
  //     } else {
  //       _showErrorMessage(
  //         localizations.failedToCheckReceiptCode.replaceFirst(
  //           '%s',
  //           response.statusCode.toString(),
  //         ),
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     debugPrint('❗ Exception in checkReceipt(): $e');
  //     _showErrorMessage(
  //       localizations.errorCheckingReceipt.replaceFirst('%s', e.toString()),
  //     );
  //     return false;
  //   }
  // }

  /// Validates required configuration parameters
  bool _validateConfiguration(
    String? clientID,
    String? companyUrl,
    String? softwareType,
    String? trdr,
  ) {
    final localizations = AppLocalizations.of(context)!;
    if (clientID == null ||
        companyUrl == null ||
        softwareType == null ||
        trdr == null) {
      _showErrorMessage(localizations.missingConfiguration);
      return false;
    }
    return true;
  }

  /// Returns appropriate service path based on software type
  String _getServicePath(String softwareType) {
    return softwareType == "TESAE"
        ? "/pegasus/a_xit/connector.php"
        : "/s1services";
  }

  /// Builds API URI with CORS proxy
  Uri _buildApiUri(String companyUrl, String servicePath) {
    return Uri.parse("${ApiConstants.baseUrl}https://$companyUrl$servicePath");
  }

  /// Builds request body for receipt check

  /// Builds request body for receipt check
  ///

  Map<String, dynamic> _buildReceiptCheckRequest({
    required String clientID,
    required String scannedFinCode,
    required int fiscalYear,
    required String trdr,
  }) {
    final requestBody = {
      "service": "SqlData",
      "clientID": clientID,
      "appId": "1001",
      "SqlName": "9705",
      "findoc": scannedFinCode,
    };

    // 🔴 YAHAN PRINT KARO
    print("========== RECEIPT CHECK REQUEST (FROM BUILDER) ==========");
    print(jsonEncode(requestBody));
    print(' ye he $requestBody');
    print("==========================================================");

    return requestBody;
  }

  // Map<String, dynamic> _buildReceiptCheckRequest({
  //   required String clientID,
  //   required String scannedFinCode,
  //   required int fiscalYear,
  //   required String trdr,
  // }) {
  //   return {
  //     "service": "SqlData",
  //     "clientID": clientID,
  //     "appId": "1001",
  //     "SqlName": "9705",
  //     "findoc": scannedFinCode, // Scanned number  directly use in
  //     // "findoc": int.parse(scannedFinCode), // Scanned number  directly use in
  //   };
  // }

  // Map<String, dynamic> _buildReceiptCheckRequest({
  //   required String clientID,
  //   required String scannedFinCode,
  //   required int fiscalYear,
  //   required String trdr,S
  // }) {
  //   return {
  //     "service": "getBrowserInfo",
  //     "clientID": clientID,
  //     "appId": "1001",
  //     "OBJECT": "SALDOC",
  //     "LIST": "",
  //     "VERSION": 2,
  //     "LIMIT": 1,
  //     "FILTERS":
  //         "SALDOC.FINCODE='$scannedFinCode'&SALDOC.FISCPRD=$fiscalYear&SALDOC.TRDR=$trdr",
  //   };
  // }

  /// Makes HTTP POST request to API
  Future<http.Response> _makeApiCall(Uri uri, Map<String, dynamic> body) async {
    return await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  /// Processes the API response for receipt check
  /// Processes the API response for receipt check
  /// Processes the API response for receipt check
  ///
  ///

  Future<bool> _processReceiptResponse(http.Response response) async {
    final localizations = AppLocalizations.of(context)!;
    final data = jsonDecode(response.body);
    final totalCount = data['totalcount'] ?? 0;

    // 🔴 YAHAN PRINT KARO - PARSED DATA
    print("========== PROCESSED RECEIPT DATA ==========");
    print("Total Count: $totalCount");
    print("Full Parsed Data:");
    print(jsonEncode(data));
    print("============================================");

    if (totalCount == 0 || data['rows'] == null || data['rows'].isEmpty) {
      _showErrorMessage(localizations.noReceiptFound);
      return false;
    }

    final rows = data['rows'];
    final receiptRow = rows[0];

    if (receiptRow['findoc'] == null) {
      _showErrorMessage(localizations.noReceiptFound);
      return false;
    }

    final String findocID = receiptRow['findoc'].toString();
    debugPrint('✅ Receipt exists. FINDOC: $findocID');

    return await setBonusToReceipt(findocID: findocID, cardPoints: '');
  }
  // Future<bool> _processReceiptResponse(http.Response response) async {
  //   final localizations = AppLocalizations.of(context)!;
  //   final data = jsonDecode(response.body);
  //   final totalCount = data['totalcount'] ?? 0;

  //   // Agar totalcount 0 hai ya rows empty hain, to proceed mat karo
  //   if (totalCount == 0 || data['rows'] == null || data['rows'].isEmpty) {
  //     _showErrorMessage(localizations.noReceiptFound);
  //     return false; // setData API nahi chalegi
  //   }

  //   final rows = data['rows'];
  //   final receiptRow = rows[0];

  //   // Check if findoc exists in the response
  //   if (receiptRow['findoc'] == null) {
  //     _showErrorMessage(localizations.noReceiptFound);
  //     return false;
  //   }

  //   final String findocID = receiptRow['findoc'].toString();
  //   debugPrint('✅ Receipt exists. FINDOC: $findocID');

  //   // Ab setData API chalegi
  //   return await setBonusToReceipt(
  //     findocID: findocID,
  //     cardPoints: '', // Not needed anymore
  //   );
  // }

  ///
  // Future<bool> _processReceiptResponse(http.Response response) async {
  //   final localizations = AppLocalizations.of(context)!;
  //   final data = jsonDecode(response.body);
  //   final totalCount = data['totalcount'] ?? 0;
  //   if (totalCount == 0) {
  //     _showErrorMessage(localizations.noReceiptFound);
  //    return false;
  //   }
  //   final rows = data['rows'];
  //   final receiptRow = rows[0];
  //   final String rawFindocKey = receiptRow[0];
  //   final String receiptAmount = receiptRow[7];
  //   final String findocID = rawFindocKey.split(';')[1];
  //   debugPrint('✅ Receipt exists. FINDOC: $findocID, Points: $receiptAmount');
  //   return await setBonusToReceipt(
  //     findocID: findocID,
  //     cardPoints: receiptAmount,
  //   );
  // }

  /// Assigns bonus points to the receipt
  Future<bool> setBonusToReceipt({
    required String findocID,
    required String cardPoints,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final localizations = AppLocalizations.of(context)!;
      final prefs = await SharedPreferences.getInstance();
      final clientID = prefs.getString('clientID');
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');
      final trdr = prefs.getString('TRDR');

      if (clientID == null || companyUrl == null || softwareType == null) {
        _showErrorMessage(localizations.missingConfiguration);
        return false;
      }

      final servicePath = _getServicePath(softwareType);
      final uri = _buildApiUri(companyUrl, servicePath);

      final requestBody = _buildBonusRequest(
        clientID: clientID,
        findocID: findocID,
        trdr: trdr!,
      );

      // 🔴 YAHAN PRINT KARO - PAYLOAD
      print("========== BONUS ASSIGN API PAYLOAD ==========");
      print("API URL: $uri");
      print("REQUEST BODY:");
      print(jsonEncode(requestBody));
      print("==============================================");

      final response = await _makeApiCall(uri, requestBody);

      // 🔴 YAHAN PRINT KARO - RESPONSE
      print("========== BONUS ASSIGN API RESPONSE ==========");
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY:");
      print(response.body);
      print("==============================================");

      if (response.statusCode == 200) {
        return _processBonusResponse(response);
      } else {
        _showErrorMessage(
          localizations.serverError.replaceFirst(
            '%s',
            response.statusCode.toString(),
          ),
        );
        return false;
      }
    } catch (e) {
      debugPrint('❗ setBonusToReceipt exception: $e');
      _showErrorMessage(
        localizations.errorApplyingBonus.replaceFirst('%s', e.toString()),
      );
      return false;
    }
  }
  // Future<bool> setBonusToReceipt({
  //   required String findocID,
  //   required String cardPoints,
  // }) async {
  //   final localizations = AppLocalizations.of(context)!;
  //   try {
  //     final localizations = AppLocalizations.of(context)!;
  //     final prefs = await SharedPreferences.getInstance();
  //     final clientID = prefs.getString('clientID');
  //     final companyUrl = prefs.getString('company_url');
  //     final softwareType = prefs.getString('software_type');
  //     final trdr = prefs.getString('TRDR');

  //     if (clientID == null || companyUrl == null || softwareType == null) {
  //       _showErrorMessage(localizations.missingConfiguration);
  //       return false;
  //     }

  //     final servicePath = _getServicePath(softwareType);
  //     final uri = _buildApiUri(companyUrl, servicePath);

  //     final requestBody = _buildBonusRequest(
  //       clientID: clientID,
  //       findocID: findocID,
  //       // cardPoints: cardPoints,
  //       trdr: trdr!,
  //     );

  //     final response = await _makeApiCall(uri, requestBody);

  //     if (response.statusCode == 200) {
  //       return _processBonusResponse(response);
  //     } else {
  //       _showErrorMessage(
  //         localizations.serverError.replaceFirst(
  //           '%s',
  //           response.statusCode.toString(),
  //         ),
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     debugPrint('❗ setBonusToReceipt exception: $e');
  //     _showErrorMessage(
  //       localizations.errorApplyingBonus.replaceFirst('%s', e.toString()),
  //     );
  //     return false;
  //   }
  // }
  Map<String, dynamic> _buildBonusRequest({
    required String clientID,
    required String findocID,
    required String trdr,
  }) {
    final requestBody = {
      "service": "setData",
      "clientID": clientID,
      "appId": "1001",
      "OBJECT": "SALDOC",
      "KEY": findocID,
      "data": {
        "SALDOC": [
          {"CCCXITLOYALTYTRDR": trdr, "BOOL01": 1},
        ],
      },
    };

    // 🔴 YAHAN PRINT KARO - BONUS REQUEST
    print("========== BONUS REQUEST (FROM BUILDER) ==========");
    print(jsonEncode(requestBody));
    print("==================================================");

    return requestBody;
  }
  // Map<String, dynamic> _buildBonusRequest({
  //   required String clientID,
  //   required String findocID,
  //   required String trdr, // member ka trdr
  // }) {
  //   return {
  //     "service": "setData",
  //     "clientID": clientID,
  //     "appId": "1001",
  //     "OBJECT": "SALDOC",
  //     "KEY": findocID,
  //     "data": {
  //       "SALDOC": [
  //         {"CCCXITLOYALTYTRDR": trdr, "BOOL01": 1},
  //       ],
  //     },
  //   };
  // }

  /// Processes the bonus assignment response
  /// Builds request body for bonus assignment
  // Map<String, dynamic> _buildBonusRequest({
  //   required String clientID,
  //   required String findocID,
  //   required String cardPoints,
  // }) {
  //   return {
  //     "service": "setData",
  //     "clientID": clientID,
  //     "appId": "1001",
  //     "OBJECT": "SALDOC",
  //     "KEY": findocID,
  //     "data": {
  //       "SALDOC": [
  //         {"BUSUNITS": "8073", "NUM01": cardPoints},
  //       ],
  //     },
  //   };
  // }
  bool _processBonusResponse(http.Response response) {
    final localizations = AppLocalizations.of(context)!;
    final data = jsonDecode(response.body);

    // 🔴 YAHAN PRINT KARO - BONUS RESPONSE PARSED
    print("========== PROCESSED BONUS DATA ==========");
    print("Success: ${data['success']}");
    print("Full Parsed Data:");
    print(jsonEncode(data));
    print("==========================================");

    if (data['success'] == true) {
      _showSuccessMessage(localizations.bonusSuccessfullyApplied);
      return true;
    } else {
      _showErrorMessage(
        localizations.failedToApplyBonus.replaceFirst(
          '%s',
          data['error'] ?? localizations.unknownError,
        ),
      );
      return false;
    }
  }

  // bool _processBonusResponse(http.Response response) {
  //   final localizations = AppLocalizations.of(context)!;
  //   final data = jsonDecode(response.body);
  //   if (data['success'] == true) {
  //     _showSuccessMessage(localizations.bonusSuccessfullyApplied);
  //     return true;
  //   } else {
  //     _showErrorMessage(
  //       localizations.failedToApplyBonus.replaceFirst(
  //         '%s',
  //         data['error'] ?? localizations.unknownError,
  //       ),
  //     );
  //     return false;
  //   }
  // }

  /// Shows success message using SnackBar
  /// Shows success message using SnackBar + celebration overlay
  ///
  void _showSuccessMessage(String message) {
    if (!mounted) return;

    // Pehle snackbar
    SnackbarUtil.showCustomSnackBar(
      context: context,
      isSuccess: true,
      message: message,
    );

    // Thodi delay de do taake screen properly settle ho jaye
    Future.delayed(const Duration(milliseconds: 300), () {
      _showCelebrationOverlay(message);
    });
  }

  ///
  // void _showSuccessMessage(String message) {
  //   SnackbarUtil.showCustomSnackBar(
  //     context: context,
  //     isSuccess: true,
  //     message: message,
  //   );
  // }

  /// Shows error message using SnackBar
  void _showErrorMessage(String message) {
    SnackbarUtil.showCustomSnackBar(
      context: context,
      isSuccess: false,
      message: message,
    );
  }

  /// Shows full-screen celebration overlay for 2 seconds
  void _showCelebrationOverlay(String message) {
    // Ensure widget is still mounted
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return _CelebrationOverlay(message: message);
        },
        transitionBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
      ).then((_) {
        // dialog close ho gaya
      });

      // Auto-dismiss after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    });
  }

  /// Navigates to QR Scanner screen
  void _navigateToScanner() {
    if (kIsWeb) {
      _showNotSupportedDialog();
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => QRScannerScreen(
          onScanComplete: (scannedData) async {
            if (scannedData != null) {
              await checkReceipt(
                scannedData,
              ); // Only check receipt when scanning
            }
          },
        ),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        maintainState: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with company logo
            const SizedBox(height: 20),
            // Logo
            Center(
              child: Image.asset(
                'assets/images/app-logo.png',
                height: 100,
                width: 600,
              ),
            ),
            const SizedBox(height: 2),

            Container(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/scan-reciept.png',
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Orange section with receipt

            // Bottom section with text and button
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    localizations.scanYourReceipt,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.earnPointsInstantly,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Scan button

                  // Scan button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: _navigateToScanner,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localizations.startScanning,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation bar
    );
  }

  /// Shows dialog for unsupported web platform
  void _showNotSupportedDialog() {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.web_asset_off, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              localizations.notAvailable,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          localizations.qrNotSupportedWeb,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            height: 1.4,
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Text(
                    localizations.gotIt,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  final Function(String?) onScanComplete;

  const QRScannerScreen({super.key, required this.onScanComplete});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  late MobileScannerController _controller;
  String? _scannedData;
  bool _isProcessing = false;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _initializeAnimations();
  }

  void _initializeScanner() {
    _controller = MobileScannerController();
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.linear),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (kIsWeb) {
      return _buildWebUnsupportedView(localizations);
    }

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          localizations.scanYourReceipt,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          _buildCameraView(),
          _buildScanningOverlay(),
          _buildInstructions(localizations),
          if (_isProcessing) _buildProcessingOverlay(localizations),
        ],
      ),
    );
  }

  /// Builds camera view for scanning
  Widget _buildCameraView() {
    return MobileScanner(
      controller: _controller,
      onDetect: _handleBarcodeDetection,
    );
  }

  /// Handles barcode detection
  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final scannedValue = barcode.rawValue;
      if (scannedValue != null) {
        setState(() {
          _scannedData = scannedValue;
          _isProcessing = true;
        });
        _controller.stop();
        debugPrint('📱 Scanned Data: $scannedValue');

        // ❌ HATA DIYA: _showSuccessDialog(scannedValue);
        // ✅ SEEDHA API CALL - loading overlay dikhega, dialog nahi
        widget.onScanComplete(scannedValue).then((_) {
          if (mounted) {
            Navigator.pop(context); // API complete hone ke baad screen close
          }
        });
        break;
      }
    }
  }

  // void _handleBarcodeDetection(BarcodeCapture capture) {
  //   if (_isProcessing) return;

  //   final List<Barcode> barcodes = capture.barcodes;
  //   for (final barcode in barcodes) {
  //     final scannedValue = barcode.rawValue;
  //     if (scannedValue != null) {
  //       setState(() {
  //         _scannedData = scannedValue;
  //         _isProcessing = true;
  //       });
  //       _controller.stop();
  //       debugPrint('📱 Scanned Data: $scannedValue');
  //       _showSuccessDialog(scannedValue);
  //       break;
  //     }
  //   }
  // }

  /// Builds the scanning overlay
  Widget _buildScanningOverlay() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [..._buildCornerDecorations(), _buildScanningLine()],
          ),
        ),
      ),
    );
  }

  /// Builds corner decorations for scan area
  List<Widget> _buildCornerDecorations() {
    return List.generate(4, (index) {
      return Positioned(
        top: index < 2 ? 10.0 : null,
        bottom: index >= 2 ? 10.0 : null,
        left: index % 2 == 0 ? 10.0 : null,
        right: index % 2 == 1 ? 10.0 : null,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              top: index < 2
                  ? const BorderSide(color: Colors.orange, width: 3)
                  : BorderSide.none,
              bottom: index >= 2
                  ? const BorderSide(color: Colors.orange, width: 3)
                  : BorderSide.none,
              left: index % 2 == 0
                  ? const BorderSide(color: Colors.orange, width: 3)
                  : BorderSide.none,
              right: index % 2 == 1
                  ? const BorderSide(color: Colors.orange, width: 3)
                  : BorderSide.none,
            ),
          ),
        ),
      );
    });
  }

  /// Builds the animated scanning line
  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Positioned(
          top: (125 + (_scanAnimation.value * 100)).clamp(10.0, 230.0),
          left: 20,
          right: 20,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.transparent, Colors.orange, Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }

  /// Builds instruction text at bottom
  Widget _buildInstructions(AppLocalizations localizations) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, color: Colors.orange, size: 30),
            const SizedBox(height: 10),
            Text(
              _scannedData ?? localizations.positionQrCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds processing overlay
  Widget _buildProcessingOverlay(AppLocalizations localizations) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.processing,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait...', // ya localizations string use karo
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Widget _buildProcessingOverlay(AppLocalizations localizations) {
  //   return Container(
  //     color: Colors.black.withOpacity(0.8),
  //     child: Center(
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const CircularProgressIndicator(
  //             valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             localizations.processing,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 16,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  /// Builds web unsupported view
  Widget _buildWebUnsupportedView(AppLocalizations localizations) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              localizations.qrScannerNotAvailableWeb,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $urlString");
    }
  }

  /// Shows success dialog after successful scan
  void _showSuccessDialog(String scannedData) {
    final localizations = AppLocalizations.of(context)!;
    final bool isUrl = _isValidUrl(scannedData);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              localizations.scanSuccessful,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                '${localizations.scanned}: $scannedData',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // ✅ OPEN URL BUTTON (Only if URL)
            if (isUrl) ...[
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.blue,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () async {
                      await _openUrl(scannedData);
                    },
                    child: const Center(
                      child: Text(
                        "Open URL",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ✅ CONTINUE BUTTON
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    await widget.onScanComplete(scannedData);
                  },
                  child: Center(
                    child: Text(
                      localizations.continueText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:loyalty_app/utils/api_constants.dart';
// import 'package:loyalty_app/utils/snackbar.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ScanReceiptScreen extends StatefulWidget {
//   const ScanReceiptScreen({super.key});

//   @override
//   State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
// }

// class _ScanReceiptScreenState extends State<ScanReceiptScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _pulseController;
//   late AnimationController _slideController;
//   late Animation<double> _pulseAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     // Removed the checkReceipt call from here - it should only run when scanning
//   }

//   void _initializeAnimations() {
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);

//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );

//     _slideAnimation =
//         Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
//           CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
//         );

//     _slideController.forward();
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _slideController.reset();
//     _slideController.forward();
//   }

//   /// Checks if receipt exists in the system using scanned barcode
//   Future<bool> checkReceipt(String scannedFinCode) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final clientID = prefs.getString('clientID');
//       final companyUrl = prefs.getString('company_url');
//       final softwareType = prefs.getString('software_type');
//       final trdr = prefs.getString('TRDR');

//       if (!_validateConfiguration(clientID, companyUrl, softwareType, trdr)) {
//         return false;
//       }

//       final servicePath = _getServicePath(softwareType!);
//       final uri = _buildApiUri(companyUrl!, servicePath);
//       final int fiscalYear = DateTime.now().year;

//       final requestBody = _buildReceiptCheckRequest(
//         clientID: clientID!,
//         scannedFinCode: scannedFinCode,
//         fiscalYear: fiscalYear,
//         trdr: trdr!,
//       );

//       final response = await _makeApiCall(uri, requestBody);

//       if (response.statusCode == 200) {
//         return await _processReceiptResponse(response);
//       } else {
//         _showErrorMessage(
//           'Failed to check receipt. Code: ${response.statusCode}',
//         );
//         return false;
//       }
//     } catch (e) {
//       debugPrint('❗ Exception in checkReceipt(): $e');
//       _showErrorMessage('Error checking receipt: ${e.toString()}');
//       return false;
//     }
//   }

//   /// Validates required configuration parameters
//   bool _validateConfiguration(
//     String? clientID,
//     String? companyUrl,
//     String? softwareType,
//     String? trdr,
//   ) {
//     if (clientID == null ||
//         companyUrl == null ||
//         softwareType == null ||
//         trdr == null) {
//       _showErrorMessage('Missing configuration. Please restart the app.');
//       return false;
//     }
//     return true;
//   }

//   /// Returns appropriate service path based on software type
//   String _getServicePath(String softwareType) {
//     return softwareType == "TESAE"
//         ? "/pegasus/a_xit/connector.php"
//         : "/s1services";
//   }

//   /// Builds API URI with CORS proxy
//   Uri _buildApiUri(String companyUrl, String servicePath) {
//     return Uri.parse("${ApiConstants.baseUrl}https://$companyUrl$servicePath");
//   }

//   /// Builds request body for receipt check
//   Map<String, dynamic> _buildReceiptCheckRequest({
//     required String clientID,
//     required String scannedFinCode,
//     required int fiscalYear,
//     required String trdr,
//   }) {
//     return {
//       "service": "getBrowserInfo",
//       "clientID": clientID,
//       "appId": "1001",
//       "OBJECT": "SALDOC",
//       "LIST": "",
//       "VERSION": 2,
//       "LIMIT": 1,
//       "FILTERS":
//           "SALDOC.FINCODE='$scannedFinCode'&SALDOC.FISCPRD=$fiscalYear&SALDOC.TRDR=$trdr",
//     };
//   }

//   /// Makes HTTP POST request to API
//   Future<http.Response> _makeApiCall(Uri uri, Map<String, dynamic> body) async {
//     return await http.post(
//       uri,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(body),
//     );
//   }

//   /// Processes the API response for receipt check
//   Future<bool> _processReceiptResponse(http.Response response) async {
//     final data = jsonDecode(response.body);
//     final totalCount = data['totalcount'] ?? 0;

//     if (totalCount == 0) {
//       _showErrorMessage('No receipt found for this customer.');
//       return false;
//     }

//     final rows = data['rows'];
//     final receiptRow = rows[0];
//     final String rawFindocKey = receiptRow[0];
//     final String receiptAmount = receiptRow[7];
//     final String findocID = rawFindocKey.split(';')[1];

//     debugPrint('✅ Receipt exists. FINDOC: $findocID, Points: $receiptAmount');

//     return await setBonusToReceipt(
//       findocID: findocID,
//       cardPoints: receiptAmount,
//     );
//   }

//   /// Assigns bonus points to the receipt
//   Future<bool> setBonusToReceipt({
//     required String findocID,
//     required String cardPoints,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final clientID = prefs.getString('clientID');
//       final companyUrl = prefs.getString('company_url');
//       final softwareType = prefs.getString('software_type');

//       if (clientID == null || companyUrl == null || softwareType == null) {
//         _showErrorMessage('Missing configuration. Please restart the app.');
//         return false;
//       }

//       final servicePath = _getServicePath(softwareType);
//       final uri = _buildApiUri(companyUrl, servicePath);

//       final requestBody = _buildBonusRequest(
//         clientID: clientID,
//         findocID: findocID,
//         cardPoints: cardPoints,
//       );

//       final response = await _makeApiCall(uri, requestBody);

//       if (response.statusCode == 200) {
//         return _processBonusResponse(response);
//       } else {
//         _showErrorMessage('Server error: ${response.statusCode}');
//         return false;
//       }
//     } catch (e) {
//       debugPrint('❗ setBonusToReceipt exception: $e');
//       _showErrorMessage('Error applying bonus: ${e.toString()}');
//       return false;
//     }
//   }

//   /// Builds request body for bonus assignment
//   Map<String, dynamic> _buildBonusRequest({
//     required String clientID,
//     required String findocID,
//     required String cardPoints,
//   }) {
//     return {
//       "service": "setData",
//       "clientID": clientID,
//       "appId": "1001",
//       "OBJECT": "SALDOC",
//       "KEY": findocID,
//       "data": {
//         "SALDOC": [
//           {"BUSUNITS": "8073", "NUM01": cardPoints},
//         ],
//       },
//     };
//   }

//   /// Processes the bonus assignment response
//   bool _processBonusResponse(http.Response response) {
//     final data = jsonDecode(response.body);
//     if (data['success'] == true) {
//       _showSuccessMessage('Bonus successfully applied to receipt.');
//       return true;
//     } else {
//       _showErrorMessage(
//         'Failed to apply bonus: ${data['error'] ?? 'Unknown error'}',
//       );
//       return false;
//     }
//   }

//   /// Shows success message using SnackBar
//   void _showSuccessMessage(String message) {
//     SnackbarUtil.showCustomSnackBar(
//       context: context,
//       isSuccess: true,
//       message: message,
//     );
//   }

//   /// Shows error message using SnackBar
//   void _showErrorMessage(String message) {
//     SnackbarUtil.showCustomSnackBar(
//       context: context,
//       isSuccess: false,
//       message: message,
//     );
//   }

//   /// Navigates to QR Scanner screen
//   void _navigateToScanner() {
//     if (kIsWeb) {
//       _showNotSupportedDialog();
//       return;
//     }

//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, _) => QRScannerScreen(
//           onScanComplete: (scannedData) async {
//             if (scannedData != null) {
//               await checkReceipt(
//                 scannedData,
//               ); // Only check receipt when scanning
//             }
//           },
//         ),
//         transitionsBuilder: (context, animation, _, child) {
//           return SlideTransition(
//             position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
//                 .animate(
//                   CurvedAnimation(parent: animation, curve: Curves.easeInOut),
//                 ),
//             child: child,
//           );
//         },
//         transitionDuration: const Duration(milliseconds: 300),
//         maintainState: false,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),

//       body: Column(
//         children: [
//           // Header with company logo
//           const SizedBox(height: 20),
//           // Logo
//           Center(
//             child: Image.asset(
//               'assets/images/app-logo.png',
//               height: 100,
//               width: 600,
//             ),
//           ),
//           const SizedBox(height: 2),

//           Container(
//             child: Column(
//               children: [
//                 Image.asset(
//                   'assets/images/scan-reciept.png',
//                   height: 300,
//                   width: double.infinity,
//                   fit: BoxFit.contain,
//                 ),
//                 const SizedBox(height: 10),
//               ],
//             ),
//           ),

//           // Orange section with receipt

//           // Bottom section with text and button
//           Container(
//             color: const Color(0xFFF5F5F5),
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               children: [
//                 const Text(
//                   'Scan your Receipt',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Earn points instantly and\nunlock amazing rewards',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey,
//                     height: 1.4,
//                   ),
//                 ),
//                 const SizedBox(height: 30),

//                 // Scan button
//                 Container(
//                   width: double.infinity,
//                   height: 56,
//                   decoration: BoxDecoration(
//                     color: Colors.black,
//                     borderRadius: BorderRadius.circular(28),
//                   ),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(28),
//                       onTap: _navigateToScanner,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(
//                               Icons.qr_code_scanner,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           const Text(
//                             'START SCANNING',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               letterSpacing: 1,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ],
//       ),

//       // Bottom navigation bar
//     );
//   }

//   /// Shows dialog for unsupported web platform
//   void _showNotSupportedDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF1a1a2e),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(
//                 Icons.web_asset_off,
//                 color: Colors.red,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 12),
//             const Text(
//               "Not Available",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           "QR code scanning is not supported on web browsers. Please use the mobile app for the best experience.",
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.8),
//             fontSize: 16,
//             height: 1.4,
//           ),
//         ),
//         actions: [
//           Container(
//             width: double.infinity,
//             height: 50,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(25),
//               gradient: const LinearGradient(
//                 colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
//               ),
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(25),
//                 onTap: () => Navigator.pop(context),
//                 child: const Center(
//                   child: Text(
//                     "Got It",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // QRScannerScreen remains the same as in your original code
// class QRScannerScreen extends StatefulWidget {
//   final Function(String?) onScanComplete;

//   const QRScannerScreen({super.key, required this.onScanComplete});

//   @override
//   State<QRScannerScreen> createState() => _QRScannerScreenState();
// }

// class _QRScannerScreenState extends State<QRScannerScreen>
//     with TickerProviderStateMixin {
//   late MobileScannerController _controller;
//   String? _scannedData;
//   bool _isProcessing = false;
//   late AnimationController _scanAnimationController;
//   late Animation<double> _scanAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeScanner();
//     _initializeAnimations();
//   }

//   void _initializeScanner() {
//     _controller = MobileScannerController();
//   }

//   void _initializeAnimations() {
//     _scanAnimationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat();

//     _scanAnimation = Tween<double>(begin: -1, end: 1).animate(
//       CurvedAnimation(parent: _scanAnimationController, curve: Curves.linear),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (kIsWeb) {
//       return _buildWebUnsupportedView();
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           _buildCameraView(),
//           _buildScanningOverlay(),
//           _buildInstructions(),
//           if (_isProcessing) _buildProcessingOverlay(),
//         ],
//       ),
//     );
//   }

//   /// Builds the app bar

//   /// Builds camera view for scanning
//   Widget _buildCameraView() {
//     return MobileScanner(
//       controller: _controller,
//       onDetect: _handleBarcodeDetection,
//     );
//   }

//   /// Handles barcode detection
//   void _handleBarcodeDetection(BarcodeCapture capture) {
//     if (_isProcessing) return;

//     final List<Barcode> barcodes = capture.barcodes;
//     for (final barcode in barcodes) {
//       final scannedValue = barcode.rawValue;
//       if (scannedValue != null) {
//         setState(() {
//           _scannedData = scannedValue;
//           _isProcessing = true;
//         });
//         _controller.stop();
//         debugPrint('📱 Scanned Data: $scannedValue');
//         _showSuccessDialog(scannedValue);
//         break;
//       }
//     }
//   }

//   /// Builds the scanning overlay
//   Widget _buildScanningOverlay() {
//     return Container(
//       decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
//       child: Center(
//         child: Container(
//           width: 250,
//           height: 250,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.white, width: 2),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Stack(
//             children: [..._buildCornerDecorations(), _buildScanningLine()],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Builds corner decorations for scan area
//   List<Widget> _buildCornerDecorations() {
//     return List.generate(4, (index) {
//       return Positioned(
//         top: index < 2 ? 10 : null,
//         bottom: index >= 2 ? 10 : null,
//         left: index % 2 == 0 ? 10 : null,
//         right: index % 2 == 1 ? 10 : null,
//         child: Container(
//           width: 20,
//           height: 20,
//           decoration: BoxDecoration(
//             border: Border(
//               top: index < 2
//                   ? const BorderSide(color: Colors.orange, width: 3)
//                   : BorderSide.none,
//               bottom: index >= 2
//                   ? const BorderSide(color: Colors.orange, width: 3)
//                   : BorderSide.none,
//               left: index % 2 == 0
//                   ? const BorderSide(color: Colors.orange, width: 3)
//                   : BorderSide.none,
//               right: index % 2 == 1
//                   ? const BorderSide(color: Colors.orange, width: 3)
//                   : BorderSide.none,
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   /// Builds the animated scanning line
//   Widget _buildScanningLine() {
//     return AnimatedBuilder(
//       animation: _scanAnimation,
//       builder: (context, child) {
//         return Positioned(
//           top: (125 + (_scanAnimation.value * 100)).clamp(10.0, 230.0),
//           left: 20,
//           right: 20,
//           child: Container(
//             height: 2,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Colors.transparent, Colors.orange, Colors.transparent],
//               ),
//               borderRadius: BorderRadius.circular(1),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   /// Builds instruction text at bottom
//   Widget _buildInstructions() {
//     return Positioned(
//       bottom: 100,
//       left: 0,
//       right: 0,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 40),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.7),
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.qr_code_2, color: Colors.orange, size: 30),
//             const SizedBox(height: 10),
//             Text(
//               _scannedData ?? 'Position QR code within the frame',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Builds processing overlay
//   Widget _buildProcessingOverlay() {
//     return Container(
//       color: Colors.black.withOpacity(0.8),
//       child: const Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Processing...',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Builds web unsupported view
//   Widget _buildWebUnsupportedView() {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
//           ),
//         ),
//         child: const Center(
//           child: Text(
//             "QR Scanner is not available on Web.",
//             style: TextStyle(color: Colors.white, fontSize: 18),
//           ),
//         ),
//       ),
//     );
//   }

//   /// Shows success dialog after successful scan
//   void _showSuccessDialog(String scannedData) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF1a1a2e),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.check_circle,
//                 color: Colors.green,
//                 size: 60,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Scan Successful!',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 24,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.05),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.1),
//                   width: 1,
//                 ),
//               ),
//               child: Text(
//                 'Scanned: $scannedData',
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.8),
//                   fontSize: 14,
//                   fontFamily: 'monospace',
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Container(
//               width: double.infinity,
//               height: 50,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(25),
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
//                 ),
//               ),
//               child: Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(25),
//                   onTap: () async {
//                     Navigator.pop(context); // Close dialog
//                     Navigator.pop(context); // Return to main screen

//                     // Call the callback with scanned data
//                     await widget.onScanComplete(scannedData);
//                   },
//                   child: const Center(
//                     child: Text(
//                       'Continue',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _scanAnimationController.dispose();
//     _controller.dispose();
//     super.dispose();
//   }
// }
// ============================================================
// 🎉 CELEBRATION OVERLAY WIDGET
// ============================================================
class _CelebrationOverlay extends StatefulWidget {
  final String message;
  const _CelebrationOverlay({required this.message});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with TickerProviderStateMixin {
  late List<_ParticleModel> _particles;
  late List<_BalloonModel> _balloons;
  late AnimationController _controller;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  final List<Color> _confettiColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
    Colors.amber,
    const Color(0xFFFF6B35),
  ];

  final List<Color> _balloonColors = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _scaleController.forward();

    final random = DateTime.now().millisecondsSinceEpoch;
    _particles = List.generate(
      80,
      (i) => _ParticleModel(
        x:
            (((random * (i + 1) * 6364136223846793005 + 1442695040888963407) >>
                    17) &
                0xFFFF) /
            0xFFFF,
        startY: 1.0 + (i % 5) * 0.1,
        size: 6.0 + (i % 8) * 2.0,
        color: _confettiColors[i % _confettiColors.length],
        speed: 0.4 + (i % 6) * 0.1,
        wobble: (i % 3) * 0.15,
        shape: i % 3,
      ),
    );

    _balloons = List.generate(
      12,
      (i) => _BalloonModel(
        x: 0.05 + (i * 0.09) % 0.90,
        size: 28.0 + (i % 5) * 10.0,
        color: _balloonColors[i % _balloonColors.length],
        speed: 0.3 + (i % 4) * 0.08,
        delay: (i % 5) * 0.1,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent blurred background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.40),
                ],
              ),
            ),
          ),

          // Animated confetti particles (bottom to top)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                  screenSize: size,
                ),
                size: size,
              );
            },
          ),

          // Balloons floating up
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: _balloons.map((balloon) {
                  final progress =
                      ((_controller.value - balloon.delay) /
                              (1.0 - balloon.delay))
                          .clamp(0.0, 1.0);
                  final yPos =
                      size.height -
                      (progress * (size.height + balloon.size * 2));
                  final wobbleX =
                      balloon.x * size.width +
                      (20 * (0.5 - balloon.x) * progress);

                  return Positioned(
                    left: wobbleX - balloon.size / 2,
                    top: yPos - balloon.size,
                    child: Opacity(
                      opacity: progress < 0.1
                          ? progress * 10
                          : (progress > 0.8 ? (1.0 - progress) * 5 : 1.0),
                      child: _buildBalloon(balloon),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Center success card
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Big success icon with glow
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.6),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.greenAccent,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🎉 emoji row
                    const Text('🎉 🎈 🎊', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 12),

                    // Success title
                    const Text(
                      'Points Added!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: Colors.greenAccent, blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Message
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalloon(_BalloonModel balloon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Balloon body
        Container(
          width: balloon.size,
          height: balloon.size * 1.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [
                balloon.color.withOpacity(0.95),
                balloon.color.withOpacity(0.7),
                balloon.color.withOpacity(0.5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: balloon.color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // String
        Container(
          width: 1.5,
          height: balloon.size * 0.6,
          color: balloon.color.withOpacity(0.6),
        ),
      ],
    );
  }
}

// Particle model
class _ParticleModel {
  final double x;
  final double startY;
  final double size;
  final Color color;
  final double speed;
  final double wobble;
  final int shape; // 0=circle, 1=rect, 2=diamond

  _ParticleModel({
    required this.x,
    required this.startY,
    required this.size,
    required this.color,
    required this.speed,
    required this.wobble,
    required this.shape,
  });
}

// Balloon model
class _BalloonModel {
  final double x;
  final double size;
  final Color color;
  final double speed;
  final double delay;

  _BalloonModel({
    required this.x,
    required this.size,
    required this.color,
    required this.speed,
    required this.delay,
  });
}

// Particle painter
class _ParticlePainter extends CustomPainter {
  final List<_ParticleModel> particles;
  final double progress;
  final Size screenSize;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final t = (progress * p.speed * 2.5).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = p.x * size.width + (p.wobble * size.width * (t - 0.5));
      final y = size.height * (1.0 - t * 1.3);

      if (y < -p.size) continue;

      final opacity = t > 0.7 ? (1.0 - t) * 3.0 : 1.0;
      final paint = Paint()
        ..color = p.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 6.28 * (i % 2 == 0 ? 1 : -1));

      if (p.shape == 0) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else if (p.shape == 1) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      } else {
        final path = Path();
        path.moveTo(0, -p.size / 2);
        path.lineTo(p.size / 2, 0);
        path.lineTo(0, p.size / 2);
        path.lineTo(-p.size / 2, 0);
        path.close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
