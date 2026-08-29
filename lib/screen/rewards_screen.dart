import 'package:flutter/material.dart';
import 'package:loyalty_app/Services/language_service.dart'
    show AppLocalizations;
import 'package:loyalty_app/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:loyalty_app/utils/language_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:loyalty_app/Auth/LanguageSelectionPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:loyalty_app/Services/language_service.dart';
import 'package:charset_converter/charset_converter.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<RewardItem> rewards = [];
  List<RewardItem> displayedRewards = [];
  bool isLoading = true;
  String? error;
  String totalPoints = "0";
  final bool _isLoading = false;
  String userName = "User";
  String? profileImagePath;
  int itemsToShow = 10;
  bool _hasError = false;
  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchRewards();
    loadTotalPoints();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalPoints = prefs.getString('totalPoints') ?? '2000';
      userName = prefs.getString('Namee') ?? 'unknown';
    });
    print('user bname $userName');
  }

  void _updateDisplayedRewards() {
    setState(() {
      displayedRewards = rewards.take(itemsToShow).toList();
    });
  }

  void _loadMoreItems() {
    setState(() {
      itemsToShow = rewards.length;
      _updateDisplayedRewards();
    });
  }

  Future<void> loadTotalPoints() async {
    if (_isLoading) return;

    setState(() {
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
        String responseBody = await decodeGreekResponseBytes(response.bodyBytes);
        final data = jsonDecode(responseBody);

        if (data is Map<String, dynamic> &&
            data['success'] == true &&
            data['rows'] != null &&
            data['rows'].isNotEmpty) {
          final points = data['rows'][0]['totalpoints']?.toString() ?? "0";

          // Base64 image save karo
          final base64Image = data['rows'][0]['CCCXITLIMAGE']?.toString() ?? '';

          await prefs.setString('totalPoints', points);

          // Base64 image ko SharedPreferences me save karo
          if (base64Image.isNotEmpty) {
            await prefs.setString('user_profile_base64', base64Image);
          }

          if (mounted) {
            setState(() {
              totalPoints = points;
              profileImagePath = base64Image;
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
        setState(() {});
      }
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

  Future<void> fetchRewards() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyUrl = prefs.getString('company_url');
      final softwareType = prefs.getString('software_type');
      final clientID = prefs.getString('clientID');
      final trdr = prefs.getString('TRDR');

      debugPrint("🔍 SharedPreferences values:");
      debugPrint(" companyUrl: $companyUrl");
      debugPrint(" softwareType: $softwareType");
      debugPrint(" clientID: $clientID");
      debugPrint(" trdr: $trdr");

      if (companyUrl == null ||
          softwareType == null ||
          clientID == null ||
          trdr == null) {
        throw Exception(
          "Missing required SharedPreferences values:\n"
          "companyUrl: $companyUrl\n"
          "softwareType: $softwareType\n"
          "clientID: $clientID\n"
          "trdr: $trdr",
        );
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
        "SqlName": "9701",
        "trdr": trdr,
      };

      debugPrint("📤 Request body: ${jsonEncode(requestBody)}");

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'LoyaltyApp/1.0',
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                "Request timeout - Server took too long to respond",
              );
            },
          );

      debugPrint("📥 Response status: ${response.statusCode}");
      debugPrint("📥 Response headers: ${response.headers}");
      debugPrint("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        String responseBody = await decodeGreekResponseBytes(response.bodyBytes);
        final data = jsonDecode(responseBody);
        List<dynamic> rewardsData = [];

        if (data is Map<String, dynamic>) {
          if (data['success'] == true &&
              data['rows'] != null &&
              data['rows'] is List) {
            rewardsData = data['rows'] as List<dynamic>;
          } else if (data['rows'] != null && data['rows'] is List) {
            rewardsData = data['rows'] as List<dynamic>;
          } else if (data['data'] != null && data['data'] is List) {
            rewardsData = data['data'] as List<dynamic>;
          } else {
            // Create sample data for testing
            rewardsData = [
              {
                'code': '1002',
                'barcode': '348370',
                'name': 'Keratin Nanocure® Marrakesh Nights Argan Oil 100ml',
                'image':
                    'https://www.angelopouloshair.gr/media/catalog/product/cache/2d7a18900e6360ff4f79090378c73bca/k/e/keratin-nanocure-marrakesh-nights-argan-oil-100ml-2.jpg',
                'redirecturl':
                    'https://www.angelopouloshair.gr/el/keratin-nanocurer-argan-oil-100ml?q=348370',
                'points': '120',
              },
              {
                'code': '1021',
                'barcode': '82876',
                'name': 'Keratin Nanocure® Au Gold 24ct Shampoo 500ml',
                'image':
                    'https://www.angelopouloshair.gr/media/catalog/product/cache/2d7a18900e6360ff4f79090378c73bca/A/u/Au_Organic_Premium_Nanocure_Gold_24kt_Shampoo.jpg',
                'redirecturl':
                    'https://www.angelopouloshair.gr/el/keratin-nanocurer-au-gold-24ct-shampoo-500ml',
                'points': '200',
              },
              {
                'code': '1003',
                'barcode': '344743',
                'name':
                    'L\'Oréal Professionnel Steampod v3 Ισιωτική Πρέσα Ατμού',
                'image':
                    'https://via.placeholder.com/100x100/C0C0C0/000000?text=SteamPod',
                'redirecturl': 'https://example.com/steampod',
                'points': '2500',
              },
            ];
          }
        } else if (data is List) {
          rewardsData = data;
        } else {
          throw Exception(
            "Invalid response format: Expected Map or List but got ${data.runtimeType}",
          );
        }

        if (mounted) {
          setState(() {
            rewards = rewardsData
                .map((item) => RewardItem.fromJson(item))
                .toList();
            _updateDisplayedRewards();
            isLoading = false;
          });
        }
        return;
      } else if (response.statusCode == 403) {
        throw Exception("Access denied (403) - Check CORS or authentication");
      } else if (response.statusCode == 404) {
        throw Exception("Service not found (404) - Check URL and service path");
      } else if (response.statusCode == 500) {
        throw Exception("Server error (500) - Check server logs");
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("❗ Error loading rewards: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          error = e.toString();
        });
      }
    }
  }

  // Fixed sticky header
  Widget _buildStickyHeader(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ✅ Orange Header Section (Logo + Profile + Welcome + Language)
          Container(
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
                      'assets/images/home-logo.png', // apna logo rakho
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

                      // Welcome text
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

                      // Language button
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LanguageSelectionPage(),
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
          ),

          // ✅ Points Section
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 5),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          134,
                          134,
                          134,
                        ).withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(9, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLoading
                            ? localizations.loading
                            : '$totalPoints ${localizations.points}',
                        style: GoogleFonts.jura(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEC7103),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/icons/star-icon.png',
                        width: 30,
                        height: 30,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.star,
                            color: Color(0xFFEC7103),
                            size: 35,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildBalanceSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        children: [
          Text(
            'My balance',
            style: GoogleFonts.jura(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(221, 30, 255, 0),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    134,
                    134,
                    134,
                  ).withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(9, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isLoading ? 'Loading...' : '$totalPoints POINTS',
                  style: GoogleFonts.jura(
                    fontSize: 20, // Bigger text like in image
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEC7103),
                  ),
                ),
                const SizedBox(width: 8),
                // Bigger star icon
                Image.asset(
                  'assets/icons/star-icon.png',
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.star,
                      color: Color(0xFFEC7103),
                      size: 35,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(RewardItem item) {
    showDialog(
      context: context,
      barrierColor: const Color.fromARGB(255, 255, 255, 255),
      builder: (context) => Dialog(
        backgroundColor: const Color.fromARGB(236, 255, 255, 255),
        insetPadding: EdgeInsets.zero,
        elevation: 0,
        child: Container(
          color: const Color.fromARGB(221, 255, 255, 255),
          child: Stack(
            children: [
              // Full screen image
              Center(
                child: Hero(
                  tag: item.image,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.only(
                      top: 70,
                      bottom: 120,
                      left: 100,
                      right: 100,
                    ),
                    child: Image.network(
                      item.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 300,
                          height: 300,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/thinking1.png',
                                width: 118,
                                height: 118,
                                // optional
                              ),

                              const SizedBox(height: 12),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 300,
                          height: 300,
                          color: Colors.grey[900],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Close button (top right)
              Positioned(
                top: 40,
                right: 20,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              // Shop Now button (bottom left)
              Positioned(
                bottom: 25,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _launchURL(item.redirectUrl);
                      },
                      icon: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'Shop Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC7103),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ),
              ),
              // Product title (bottom center)
              if (item.title.isNotEmpty)
                Positioned(
                  bottom: 80,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(158, 255, 255, 255),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Fixed URL launch function
  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No URL available for this product'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      debugPrint('🔗 Attempting to launch URL: $url');

      // Clean the URL if needed
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final Uri uri = Uri.parse(cleanUrl);
      debugPrint('🔗 Parsed URI: $uri');

      // Launch URL directly without checking canLaunchUrl first
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        debugPrint('✅ Successfully launched URL: $cleanUrl');
      } else {
        throw Exception('Failed to launch URL');
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Fixed header at top
          _buildStickyHeader(context),
          // Scrollable content below
          Expanded(child: _buildScrollableContent()),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    final localizations = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFEC7103)),
            SizedBox(height: 16),
            Text("Loading rewards..."),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                localizations.errorLoadingRewards,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: fetchRewards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC7103),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              // TextButton(
              //   onPressed: _showDebugInfo,
              //   child: const Text('Show Debug Info'),
              // ),
            ],
          ),
        ),
      );
    }

    if (rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              localizations.noRewardsAvailable,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchRewards,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC7103),
                foregroundColor: Colors.white,
              ),
              child: Text(localizations.refreshText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchRewards,
      color: const Color(0xFFEC7103),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayedRewards.length < rewards.length
            ? displayedRewards.length + 1
            : displayedRewards.length,
        itemBuilder: (context, index) {
          if (index < displayedRewards.length) {
            final item = displayedRewards[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: VerticalRewardCard(
                item: item,
                onTap: () => _showImageViewer(item),
              ),
            );
          } else if (index == displayedRewards.length &&
              displayedRewards.length < rewards.length) {
            // Show "Load More" button
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: ElevatedButton(
                  onPressed: _loadMoreItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC7103),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Load More Products'),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  void _showDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final companyUrl = prefs.getString('company_url');
    final softwareType = prefs.getString('software_type');
    final clientID = prefs.getString('clientID');
    final trdr = prefs.getString('TRDR');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugRow('Company URL', companyUrl),
              _buildDebugRow('Software Type', softwareType),
              _buildDebugRow('Client ID', clientID),
              _buildDebugRow('TRDR', trdr),
              const SizedBox(height: 8),
              const Text(
                'Last Error:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(error ?? 'None'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'null',
              style: TextStyle(
                color: value == null ? Colors.red : Colors.black,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// language character corrector

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


// Rest of the classes remain the same
class RewardItem {
  final String title;
  final String image;
  final int points;
  final String? code;
  final String? barcode;
  final String? sku;
  final String? description;
  final String? redirectUrl;

  RewardItem({
    required this.title,
    required this.image,
    required this.points,
    this.code,
    this.barcode,
    this.sku,
    this.description,
    this.redirectUrl,
  });

  factory RewardItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return RewardItem(
        title: json['name']?.toString() ?? 'Unknown Product',
        image: json['image']?.toString() ?? '',
        points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
        code: json['code']?.toString(),
        barcode: json['barcode']?.toString(),
        sku: json['barcode']?.toString(),
        description: json['description']?.toString(),
        redirectUrl: json['redirecturl']?.toString(),
      );
    }
    return RewardItem(title: 'Unknown Product', image: '', points: 0);
  }
}

class VerticalRewardCard extends StatelessWidget {
  final RewardItem item;
  final VoidCallback? onTap;

  const VerticalRewardCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEC7103), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Hero(
                tag: item.image,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImage(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SKU
                    if (item.sku != null && item.sku!.isNotEmpty)
                      Text(
                        'SKU: ${item.sku}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                    const SizedBox(height: 8),
                    // Description
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: GoogleFonts.jura(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    // Points Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC7103),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${item.points} POINTS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.image.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[300],
        child: const Icon(
          Icons.image_not_supported,
          size: 32,
          color: Colors.grey,
        ),
      );
    }

    // Check if it's a network image (URL) or local asset
    if (item.image.startsWith('http')) {
      return Image.network(
        item.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFEC7103),
              ),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        item.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
          );
        },
      );
    }
  }
}
