import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:charset_converter/charset_converter.dart';
import 'package:http/http.dart' as http;

/// Main function to decode Greek response bytes
Future<String> decodeGreekResponseBytes(List<int> bytes) async {
  try {
    // Web ke liye simple UTF8 decode
    if (kIsWeb) {
      return utf8.decode(bytes, allowMalformed: true);
    }

    // Step 1: UTF-8 decode
    final utf8Text = utf8.decode(bytes, allowMalformed: true);

    if (utf8Text.contains('ό') || utf8Text.contains('Ω') || utf8Text.contains('ά')) {
      return utf8Text;
    }

    // Step 2: Fallback ISO-8859-7 for Android/iOS
    final isoText = await CharsetConverter.decode('iso-8859-7', Uint8List.fromList(bytes));
    return isoText;
  } catch (e) {
    print('Decoding error: $e');
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// Enhanced Greek text decoder - handles multiple encoding scenarios
String decodeGreekText(dynamic value) {
  if (value == null) return '';

  String text = value.toString().trim();
  if (text.isEmpty) return '';

  try {
    // Method 1: Check if text contains Greek Unicode characters
    if (_containsGreekUnicode(text)) {
      return text;
    }

    // Method 2: Handle Windows-1253 to UTF-8 conversion
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
    return text;
  }
}

/// Check if text contains properly encoded Greek Unicode characters
bool _containsGreekUnicode(String text) {
  // Greek Unicode range: U+0370–U+03FF and U+1F00–U+1FFF
  return text.runes.any(
    (rune) => (rune >= 0x0370 && rune <= 0x03FF) || (rune >= 0x1F00 && rune <= 0x1FFF),
  );
}

/// Enhanced Windows-1253 detection
bool _isWindows1253Encoded(String text) {
  final windows1253Patterns = [
    'Áí', 'ìï', 'êÝ', 'ðñ', 'óå', 'ôá', 'êá', 'Üò', 'íô', 'Þò',
    'ýø', 'ôå', 'ñÝ', 'óö', 'ïñ', 'ëë', 'õí', 'éê', 'ðþ', 'íõ',
  ];

  return windows1253Patterns.any((pattern) => text.contains(pattern)) ||
      text.codeUnits.any((unit) => unit >= 0xC0 && unit <= 0xFF);
}

/// Enhanced Windows-1253 to Greek Unicode conversion
String _convertWindows1253ToUtf8(String text) {
  final Map<int, String> windows1253ToGreek = {
    // Greek uppercase letters (0xC1-0xD9)
    0xC1: 'Α', 0xC2: 'Β', 0xC3: 'Γ', 0xC4: 'Δ', 0xC5: 'Ε', 0xC6: 'Ζ',
    0xC7: 'Η', 0xC8: 'Θ', 0xC9: 'Ι', 0xCA: 'Κ', 0xCB: 'Λ', 0xCC: 'Μ',
    0xCD: 'Ν', 0xCE: 'Ξ', 0xCF: 'Ο', 0xD0: 'Π', 0xD1: 'Ρ', 0xD3: 'Σ',
    0xD4: 'Τ', 0xD5: 'Υ', 0xD6: 'Φ', 0xD7: 'Χ', 0xD8: 'Ψ', 0xD9: 'Ω',

    // Greek lowercase letters (0xE1-0xF9)
    0xE1: 'α', 0xE2: 'β', 0xE3: 'γ', 0xE4: 'δ', 0xE5: 'ε', 0xE6: 'ζ',
    0xE7: 'η', 0xE8: 'θ', 0xE9: 'ι', 0xEA: 'κ', 0xEB: 'λ', 0xEC: 'μ',
    0xED: 'ν', 0xEE: 'ξ', 0xEF: 'ο', 0xF0: 'π', 0xF1: 'ρ', 0xF2: 'ς',
    0xF3: 'σ', 0xF4: 'τ', 0xF5: 'υ', 0xF6: 'φ', 0xF7: 'χ', 0xF8: 'ψ',
    0xF9: 'ω',

    // Greek accented characters
    0xAA: 'Ί', 0xBA: 'Ό', 0xDA: 'Ύ', 0xDB: 'Ώ', 0xDC: 'ά', 0xDD: 'έ',
    0xDE: 'ή', 0xDF: 'ί', 0xE0: 'ό', 0xFC: 'ύ', 0xFD: 'ώ', 0xFB: 'ή',
    0xFA: 'ί', 0xB6: 'Ά', 0xB8: 'Έ', 0xB9: 'Ή', 0xBC: 'Ό', 0xBE: 'Ύ',
    0xBF: 'Ώ', 0xFE: 'ώ',
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
      } else {
        // Handle accented characters
        final accentMap = {
          0xB6: 'Ά', 0xB8: 'Έ', 0xB9: 'Ή', 0xBC: 'Ό', 0xBE: 'Ύ', 0xBF: 'Ώ',
          0xDC: 'ά', 0xDD: 'έ', 0xDE: 'ή', 0xDF: 'ί', 0xFC: 'ό', 0xFD: 'ύ',
          0xFE: 'ώ',
        };
        result += accentMap[byte] ?? String.fromCharCode(byte);
      }
    }

    return result;
  } catch (e) {
    if (kDebugMode) print('Byte conversion failed: $e');
    return text;
  }
}

/// Check if text is ISO-8859-7 encoded
bool _isIso88597Encoded(String text) {
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
    final bytes = Uint8List.fromList(text.codeUnits);
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
      return match.group(0)!;
    }
  });
}

/// Enhanced API response decoder for Greek content
Future<String> decodeApiResponse(http.Response response) async {
  if (kDebugMode) {
    print('Raw bytes: ${response.bodyBytes}');
    print('As UTF8: ${utf8.decode(response.bodyBytes, allowMalformed: true)}');
  }

  try {
    // Method 1: Check content-type header for charset
    String? contentType = response.headers['content-type'];
    if (contentType != null) {
      if (contentType.contains('charset=windows-1253')) {
        return _convertWindows1253ToUtf8(String.fromCharCodes(response.bodyBytes));
      } else if (contentType.contains('charset=iso-8859-7')) {
        return await _convertIso88597ToUtf8(String.fromCharCodes(response.bodyBytes));
      }
    }

    // Method 2: Try UTF-8 decoding first
    try {
      String responseBody = utf8.decode(response.bodyBytes);
      if (_containsGreekUnicode(responseBody) || !_containsLatinExtended(responseBody)) {
        return responseBody;
      }
    } catch (e) {
      if (kDebugMode) print('UTF-8 decoding failed: $e');
    }

    // Method 3: Try Latin-1 then convert to UTF-8
    try {
      String latin1Decoded = latin1.decode(response.bodyBytes);
      String converted = decodeGreekText(latin1Decoded);
      if (_containsGreekUnicode(converted)) {
        return converted;
      }
    } catch (e) {
      if (kDebugMode) print('Latin-1 decoding failed: $e');
    }

    // Method 4: Fallback to response.body
    return decodeGreekText(response.body);
  } catch (e) {
    if (kDebugMode) print('All decoding methods failed: $e');
    return response.body;
  }
}
// is ko theek kar ke de do 

// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:charset_converter/charset_converter.dart';
// import 'dart:async';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:loyalty_app/Services/language_service.dart';
// import 'package:loyalty_app/Auth/LanguageSelectionPage.dart';
// import 'package:loyalty_app/utils/api_constants.dart';
// import 'package:loyalty_app/utils/language_decoder.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_html/flutter_html.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:charset_converter/charset_converter.dart';

// Future<String> decodeGreekResponseBytes(List<int> bytes) async {
//   try {
//     // Web ke liye simple UTF8 decode hi karo
//     if (kIsWeb) {
//       return utf8.decode(bytes, allowMalformed: true);
//     }

//     // Step 1: UTF-8 decode
//     final utf8Text = utf8.decode(bytes, allowMalformed: true);

//     if (utf8Text.contains('ό') || utf8Text.contains('Ω') || utf8Text.contains('ά')) {
//       return utf8Text;
//     }

//     // Step 2: Fallback ISO-8859-7 for Android/iOS
//     final isoText = await CharsetConverter.decode('iso-8859-7', Uint8List.fromList(bytes));
//     return isoText;
//   } catch (e) {
//     print('Decoding error: $e');
//     return utf8.decode(bytes, allowMalformed: true);
//   }
// }

// // lanuage function above
// // lanuage function above
// // lanuage function above
//   /// Enhanced Greek text decoder - handles multiple encoding scenarios
//   String _decodeGreekText(dynamic value) {
//     if (value == null) return '';

//     String text = value.toString().trim();
//     if (text.isEmpty) return '';

//     try {
//       // Method 1: Check if text contains Greek Unicode characters (properly encoded)
//       if (_containsGreekUnicode(text)) {
//         return text; // Already properly encoded
//       }

//       // Method 2: Handle Windows-1253 to UTF-8 conversion (most common case)
//       if (_isWindows1253Encoded(text)) {
//         return _convertWindows1253ToUtf8(text);
//       }

//       // Method 3: Try byte-level Windows-1253 conversion
//       String converted = _convertBytesToGreek(text);
//       if (_containsGreekUnicode(converted)) {
//         return converted;
//       }

//       // Method 4: Handle HTML entities and numeric character references
//       text = _decodeHtmlEntities(text);
//       text = _decodeNumericEntities(text);

//       return text;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Greek text decoding error: $e');
//         print('Original text: $text');
//       }
//       return text; // Return original if all methods fail
//     }
//   }
// // lanuage encof=dinge here
//   /// Enhanced Windows-1253 detection
//   bool _isWindows1253Encoded(String text) {
//     // Check for common Windows-1253 Greek character patterns
//     final windows1253Patterns = [
//       'Áí',
//       'ìï',
//       'êÝ',
//       'ðñ',
//       'óå',
//       'ôá',
//       'êá',
//       'Üò',
//       'íô',
//       'Þò',
//       'ýø',
//       'ôå',
//       'ñÝ',
//       'óö',
//       'ïñ',
//       'ëë',
//       'õí',
//       'éê',
//       'ðþ',
//       'íõ',
//     ];

//     return windows1253Patterns.any((pattern) => text.contains(pattern)) ||
//         text.codeUnits.any((unit) => unit >= 0xC0 && unit <= 0xFF);
//   }

//   /// Enhanced Windows-1253 to Greek Unicode conversion
//   String _convertWindows1253ToUtf8(String text) {
//     // Complete Windows-1253 to Greek Unicode mapping table
//     final Map<int, String> windows1253ToGreek = {
//       // Greek uppercase letters (0xC1-0xD9)
//       0xC1: 'Α',
//       0xC2: 'Β',
//       0xC3: 'Γ',
//       0xC4: 'Δ',
//       0xC5: 'Ε',
//       0xC6: 'Ζ',
//       0xC7: 'Η',
//       0xC8: 'Θ',
//       0xC9: 'Ι',
//       0xCA: 'Κ',
//       0xCB: 'Λ',
//       0xCC: 'Μ',
//       0xCD: 'Ν',
//       0xCE: 'Ξ',
//       0xCF: 'Ο',
//       0xD0: 'Π',
//       0xD1: 'Ρ',
//       0xD3: 'Σ',
//       0xD4: 'Τ',
//       0xD5: 'Υ',
//       0xD6: 'Φ',
//       0xD7: 'Χ',
//       0xD8: 'Ψ',
//       0xD9: 'Ω',

//       // Greek lowercase letters (0xE1-0xF9)
//       0xE1: 'α',
//       0xE2: 'β',
//       0xE3: 'γ',
//       0xE4: 'δ',
//       0xE5: 'ε',
//       0xE6: 'ζ',
//       0xE7: 'η',
//       0xE8: 'θ',
//       0xE9: 'ι',
//       0xEA: 'κ',
//       0xEB: 'λ',
//       0xEC: 'μ',
//       0xED: 'ν',
//       0xEE: 'ξ',
//       0xEF: 'ο',
//       0xF0: 'π',
//       0xF1: 'ρ',
//       0xF2: 'ς',
//       0xF3: 'σ',
//       0xF4: 'τ',
//       0xF5: 'υ',
//       0xF6: 'φ',
//       0xF7: 'χ',
//       0xF8: 'ψ',
//       0xF9: 'ω',

//       // Greek accented characters
//       0xAA: 'Ί', 0xBA: 'Ό', 0xDA: 'Ύ', 0xDB: 'Ώ', 0xDC: 'ΐ', 0xDD: 'ΰ',
//       0xFD: 'ύ', 0xFC: 'ό', 0xFE: 'ώ', 0xFB: 'ή', 0xFA: 'ί', 0xDF: 'ϊ',

//       // Additional accented vowels
//       0xB6: 'Ά', 0xB8: 'Έ', 0xB9: 'Ή', 0xBC: 'Ό', 0xBE: 'Ύ', 0xBF: 'Ώ',
//       0xDC: 'ά',
//       0xDD: 'έ',
//       0xDE: 'ή',
//       0xDF: 'ί',
//       0xE0: 'ό',
//       0xFC: 'ύ',
//       0xFD: 'ώ',
//     };

//     String converted = '';
//     for (int i = 0; i < text.length; i++) {
//       int charCode = text.codeUnitAt(i);
//       if (windows1253ToGreek.containsKey(charCode)) {
//         converted += windows1253ToGreek[charCode]!;
//       } else {
//         converted += text[i];
//       }
//     }

//     return converted;
//   }

//   /// Byte-level conversion for stubborn encoding issues
//   String _convertBytesToGreek(String text) {
//     try {
//       List<int> bytes = text.codeUnits;
//       String result = '';

//       for (int byte in bytes) {
//         // Windows-1253 Greek range conversion
//         if (byte >= 0xC1 && byte <= 0xD9) {
//           // Uppercase Greek letters
//           int greekCode = 0x0391 + (byte - 0xC1);
//           if (byte == 0xD2) greekCode = 0x03A3; // Sigma special case
//           result += String.fromCharCode(greekCode);
//         } else if (byte >= 0xE1 && byte <= 0xF9) {
//           // Lowercase Greek letters
//           int greekCode = 0x03B1 + (byte - 0xE1);
//           if (byte == 0xF2) greekCode = 0x03C2; // Final sigma
//           result += String.fromCharCode(greekCode);
//         } else if (byte == 0xB6) {
//           result += 'Ά'; // Alpha with tonos
//         } else if (byte == 0xB8) {
//           result += 'Έ'; // Epsilon with tonos
//         } else if (byte == 0xB9) {
//           result += 'Ή'; // Eta with tonos
//         } else if (byte == 0xBC) {
//           result += 'Ό'; // Omicron with tonos
//         } else if (byte == 0xBE) {
//           result += 'Ύ'; // Upsilon with tonos
//         } else if (byte == 0xBF) {
//           result += 'Ώ'; // Omega with tonos
//         } else if (byte == 0xDC) {
//           result += 'ά'; // alpha with tonos
//         } else if (byte == 0xDD) {
//           result += 'έ'; // epsilon with tonos
//         } else if (byte == 0xDE) {
//           result += 'ή'; // eta with tonos
//         } else if (byte == 0xDF) {
//           result += 'ί'; // iota with tonos
//         } else if (byte == 0xFC) {
//           result += 'ό'; // omicron with tonos
//         } else if (byte == 0xFD) {
//           result += 'ύ'; // upsilon with tonos
//         } else if (byte == 0xFE) {
//           result += 'ώ'; // omega with tonos
//         } else {
//           result += String.fromCharCode(byte);
//         }
//       }

//       return result;
//     } catch (e) {
//       if (kDebugMode) print('Byte conversion failed: $e');
//       return text;
//     }
//   }

//   @override
//   void dispose() {
//     _autoMarkReadTimer?.cancel();
//     super.dispose();
//   }

//   /// Enhanced Greek text decoder - handles multiple encoding scenarios
//   ///
//   ///
//   /// Check if text contains properly encoded Greek Unicode characters
//   bool _containsGreekUnicode(String text) {
//     // Greek Unicode range: U+0370–U+03FF and U+1F00–U+1FFF
//     return text.runes.any(
//       (rune) =>
//           (rune >= 0x0370 && rune <= 0x03FF) ||
//           (rune >= 0x1F00 && rune <= 0x1FFF),
//     );
//   }

//   /// Check if text is Windows-1253 encoded (common Greek encoding)
//   // bool _isWindows1253Encoded(String text) {
//   //   // Windows-1253 specific characters that map to Greek
//   //   final windows1253Indicators = [
//   //     'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï',
//   //     'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï',
//   //     'ð', 'ñ', 'ò', 'ó', 'ô', 'õ', 'ö', '÷', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'þ'
//   //   ];

//   //   return windows1253Indicators.any((char) => text.contains(char));
//   // }

//   // /// Convert Windows-1253 encoded text to UTF-8
//   // String _convertWindows1253ToUtf8(String text) {
//   //   // Windows-1253 to Greek Unicode mapping
//   //   final Map<String, String> windows1253ToGreek = {
//   //     // Uppercase Greek letters
//   //     'Á': 'Α', 'Â': 'Β', 'Ã': 'Γ', 'Ä': 'Δ', 'Å': 'Ε', 'Æ': 'Ζ', 'Ç': 'Η', 'È': 'Θ',
//   //     'É': 'Ι', 'Ê': 'Κ', 'Ë': 'Λ', 'Ì': 'Μ', 'Í': 'Ν', 'Î': 'Ξ', 'Ï': 'Ο', 'Ð': 'Π',
//   //     'Ñ': 'Ρ', 'Ó': 'Σ', 'Ô': 'Τ', 'Õ': 'Υ', 'Ö': 'Φ', '×': 'Χ', 'Ø': 'Ψ', 'Ù': 'Ω',

//   //     // Lowercase Greek letters
//   //     'á': 'α', 'â': 'β', 'ã': 'γ', 'ä': 'δ', 'å': 'ε', 'æ': 'ζ', 'ç': 'η', 'è': 'θ',
//   //     'é': 'ι', 'ê': 'κ', 'ë': 'λ', 'ì': 'μ', 'í': 'ν', 'î': 'ξ', 'ï': 'ο', 'ð': 'π',
//   //     'ñ': 'ρ', 'ò': 'ς', 'ó': 'σ', 'ô': 'τ', 'õ': 'υ', 'ö': 'φ', '÷': 'χ', 'ø': 'ψ', 'ù': 'ω',

//   //     // Greek accented characters
//   //     'Ú': 'Ί', 'Û': 'Ό', 'Ü': 'Ύ', 'Ý': 'Ώ', 'Þ': 'ΐ', 'ß': 'ΰ',
//   //     'ú': 'ύ', 'û': 'ό', 'ü': 'ώ', 'ý': 'ή', 'þ': 'ί', 'ÿ': 'ϊ'
//   //   };

//   //   String converted = text;
//   //   windows1253ToGreek.forEach((key, value) {
//   //     converted = converted.replaceAll(key, value);
//   //   });

//   //   return converted;
//   // }

//   /// Check if text is ISO-8859-7 encoded
//   bool _isIso88597Encoded(String text) {
//     // ISO-8859-7 has specific byte patterns for Greek
//     try {
//       List<int> bytes = text.codeUnits;
//       return bytes.any((byte) => byte >= 0xB6 && byte <= 0xFF);
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Convert ISO-8859-7 to UTF-8
//   Future<String> _convertIso88597ToUtf8(String text) async {
//     try {
//       // Convert List<int> → Uint8List
//       final bytes = Uint8List.fromList(text.codeUnits);

//       // Decode from ISO-8859-7 to UTF-8
//       return await CharsetConverter.decode('iso-8859-7', bytes);
//     } catch (e) {
//       if (kDebugMode) print('ISO-8859-7 conversion failed: $e');
//       return text;
//     }
//   }

//   /// Check if text contains Latin extended characters
//   bool _containsLatinExtended(String text) {
//     return text.codeUnits.any((unit) => unit > 127 && unit < 256);
//   }

//   /// Decode HTML entities
//   String _decodeHtmlEntities(String text) {
//     return text
//         .replaceAll('&amp;', '&')
//         .replaceAll('&lt;', '<')
//         .replaceAll('&gt;', '>')
//         .replaceAll('&quot;', '"')
//         .replaceAll('&#39;', "'")
//         .replaceAll('&nbsp;', ' ')
//         .replaceAll('&hellip;', '…')
//         .replaceAll('&mdash;', '—')
//         .replaceAll('&ndash;', '–')
//         .replaceAll('&copy;', '©')
//         .replaceAll('&reg;', '®')
//         .replaceAll('&trade;', '™');
//   }

//   /// Decode numeric character references (&#xxx; format)
//   String _decodeNumericEntities(String text) {
//     return text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
//       try {
//         int charCode = int.parse(match.group(1)!);
//         return String.fromCharCode(charCode);
//       } catch (e) {
//         return match.group(0)!; // Return original if conversion fails
//       }
//     });
//   }

//   /// Enhanced API response decoder for Greek content
//   Future<String> _decodeApiResponse(http.Response response) async {
//     String responseBody;
// print('Raw bytes: ${response.bodyBytes}');
// print('As UTF8: ${utf8.decode(response.bodyBytes, allowMalformed: true)}');

//     try {
//       // Method 1: Check if response has charset info in headers
//       String? contentType = response.headers['content-type'];
//       if (contentType != null) {
//         if (contentType.contains('charset=windows-1253')) {
//           // Decode as Windows-1253
//           responseBody = _convertWindows1253ToUtf8(
//             String.fromCharCodes(response.bodyBytes),
//           );
//           return responseBody;
//         } else if (contentType.contains('charset=iso-8859-7')) {
//           // Decode as ISO-8859-7
//           responseBody = await _convertIso88597ToUtf8(
//             String.fromCharCodes(response.bodyBytes),
//           );
//           return responseBody;
//         }
//       }

//       // Method 2: Try UTF-8 decoding first
//       try {
//         responseBody = utf8.decode(response.bodyBytes);
//         if (_containsGreekUnicode(responseBody) ||
//             !_containsLatinExtended(responseBody)) {
//           return responseBody;
//         }
//       } catch (e) {
//         if (kDebugMode) print('UTF-8 decoding failed: $e');
//       }

//       // Method 3: Try Latin-1 then convert to UTF-8
//       try {
//         String latin1Decoded = latin1.decode(response.bodyBytes);
//         responseBody = _decodeGreekText(latin1Decoded);
//         if (_containsGreekUnicode(responseBody)) {
//           return responseBody;
//         }
//       } catch (e) {
//         if (kDebugMode) print('Latin-1 decoding failed: $e');
//       }

//       // Method 4: Fallback to response.body
//       responseBody = response.body;
//       responseBody = _decodeGreekText(responseBody);

//       return responseBody;
//     } catch (e) {
//       if (kDebugMode) {
//         print('All decoding methods failed: $e');
//       }
//       return response.body; // Ultimate fallback
//     }
//   }

//   // Replace your _decodeApiResponse method with this async version:
//   Future<String> _decodeApiResponseAsync(http.Response response) async {
//     try {
//       // Check content type first
//       String? contentType = response.headers['content-type'];

//       if (contentType != null) {
//         if (contentType.contains('charset=windows-1253')) {
//           return _convertWindows1253ToUtf8(
//             String.fromCharCodes(response.bodyBytes),
//           );
//         } else if (contentType.contains('charset=iso-8859-7')) {
//           return await _convertIso88597ToUtf8(
//             String.fromCharCodes(response.bodyBytes),
//           );
//         }
//       }

//       // Try UTF-8 first
//       try {
//         String responseBody = utf8.decode(response.bodyBytes);
//         if (_containsGreekUnicode(responseBody) ||
//             !_containsLatinExtended(responseBody)) {
//           return responseBody;
//         }
//       } catch (e) {
//         debugPrint('UTF-8 decoding failed: $e');
//       }

//       // Fallback to Latin-1 then convert
//       try {
//         String latin1Decoded = latin1.decode(response.bodyBytes);
//         String converted = _decodeGreekText(latin1Decoded);
//         if (_containsGreekUnicode(converted)) {
//           return converted;
//         }
//       } catch (e) {
//         debugPrint('Latin-1 decoding failed: $e');
//       }

//       // Ultimate fallback
//       return _decodeGreekText(response.body);
//     } catch (e) {
//       return response.body;
//     }
//   }
