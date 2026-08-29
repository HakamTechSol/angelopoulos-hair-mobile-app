import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loyalty_app/Auth/LanguageSelectionPage.dart';
import 'package:loyalty_app/Auth/SignIn.dart';
import 'package:loyalty_app/Services/language_service.dart';
import 'package:loyalty_app/utils/api_constants.dart';
import 'package:loyalty_app/utils/language_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:charset_converter/charset_converter.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String fullName = "Loading...";
  String phone = "Loading...";
  String password = "••••••••••••";
  String email = "Loading...";
  String createdAt = "Loading...";
  String totalPoints = "0";
  String redeemedPoints = "0";
  String address = "Loading...";
  String city = "Loading...";
  String zip = "Loading...";
  String trdr = "";
  String clientID = "";
  bool isLoading = true;
  String? profileImagePath;
  int _selectedIndex = 4;
  final ImagePicker _picker = ImagePicker();
  String? profileImageBase64;
  Uint8List? profileImageBytes;
  String fcmToken = "Loading...";
  bool isDeletingAccount = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadProfileImageFromBase64();
        _getVersion(); // ✅ Version function call karo

  }

  // ✅ Version get karne ka function
  Future<void> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = "${packageInfo.version}.${packageInfo.buildNumber}";
      // Agar sirf version chahiye bina build number ke:
      // _appVersion = packageInfo.version;
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load user data after dependencies are resolved
    if (mounted) {
      _loadUserData();
    }
  }

  Future<void> _loadProfileImageFromBase64() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final base64Image = prefs.getString('profile_image_base64');

      if (base64Image != null && base64Image.isNotEmpty) {
        if (base64Image.length < 100) {
          debugPrint("⚠️ Base64 string seems too short, might be corrupted");
          await prefs.remove('profile_image_base64');
          return;
        }

        Uint8List imageBytes = base64Decode(base64Image);

        if (mounted) {
          setState(() {
            profileImageBase64 = base64Image;
            profileImageBytes = imageBytes;
          });
        }

        debugPrint(
          "📥 Profile image loaded successfully from base64 (${(imageBytes.length / 1024).round()}KB)",
        );
      } else {
        debugPrint("ℹ️ No profile image found in storage");
      }
    } catch (e) {
      debugPrint("❌ Error loading base64 image: $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_base64');

      if (mounted) {
        setState(() {
          profileImageBase64 = null;
          profileImageBytes = null;
        });
      }
    }
  }

  Future<void> _saveProfileImageAsBase64(String imagePath) async {
    try {
      final file = File(imagePath);

      if (!await file.exists()) {
        throw Exception("Image file not found");
      }

      // Read file in chunks to avoid memory issues
      final bytes = await file.readAsBytes();

      if (bytes.length > 2 * 1024 * 1024) {
        throw Exception("Image size too large (max 2MB)");
      }

      // Encode in background to avoid UI freeze
      String base64Image = await compute(_encodeImageToBase64, bytes);

      if (base64Image.isEmpty) {
        throw Exception("Image encoding failed");
      }

      final prefs = await SharedPreferences.getInstance();
      bool saved = await prefs.setString('profile_image_base64', base64Image);

      if (!saved) {
        throw Exception("Failed to save image");
      }

      if (mounted) {
        setState(() {
          profileImageBase64 = base64Image;
          profileImageBytes = bytes;
        });
      }

      debugPrint(
        "✅ Profile image saved successfully as base64 (${(bytes.length / 1024).round()}KB)",
      );
    } catch (e) {
      debugPrint("❌ Error saving profile image: $e");
      rethrow;
    }
  }

  // Add this static method for background image encoding:
  static String _encodeImageToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  void _showImagePickerOptions() {
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                localizations.selectProfilePicture,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    icon: Icons.camera_alt,
                    label: localizations.camera,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildImagePickerOption(
                    icon: Icons.photo_library,
                    label: localizations.gallery,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  if (profileImageBase64 != null &&
                      profileImageBase64!.isNotEmpty)
                    _buildImagePickerOption(
                      icon: Icons.delete,
                      label: localizations.remove,
                      onTap: _removeProfileImage,
                      color: Colors.red,
                    ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? Colors.black).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color ?? Colors.black),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFEC7103)),
                  SizedBox(height: 16),
                  Text(localizations.processingImage),
                ],
              ),
            ),
          ),
        );

        await _saveProfileImageAsBase64(image.path);

        if (Navigator.canPop(context)) Navigator.pop(context);
        if (Navigator.canPop(context)) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(localizations.profilePictureUpdated),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showError('${localizations.failedUpdateProfile}: ${e.toString()}');
    }
  }

  Future<void> _removeProfileImage() async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_base64');

      setState(() {
        profileImageBase64 = null;
        profileImageBytes = null;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(localizations.profilePictureRemoved),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );

      debugPrint("🗑️ Profile image removed successfully");
    } catch (e) {
      Navigator.pop(context);
      _showError('${localizations.failedUpdateProfile}: ${e.toString()}');
    }
  }

  // Also fix the _loadUserData method to handle API profile image properly
  Future<void> _loadUserData() async {
    final localizations = AppLocalizations.of(context)!;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      trdr = prefs.getString('TRDR') ?? '';
      clientID = prefs.getString('clientID') ?? '';
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');

      if (trdr.isEmpty ||
          clientID.isEmpty ||
          companyUrl == null ||
          softwareType == null) {
        _showError(localizations.missingUserCredentials);
        return;
      }

      final servicePath = _getServicePath(softwareType);
      final uri = _buildApiUri(companyUrl, servicePath);

      // Add timeout to prevent hanging
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "service": "SqlData",
              "clientID": clientID,
              "appId": "1001",
              "SqlName": "9700",
              "trdr": int.parse(trdr),
            }),
          )
          .timeout(
            Duration(seconds: 10), // 10 second timeout
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        // Move heavy decoding to background isolate
        String responseBody = await decodeGreekResponseBytes(
          response.bodyBytes,
        );
        final data = jsonDecode(responseBody);

        if (data['success'] == true &&
            data['rows'] != null &&
            data['rows'].isNotEmpty) {
          final userInfo = data['rows'][0];

          // Process user data
          await _processUserData(userInfo, prefs, localizations);
        } else {
          _showError(localizations.failedLoadUserData);
          if (mounted) setState(() => isLoading = false);
        }
      } else {
        _showError('${localizations.serverError}: ${response.statusCode}');
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      _showError('${localizations.connectionError}: ${e.toString()}');
      if (mounted) setState(() => isLoading = false);
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

  // Add this new method to process user data asynchronously
  Future<void> _processUserData(
    Map<String, dynamic> userInfo,
    SharedPreferences prefs,
    AppLocalizations localizations,
  ) async {
    String name = userInfo['NAME']?.toString().isNotEmpty == true
        ? userInfo['NAME'].toString()
        : localizations.fullName;

    String userEmail = userInfo['EMAIL']?.toString().isNotEmpty == true
        ? userInfo['EMAIL'].toString()
        : 'email@domain.gr';

    String userPhone = userInfo['PHONE01']?.toString().isNotEmpty == true
        ? userInfo['PHONE01'].toString()
        : '+30 6912345678';

    String rawDate = userInfo['INSDATE']?.toString() ?? '';
    String formattedDate = 'DD/MM/YYYY';
    if (rawDate.isNotEmpty && rawDate.contains(' ')) {
      String datePart = rawDate.split(' ')[0];
      try {
        DateTime parsedDate = DateTime.parse(datePart);
        formattedDate =
            "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
      } catch (_) {
        formattedDate = datePart;
      }
    }

    String total = userInfo['totalpoints']?.toString() ?? '0';
    String redeemed = userInfo['redeemedpoints']?.toString() ?? '0';
    String userAddress = userInfo['ADDRESS']?.toString().isNotEmpty == true
        ? userInfo['ADDRESS'].toString()
        : localizations.address;
    String userCity = userInfo['CITY']?.toString().isNotEmpty == true
        ? userInfo['CITY'].toString()
        : localizations.city;
    String userZip = userInfo['ZIP']?.toString().isNotEmpty == true
        ? userInfo['ZIP'].toString()
        : localizations.zip;
    String profileImageUrl = userInfo['IMAGE']?.toString() ?? '';

    // Process API profile image in background
    String apiProfileImage = userInfo['CCCXITLIMAGE']?.toString() ?? '';
    if (apiProfileImage.isNotEmpty &&
        (profileImageBase64 == null || profileImageBase64!.isEmpty)) {
      // Don't block UI - process in background
      _processApiImageAsync(apiProfileImage, prefs);
    }

    // Save to preferences
    await Future.wait([
      prefs.setString('user_fullname', name),
      prefs.setString('user_email', userEmail),
      prefs.setString('user_phone', userPhone),
      prefs.setString('user_created_at', formattedDate),
      prefs.setString('user_total_points', total),
      prefs.setString('user_redeemed_points', redeemed),
      prefs.setString('user_address', userAddress),
      prefs.setString('user_city', userCity),
      prefs.setString('user_zip', userZip),
      prefs.setString('u_image', profileImageUrl),
    ]);
    print('user bname profil2 $fullName');
    print('user bname profil3 $name');

    if (mounted) {
      setState(() {
        fullName = name;
        email = userEmail;
        phone = userPhone;
        createdAt = formattedDate;
        totalPoints = total;
        redeemedPoints = redeemed;
        address = userAddress;
        city = userCity;
        zip = userZip;
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final localizations = AppLocalizations.of(context)!;

    bool shouldDelete =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(localizations.deleteAccount ?? "Delete Account",
                 style: TextStyle(fontSize: 15),),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.deleteAccountWarning ??
                      "Are you sure you want to delete your account?",
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    localizations.deleteAccountNote ??
                        "⚠️ This action cannot be undone. Your account will be permanently deleted.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  localizations.cancel,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  localizations.deleteAccount ?? "Delete Account",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    setState(() {
      isDeletingAccount = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');

      if (companyUrl == null || softwareType == null) {
        _showError(localizations.missingConfiguration);
        setState(() {
          isDeletingAccount = false;
        });
        return;
      }
      final servicePath = _getServicePath(softwareType);
      final uri = _buildApiUri(companyUrl, servicePath);

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "service": "setData",
              "clientID": clientID,
              "appId": "1001",
              "OBJECT": "CUSTOMER[FORM=WEB]",
              "KEY": trdr,
              "data": {
                "CUSTOMER": [
                  {"ISACTIVE": "0"},
                ],
              },
            }),
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        String responseBody = await decodeGreekResponseBytes(
          response.bodyBytes,
        );
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          // Clear all data
          await prefs.clear();
          Get.deleteAll(force: true);


          // Show success dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 22),
                  SizedBox(width: 5),
                  Text(
                    localizations.accountDeletionScheduled ??
                        "Account Deletion Scheduled",
                  
                   style: TextStyle(fontSize: 13),
                   ),
                ],
              ),
              content: Text(
                localizations.accountWillBeDeleted ??
                    "Your account will be permanently deleted in 7 days. You can cancel this by contacting support before the deletion date.",
                style: TextStyle(fontSize: 10),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEC7103),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.okay ?? "Okay",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );

          // Navigate to login screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        } else {
          _showError(
            '${localizations.failedDeleteAccount ?? "Failed to delete account"}: ${data['message'] ?? localizations.unknownError}',
          );
        }
      } else {
        _showError('${localizations.serverError}: ${response.statusCode}');
        setState(() {
          isDeletingAccount = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error deleting account: $e");
      _showError('${localizations.connectionError}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isDeletingAccount = false;
        });
      }
    }
  }

  // Add this method to process API image in background
  Future<void> _processApiImageAsync(
    String apiProfileImage,
    SharedPreferences prefs,
  ) async {
    try {
      // Clean the base64 string
      String cleanBase64 = apiProfileImage;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      // Validate length before decoding
      if (cleanBase64.length < 100) return;

      // Decode image in background
      Uint8List imageBytes = base64Decode(cleanBase64);

      // Save to local storage
      await prefs.setString('profile_image_base64', cleanBase64);

      // Update UI on main thread
      if (mounted) {
        setState(() {
          profileImageBase64 = cleanBase64;
          profileImageBytes = imageBytes;
        });
      }

      debugPrint(
        "✅ API profile image loaded successfully (${(imageBytes.length / 1024).round()}KB)",
      );
    } catch (e) {
      debugPrint("❌ Error loading API profile image: $e");
    }
  }

  String _getServicePath(String softwareType) {
    return softwareType == "TESAE"
        ? "/pegasus/a_xit/connector.php"
        : "/s1services";
  }

  Uri _buildApiUri(String companyUrl, String servicePath) {
    return Uri.parse("${ApiConstants.baseUrl}https://$companyUrl$servicePath");
  }

  // Update your _updateUserData method with timeout:
  Future<void> _updateUserData() async {
    final localizations = AppLocalizations.of(context)!;

    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');
      final fcmToken = prefs.getString('fcm_token');

      if (companyUrl == null || softwareType == null) {
        _showError(localizations.missingConfiguration);
        return;
      }

      final servicePath = _getServicePath(softwareType);
      final uri = _buildApiUri(companyUrl, servicePath);

      Map<String, dynamic> userData = {
        "CODE": phone,
        "NAME": fullName,
        "EMAIL": email,
        "PHONE01": phone,
        "ADDRESS": address,
        "CITY": city,
        "ZIP": zip,
        "CCCXITUSERNAME": "username",
        "CCCXITPASSWORD": password,
        "REMARKS": "Updated via app",
      };

      if (fcmToken != null && fcmToken.isNotEmpty) {
        userData["CCCXITFCMTOKEN"] = fcmToken;
      }

      if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
        String cleanBase64 = profileImageBase64!;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        userData["CCCXITLIMAGE"] = cleanBase64;
        debugPrint(
          "📤 Sending image to CCCXITLIMAGE field (${cleanBase64.length} chars)",
        );
      }

      // Add timeout to prevent hanging
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "service": "setData",
              "clientID": clientID,
              "appId": "1001",
              "OBJECT": "CUSTOMER[FORM=WEB]",
              "KEY": trdr,
              "data": {
                "CUSTOMER": [userData],
              },
            }),
          )
          .timeout(
            Duration(seconds: 15), // 15 second timeout
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      debugPrint("🌐 API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        String responseBody = await decodeGreekResponseBytes(
          response.bodyBytes,
        );
        final data = jsonDecode(responseBody);
        print('user bname profile4 $fullName');

        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(localizations.profileUpdatedSuccessfully),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _showError(
            '${localizations.failedUpdateProfile}: ${data['message'] ?? localizations.unknownError}',
          );
        }
      } else {
        _showError('${localizations.serverError}: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error in _updateUserData: $e");
      _showError('${localizations.connectionError}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
    print('user bname profile3 $fullName');
  }

  bool _validateBase64Image(String base64String) {
    try {
      if (base64String.isEmpty || base64String.length < 100) {
        return false;
      }

      base64Decode(base64String);

      String header = base64String.substring(0, 20).toLowerCase();
      bool isValidImageType =
          header.contains('data:image/') ||
          base64String.startsWith('/9j/') ||
          base64String.startsWith('iVBOR') ||
          base64String.startsWith('R0lGO');

      return true;
    } catch (e) {
      debugPrint("❌ Invalid base64 image: $e");
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        _showComingSoon(
          AppLocalizations.of(context)!.rewards,
          Icons.card_giftcard,
        );
        break;
      case 2:
        _showComingSoon(
          AppLocalizations.of(context)!.qrScanner,
          Icons.qr_code_scanner,
        );
        break;
      case 3:
        _showComingSoon(
          AppLocalizations.of(context)!.notifications,
          Icons.notifications,
        );
        break;
      case 4:
        break;
    }
  }

  void _showComingSoon(String feature, IconData icon) {
    final localizations = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              '${localizations.featureComingSoon} $feature!',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void showEditDialog(
    String title,
    String initialValue,
    Function(String) onSave,
  ) {
    final localizations = AppLocalizations.of(context)!;
    TextEditingController controller = TextEditingController(
      text: initialValue == AppLocalizations.of(context)!.loading
          ? ""
          : initialValue,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "${localizations.edit} $title",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "${localizations.enter} $title",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.cancel,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEC7103),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(
              localizations.save,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    print('user bname profile2 $fullName');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Color(0xFFEC7103),
        elevation: 0,

        title: Text(
          localizations.account,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageSelectionPage(),
                ),
              );
            },
            icon: const Icon(Icons.g_translate, color: Colors.white, size: 24),
            tooltip: localizations.changeLanguage,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: Colors.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 212, 101, 3),
                                  Color.fromARGB(155, 255, 151, 61),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: profileImageBytes != null
                                  ? MemoryImage(profileImageBytes!)
                                  : null,
                              child: profileImageBytes == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey.shade600,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(0xFFEC7103),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Column(
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),

                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 236, 88, 3),
                      Color.fromARGB(255, 255, 167, 89),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.pointsEarned,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            totalPoints,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.white30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            localizations.pointsRedeemed,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            redeemedPoints,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildInfoCard(localizations.personalDetails, [
                _buildDetailRow(
                  localizations.fullName,
                  fullName,
                  Icons.person_outline,
                  editable: true,
                  onTap: () {
                    showEditDialog(
                      localizations.fullName,
                      fullName,
                      (value) => setState(() => fullName = value),
                    );
                  },
                ),
                _buildDetailRow(
                  localizations.email,
                  email,
                  Icons.email_outlined,
                  editable: true,
                  onTap: () {
                    showEditDialog(
                      localizations.email,
                      email,
                      (value) => setState(() => email = value),
                    );
                  },
                ),
                _buildDetailRow(
                  localizations.phone,
                  phone,
                  Icons.phone_outlined,
                  editable: true,
                  onTap: () {
                    showEditDialog(
                      localizations.phone,
                      phone,
                      (value) => setState(() => phone = value),
                    );
                  },
                ),
                _buildDetailRow(
                  localizations.address,
                  address,
                  Icons.location_on_outlined,
                  editable: true,
                  onTap: () {
                    showEditDialog(
                      localizations.address,
                      address,
                      (value) => setState(() => address = value),
                    );
                  },
                ),
                _buildDetailRow(
                  localizations.city,
                  city,
                  Icons.location_city_outlined,
                  editable: true,
                  onTap: () {
                    showEditDialog(
                      localizations.city,
                      city,
                      (value) => setState(() => city = value),
                    );
                  },
                ),
                _buildDetailRow(
                  localizations.zip,
                  zip,
                  Icons.markunread_mailbox_outlined,
                  editable: true,
                  onTap: () {
                    showEditDialog(
                      localizations.zip,
                      zip,
                      (value) => setState(() => zip = value),
                    );
                  },
                ),
                _buildDetailRow(
                  localizations.password,
                  password,
                  Icons.lock_outline,
                  editable: true,
                  onTap: () {
                    showEditDialog(
                      localizations.password,
                      '',
                      (value) => setState(() => password = value),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 16),

              _buildInfoCard(localizations.accountDetails, [
                _buildDetailRow(
                  localizations.accountCreated,
                  createdAt,
                  Icons.calendar_today_outlined,
                ),
                _buildDetailRow("TRDR ID", trdr, Icons.badge_outlined),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isDeletingAccount ? null : _deleteAccount,
                      child: isDeletingAccount
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.red,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_forever_outlined,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  localizations.deleteAccount ??
                                      "Delete Account",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEC7103),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: isLoading ? null : _updateUserData,
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.save_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              localizations.updateProfile,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final localizations = AppLocalizations.of(context)!;

                    bool shouldLogout =
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            title: Text(localizations.confirmLogout),
                            content: Text(localizations.logoutConfirmation),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  localizations.cancel,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  localizations.logout,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;

                    if (shouldLogout) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      // Clear GetX or Provider states if used
                      Get.deleteAll(force: true);

                      // Delay to ensure everything cleared
                      await Future.delayed(const Duration(milliseconds: 300));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(localizations.loggedOutSuccessfully),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: EdgeInsets.all(16),
                        ),
                      );

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_outlined, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        localizations.logout,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),


              // Aapke existing code ke baad, Column ke last mein:

const SizedBox(height: 30), // ✅ Yeh already aapke paas hai

// ✅ Yahan se shuru karo naya code:
Container(
  margin: const EdgeInsets.only(bottom: 20),
  child: Column(
    children: [
      Text(
        'Version $_appVersion',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '© ${DateTime.now().year} Angelopoulos Hair',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w300,
        ),
      ),
    ],
  ),
),

// ✅ Agar simple chahiye sirf version:
// Text(
//   'Version $_appVersion',
//   style: TextStyle(
//     fontSize: 13,
//     color: Colors.grey.shade600,
//     fontWeight: FontWeight.w500,
//   ),
// ),
// const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String title,
    String value,
    IconData icon, {
    bool editable = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (editable)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFFEC7103),
                ),
              ),
            ),
        ],
      ),
    );
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
}