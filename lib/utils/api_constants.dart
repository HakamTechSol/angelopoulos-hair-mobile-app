// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ApiConstants {
//   static String? _baseUrl;

//   static Future<void> loadBaseUrl() async {
//     final prefs = await SharedPreferences.getInstance();
//     // _baseUrl = prefs.getString('api_base_url') ?? "https://localhost:7089/api";
//     // _baseUrl = prefs.getString('api_base_url') ?? "webapp.xit.gr/service";
//     _baseUrl = prefs.getString('api_base_url') ?? "https://cors-anywhere.herokuapp.com/";
//     // live karte wat ye lagana he
//     // _baseUrl = prefs.getString('api_base_url') ?? "";
//   }
// // https://cors-anywhere.herokuapp.com/
//   static String get baseUrl => _baseUrl ?? "https://cors-anywhere.herokuapp.com/";
//       // live karte wat ye lagana he
//   // static String get baseUrl => _baseUrl ?? "";

//   // static String get baseUrl => _baseUrl ?? "webapp.xit.gr/service";
//   //https://webapp.xit.gr/service/license
//   // static String get baseUrl => _baseUrl ?? "https://localhost:7089/api";

//   static Future<void> setBaseUrl(String url) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('api_base_url', url);
//     _baseUrl = url;
//   }
// }

// class ApireelConstants {
//   static String? _baseUrl;

//   static Future<void> loadBaseUrl() async {
//     final prefs = await SharedPreferences.getInstance();
//     // _baseUrl = prefs.getString('api_reel_url') ?? "https://localhost:7089";
//     // _baseUrl = prefs.getString('api_reel_url') ?? "https://webapp.xit.gr/service/";
//     _baseUrl = prefs.getString('api_reel_url') ?? "https://cors-anywhere.herokuapp.com/";
//         // live karte wat ye lagana he

//     // _baseUrl = prefs.getString('api_reel_url') ?? "";
//   }

//   // static String get baseUrl => _baseUrl ?? "https://localhost:7089";
  
//   static String get baseUrl => _baseUrl ?? "https://cors-anywhere.herokuapp.com/";
//       // live karte wat ye lagana he

//   // static String get baseUrl => _baseUrl ?? "";

//   // static String get baseUrl => _baseUrl ?? "https://webapp.xit.gr/service/";

//   static Future<void> setBaseUrl(String url) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('api_reel_url', url);
//     _baseUrl = url;
//   }
// }

// class ApiUrlSettingsScreen extends StatefulWidget {
//   const ApiUrlSettingsScreen({super.key});

//   @override
//   State<ApiUrlSettingsScreen> createState() => _ApiUrlSettingsScreenState();
// }

// class _ApiUrlSettingsScreenState extends State<ApiUrlSettingsScreen> {
//   late TextEditingController _mainApiController;
//   late TextEditingController _reelApiController;

//   @override
//   void initState() {
//     super.initState();
//     _mainApiController = TextEditingController(text: ApiConstants.baseUrl);
//     _reelApiController = TextEditingController(text: ApireelConstants.baseUrl);
//   }

//   void _saveUrls() async {
//     String mainUrl = _mainApiController.text.trim();
//     String reelUrl = _reelApiController.text.trim();

//     if (!mainUrl.startsWith("http") || !reelUrl.startsWith("http")) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Invalid URL(s). Must start with http")),
//       );
//       return;
//     }

//     await ApiConstants.setBaseUrl(mainUrl);
//     await ApireelConstants.setBaseUrl(reelUrl);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('API URLs saved successfully!')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("API URL Settings")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             const Text("Main API URL:", style: TextStyle(fontSize: 16)),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _mainApiController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter Main API URL',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("Reel API URL:", style: TextStyle(fontSize: 16)),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _reelApiController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter Reel API URL',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: _saveUrls,
//               child: const Text("Save URLs"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// // }
// class ApiConstants {
//   static const String baseUrl =
//       // "https://cors-anywhere.herokuapp.com/"; // Replace with your API base URL
//       ""; 
// }

import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return "https://cors-anywhere.herokuapp.com/";
    } else if (Platform.isAndroid) {
      return "";
    } else if (Platform.isIOS) {
      return "";
    } else {
      return "";
    }
  }
}
//https://xitdevelop.oncloud.gr/s1services   porana ya tha
// https://angelopouloshair.oncloud.gr/s1services?  ye new hw 