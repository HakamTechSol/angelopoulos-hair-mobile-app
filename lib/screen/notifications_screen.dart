import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loyalty_app/Services/language_service.dart';
import 'package:loyalty_app/Auth/LanguageSelectionPage.dart';
import 'package:loyalty_app/utils/api_constants.dart';
import 'package:loyalty_app/utils/language_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charset_converter/charset_converter.dart';

class NotificationsScreen extends StatefulWidget {
    final String? initialNotificationId;

  const NotificationsScreen({super.key , this.initialNotificationId, });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  String? errorMessage;
  bool isRefreshing = false;
  String userName = "User";
  String? profileImagePath;
  Timer? _autoMarkReadTimer;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUserName();
    loadTotalPoints();

    // Start timer to mark all as read after 3 seconds
    // _autoMarkReadTimer = Timer(const Duration(seconds: 3), () {
    //   _markAllNotificationsAsRead();
    // });
  }

  /// Enhanced Greek text decoder - handles multiple encoding scenarios
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

  // lanuage encof=dinge here
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

  @override
  void dispose() {
    _autoMarkReadTimer?.cancel();
    super.dispose();
  }

  /// Enhanced Greek text decoder - handles multiple encoding scenarios
  ///
  ///
  /// Check if text contains properly encoded Greek Unicode characters
  bool _containsGreekUnicode(String text) {
    // Greek Unicode range: U+0370–U+03FF and U+1F00–U+1FFF
    return text.runes.any(
      (rune) =>
          (rune >= 0x0370 && rune <= 0x03FF) ||
          (rune >= 0x1F00 && rune <= 0x1FFF),
    );
  }

  /// Check if text is Windows-1253 encoded (common Greek encoding)
  // bool _isWindows1253Encoded(String text) {
  //   // Windows-1253 specific characters that map to Greek
  //   final windows1253Indicators = [
  //     'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï',
  //     'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï',
  //     'ð', 'ñ', 'ò', 'ó', 'ô', 'õ', 'ö', '÷', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'þ'
  //   ];

  //   return windows1253Indicators.any((char) => text.contains(char));
  // }

  // /// Convert Windows-1253 encoded text to UTF-8
  // String _convertWindows1253ToUtf8(String text) {
  //   // Windows-1253 to Greek Unicode mapping
  //   final Map<String, String> windows1253ToGreek = {
  //     // Uppercase Greek letters
  //     'Á': 'Α', 'Â': 'Β', 'Ã': 'Γ', 'Ä': 'Δ', 'Å': 'Ε', 'Æ': 'Ζ', 'Ç': 'Η', 'È': 'Θ',
  //     'É': 'Ι', 'Ê': 'Κ', 'Ë': 'Λ', 'Ì': 'Μ', 'Í': 'Ν', 'Î': 'Ξ', 'Ï': 'Ο', 'Ð': 'Π',
  //     'Ñ': 'Ρ', 'Ó': 'Σ', 'Ô': 'Τ', 'Õ': 'Υ', 'Ö': 'Φ', '×': 'Χ', 'Ø': 'Ψ', 'Ù': 'Ω',

  //     // Lowercase Greek letters
  //     'á': 'α', 'â': 'β', 'ã': 'γ', 'ä': 'δ', 'å': 'ε', 'æ': 'ζ', 'ç': 'η', 'è': 'θ',
  //     'é': 'ι', 'ê': 'κ', 'ë': 'λ', 'ì': 'μ', 'í': 'ν', 'î': 'ξ', 'ï': 'ο', 'ð': 'π',
  //     'ñ': 'ρ', 'ò': 'ς', 'ó': 'σ', 'ô': 'τ', 'õ': 'υ', 'ö': 'φ', '÷': 'χ', 'ø': 'ψ', 'ù': 'ω',

  //     // Greek accented characters
  //     'Ú': 'Ί', 'Û': 'Ό', 'Ü': 'Ύ', 'Ý': 'Ώ', 'Þ': 'ΐ', 'ß': 'ΰ',
  //     'ú': 'ύ', 'û': 'ό', 'ü': 'ώ', 'ý': 'ή', 'þ': 'ί', 'ÿ': 'ϊ'
  //   };

  //   String converted = text;
  //   windows1253ToGreek.forEach((key, value) {
  //     converted = converted.replaceAll(key, value);
  //   });

  //   return converted;
  // }

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

  // lanuage function above
Future<void> _loadNotifications() async {
  try {
    if (!isRefreshing) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final companyUrl = prefs.getString('company_url');
    final softwareType = prefs.getString('software_type');
    final clientID = prefs.getString('clientID');
    final trdr = prefs.getString('TRDR');

    if (companyUrl == null || softwareType == null ||
        clientID == null || trdr == null) {
      throw Exception("Required settings are missing. Please login again.");
    }

    final servicePath = softwareType == "TESAE"
        ? "/pegasus/a_xit/connector.php"
        : "/s1services";

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
    );

    final client = http.Client();

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Accept-Charset': 'utf-8, iso-8859-7, windows-1253',
          'Accept-Language': 'el-GR, en-US, *',
          'User-Agent': 'LoyaltyApp/1.0',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        body: utf8.encode(jsonEncode({
          "service": "SqlData",
          "clientID": clientID,
          "appId": "1001",
          "SqlName": "9702",
          "trdr": trdr,
        })),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout. Please check your internet connection.');
      });

      if (response.statusCode == 200) {
        String responseBody = await decodeGreekResponseBytes(response.bodyBytes);

        if (kDebugMode) print('Decoded response body: $responseBody');

        final data = jsonDecode(responseBody);

        if (data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> rows = data['rows'] ?? [];

          setState(() {
            notifications = rows
                .map((row) => NotificationItem.fromApi(row, _decodeGreekText))
                .toList();
            isLoading = false;
            isRefreshing = false;
          });

          // ✅ Notifications load hone ke baad specific one open karo
          _openInitialNotificationIfNeeded();

        } else {
          throw Exception(data['message'] ?? "API request failed");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } finally {
      client.close();
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Failed to load notifications: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}';
      isLoading = false;
      isRefreshing = false;
    });
    if (kDebugMode) print('General error: $e');
  }
}

// ✅ Yeh method _loadNotifications ke BAHAR, class ke andar hona chahiye
void _openInitialNotificationIfNeeded() {
  if (widget.initialNotificationId == null) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    
    final targetNotification = notifications.firstWhere(
      (n) => n.id == widget.initialNotificationId,
      orElse: () => notifications.isNotEmpty
          ? notifications.first
          : NotificationItem(
              id: widget.initialNotificationId!,
              title: 'Notification',
              message: '',
              date: DateTime.now(),
              isRead: false,
            ),
    );

    _openNotificationDetail(targetNotification);
  });
}
  // Rest of your existing methods remain the same...
  Future<void> loadTotalPoints() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');
      final clientID = prefs.getString('clientID');
      final trdr = prefs.getString('TRDR');

      if (companyUrl == null ||
          softwareType == null ||
          clientID == null ||
          trdr == null) {
        throw Exception("Missing required SharedPreferences values");
      }

      final servicePath = softwareType == "TESAE"
          ? "/pegasus/a_xit/connector.php"
          : "/s1services";

      final uri = Uri.parse(
        "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
      );

      debugPrint("🔄 Making API call to: $uri");

      final requestBody = {
        "service": "SqlData",
        "clientID": clientID,
        "appId": "1001",
        "SqlName": "9700",
        "trdr": trdr,
      };

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'LoyaltyApp/1.0',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception("Request timeout");
            },
          );

      debugPrint("📥 Response status: ${response.statusCode}");
      debugPrint("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        String responseBody = await decodeGreekResponseBytes(
          response.bodyBytes,
        );
        final data = jsonDecode(responseBody);
        if (data is Map<String, dynamic> &&
            data['success'] == true &&
            data['rows'] != null &&
            data['rows'].isNotEmpty) {
          final points = data['rows'][0]['totalpoints']?.toString() ?? "0";
          final Name = data['rows'][0]['NAME']?.toString() ?? "unknown";
          await prefs.setString('Namee', Name);

          // Base64 image save karo
          final base64Image = data['rows'][0]['CCCXITLIMAGE']?.toString() ?? '';

          await prefs.setString('totalPoints', points);

          // Base64 image ko SharedPreferences me save karo
          if (base64Image.isNotEmpty) {
            await prefs.setString('user_profile_base64', base64Image);
          }

          if (mounted) {
            setState(() {
              userName = Name;

              profileImagePath = base64Image;
              _isLoading = false;
              _hasError = false;
            });
          }
          return;
        }
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("❗ Error loading total points: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    if (notifications.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');
      final clientID = prefs.getString('clientID');

      if (companyUrl == null || softwareType == null || clientID == null) {
        throw Exception("Missing required settings");
      }

      final servicePath = softwareType == "TESAE"
          ? "/pegasus/a_xit/connector.php"
          : "/s1services";

      final uri = Uri.parse(
        "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
      );

      List<Future> markReadRequests = [];

      for (var notification in notifications) {
        if (!notification.isRead) {
          final requestBody = {
            "service": "setData",
            "clientID": clientID,
            "appId": "1001",
            "OBJECT": "SOACTION",
            "KEY": notification.id,
            "data": {
              "SOACTION": [
                {"ACTSTATUS": "3"},
              ],
            },
          };

          markReadRequests.add(
            http
                .post(
                  uri,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'User-Agent': 'LoyaltyApp/1.0',
                  },
                  body: jsonEncode(requestBody),
                )
                .timeout(const Duration(seconds: 10)),
          );
        }
      }

      if (markReadRequests.isNotEmpty) {
        await Future.wait(markReadRequests);

        setState(() {
          for (var notification in notifications) {
            notification.isRead = true;
          }
        });

        if (kDebugMode) {
          print("✅ All notifications marked as read");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❗ Error marking all as read: $e");
      }
    }
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('NAME') ?? 'user';
      if (mounted) {
        setState(() {
          userName = name;
        });
      }
    } catch (e) {
      debugPrint("❗ Error loading user name: $e");
    }
  }

  Widget _defaultImageErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Icon(Icons.person, color: Color(0xFFEC7103), size: 30),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEC7103), Color(0xFFFF8A3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Top Logo
            Center(
              child: Image.asset(
                'assets/images/home-logo.png', // apna logo yahan rakho
                width: 230,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 8),

            // ✅ Profile + Welcome + Language
            Row(
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child:
                        (profileImagePath != null &&
                            profileImagePath!.isNotEmpty)
                        ? Image.memory(
                            base64Decode(
                              profileImagePath!,
                            ), // ✅ base64 to bytes
                            fit: BoxFit.cover,
                            errorBuilder: _defaultImageErrorBuilder,
                          )
                        : Image.asset(
                            'assets/images/profile_temp.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: _defaultImageErrorBuilder,
                          ),
                  ),
                ),

                const SizedBox(width: 15),

                // Welcome Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.welcome,
                        style: GoogleFonts.jura(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        userName,
                        style: GoogleFonts.jura(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Language Button
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSelectionPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.g_translate,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isRefreshing = true;
    });
    await _loadNotifications();
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (notification.isRead) {
      if (kDebugMode) print('Notification ${notification.id} is already read');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');
      final clientID = prefs.getString('clientID');

      if (companyUrl == null || softwareType == null || clientID == null) {
        throw Exception("Missing required settings");
      }

      final servicePath = softwareType == "TESAE"
          ? "/pegasus/a_xit/connector.php"
          : "/s1services";

      final uri = Uri.parse(
        "${ApiConstants.baseUrl}https://$companyUrl$servicePath",
      );

      if (kDebugMode) {
        print('🔄 Marking notification ${notification.id} as read...');
      }

      final requestBody = {
        "service": "setData",
        "clientID": clientID,
        "appId": "1001",
        "OBJECT": "SOACTION",
        "KEY": notification.id,
        "data": {
          "SOACTION": [
            {"ACTSTATUS": "3"},
          ],
        },
      };

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'LoyaltyApp/1.0',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print(
          '📥 Mark as read response: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['success'] == true) {
          setState(() {
            notification.isRead = true;
          });
          if (kDebugMode) {
            print(
              '✅ Notification ${notification.id} marked as read successfully',
            );
          }
        } else {
          throw Exception(data['message'] ?? "Failed to mark as read");
        }
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❗ Mark as read error for ${notification.id}: $e");
      }
      // Don't show snackbar for individual failures, just log
    }
  }

  void _openNotificationDetail(NotificationItem notification) {
    // Mark as read when opening detail
    _markAsRead(notification);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationDetailScreen(notification: notification),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        // Mark all as read when navigating back
        // setState(() {
        //   for (var notification in notifications) {
        //     notification.isRead = true;
        //   }
        // });
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeaderSection(context, localizations),
            Expanded(child: _buildBody(localizations)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations localizations) {
    if (isLoading && !isRefreshing) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC7103)),
        ),
      );
    }

    if (errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFEC7103),
        backgroundColor: Colors.white,
        strokeWidth: 2.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC7103),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      localizations.retry,
                      style: const TextStyle(fontFamily: 'Roboto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFEC7103),
        backgroundColor: Colors.white,
        strokeWidth: 2.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noNotifications,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFFEC7103),
      backgroundColor: Colors.white,
      strokeWidth: 2.0,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: const Color(0xFFE5E5E5),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return NotificationTile(
            item: item,
            onTap: () => _openNotificationDetail(item),
          );
        },
      ),
    );
  }
}

// Updated NotificationItem class with Greek text decoder
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.isRead,
  });
  factory NotificationItem.fromApi(
    Map<String, dynamic> json,
    Function(dynamic) decoder,
  ) {
    // API se read status properly parse karo
    bool isReadStatus = false;

    // Multiple ways to check read status
    if (json.containsKey('ACTSTATUS')) {
      final status = json['ACTSTATUS']?.toString();
      isReadStatus = status == '3' || status == 'read' || status == '1';
    } else if (json.containsKey('isRead')) {
      isReadStatus =
          json['isRead'] == true ||
          json['isRead'] == 1 ||
          json['isRead'] == '1';
    } else if (json.containsKey('read_status')) {
      isReadStatus = json['read_status'] == true || json['read_status'] == 1;
    }

    if (kDebugMode) {
      print(
        'Notification ${json['id']}: isRead = $isReadStatus, raw status = ${json['ACTSTATUS']}',
      );
    }

    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: decoder(json['title']),
      message: decoder(json['bodymessage']),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      isRead: isReadStatus,
    );
  }

  String get formattedDateTime {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Rest of the notification detail screen and tile widgets remain the same...
class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  String _stripHtmlTags(String htmlString) {
    String stripped = htmlString.replaceAll(RegExp(r'<!DOCTYPE[^>]*>'), '');
    stripped = stripped.replaceAll(
      RegExp(r'<head>.*?</head>', dotAll: true),
      '',
    );
    stripped = stripped.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true),
      '',
    );
    stripped = stripped.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', dotAll: true),
      '',
    );

    stripped = stripped.replaceAll(RegExp(r'</tr>'), '\n');
    stripped = stripped.replaceAll(RegExp(r'</td>'), ' ');
    stripped = stripped.replaceAll(RegExp(r'</p>'), '\n\n');
    stripped = stripped.replaceAll(RegExp(r'</div>'), '\n');
    stripped = stripped.replaceAll(RegExp(r'<br[^>]*>'), '\n');

    stripped = stripped.replaceAll(RegExp(r'<[^>]*>'), '');

    stripped = stripped
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&hellip;', '...')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–');

    stripped = stripped
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'^\s+', multiLine: true), '')
        .trim();

    return stripped;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEC7103),
        foregroundColor: Colors.white,
        title: Text(
          localizations.notificationDetails,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getNotificationIcon(notification.title),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC7103).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Color(0xFFEC7103),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    notification.formattedDateTime,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFEC7103),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification.timeAgo,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.message,
                        color: Color(0xFFEC7103),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.messageDetails,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEC7103),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: notification.message.isNotEmpty
                        ? Html(
                            data: notification.message,
                            style: {
                              "body": Style(
                                fontSize: FontSize(16),
                                color: Colors.black87,
                              ),
                              ".btn": Style(
                                display: Display.inlineBlock,
                                backgroundColor: Colors.red,
                                color: Colors.white,
                                padding: HtmlPaddings.symmetric(
                                  vertical: 22,
                                  horizontal: 35,
                                ),
                                fontSize: FontSize(14),
                                fontWeight: FontWeight.bold,
                                textAlign: TextAlign.center,
                                border: Border.all(color: Colors.red, width: 1),
                              ),
                            },
                            onLinkTap: (url, _, __) {
                              if (url != null) {
                                _openLink(url);
                              }
                            },
                          )
                        : Text(
                            localizations.noMessageContentAvailable,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.6,
                              fontFamily: 'NotoSans',
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    notification.isRead
                        ? Icons.mark_email_read
                        : Icons.mark_email_unread,
                    color: notification.isRead ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    notification.isRead
                        ? localizations.read
                        : localizations.unread,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: notification.isRead ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('points') ||
        lowerTitle.contains('redeem') ||
        lowerTitle.contains('reward')) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEC7103).withOpacity(0.2),
              const Color(0xFFFF8A3D).withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.card_giftcard, color: Color(0xFFEC7103), size: 28),
        ),
      );
    } else if (lowerTitle.contains('newsletter') ||
        lowerTitle.contains('mail')) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEC7103).withOpacity(0.2),
              const Color(0xFFFF8A3D).withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.mail_outline, color: Color(0xFFEC7103), size: 28),
        ),
      );
    } else if (lowerTitle.contains('welcome') || lowerTitle.contains('hello')) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEC7103).withOpacity(0.2),
              const Color(0xFFFF8A3D).withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.emoji_emotions, color: Color(0xFFEC7103), size: 28),
        ),
      );
    } else if (lowerTitle.contains('offer') ||
        lowerTitle.contains('deal') ||
        lowerTitle.contains('discount')) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEC7103).withOpacity(0.2),
              const Color(0xFFFF8A3D).withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.local_offer, color: Color(0xFFEC7103), size: 28),
        ),
      );
    } else if (lowerTitle.contains('meeting') || lowerTitle.contains('demo')) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEC7103).withOpacity(0.2),
              const Color(0xFFFF8A3D).withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.event, color: Color(0xFFEC7103), size: 28),
        ),
      );
    } else {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEC7103).withOpacity(0.2),
              const Color(0xFFFF8A3D).withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.notifications, color: Color(0xFFEC7103), size: 28),
        ),
      );
    }
  }

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.item, this.onTap});

  bool _isHtml(String text) {
    final htmlPattern = RegExp(
      r'<[^>]*>',
      multiLine: true,
      caseSensitive: false,
    );
    return htmlPattern.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.isRead
          ? Colors.white
          : const Color(0xFFEC7103).withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                margin: EdgeInsets.only(left: item.isRead ? 20 : 0),
                child: _getNotificationIcon(item.title),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: item.isRead ? Colors.black87 : Colors.black,
                      ),
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _isHtml(item.message) ? "Click here" : item.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF999999),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedDateTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.timeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFFEC7103),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('points') ||
        lowerTitle.contains('redeem') ||
        lowerTitle.contains('reward')) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.card_giftcard, color: Color(0xFFEC7103), size: 24),
        ),
      );
    } else if (lowerTitle.contains('newsletter') ||
        lowerTitle.contains('mail')) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.mail_outline, color: Color(0xFFEC7103), size: 24),
        ),
      );
    } else if (lowerTitle.contains('welcome') || lowerTitle.contains('hello')) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.emoji_emotions, color: Color(0xFFEC7103), size: 24),
        ),
      );
    } else if (lowerTitle.contains('offer') ||
        lowerTitle.contains('deal') ||
        lowerTitle.contains('discount')) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.local_offer, color: Color(0xFFEC7103), size: 24),
        ),
      );
    } else if (lowerTitle.contains('meeting') || lowerTitle.contains('demo')) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.event, color: Color(0xFFEC7103), size: 24),
        ),
      );
    } else {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.notifications, color: Color(0xFFEC7103), size: 24),
        ),
      );
    }
  }
}
