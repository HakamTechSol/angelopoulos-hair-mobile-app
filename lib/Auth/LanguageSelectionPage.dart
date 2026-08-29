import 'package:flutter/material.dart';
import 'package:loyalty_app/Services/language_service.dart';
import 'package:provider/provider.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late String selectedLanguageCode;

  final List<Map<String, dynamic>> languages = [
    {
      'name': 'Greek',
      'nativeName': 'Ελληνικά',
      'code': 'el',
      'flag': '🇬🇷',
    },
    {
      'name': 'English',
      'nativeName': 'English',
      'code': 'en',
      'flag': '🇺🇸',
    },
    {
      'name': 'Romanian',
      'nativeName': 'Română',
      'code': 'ro',
      'flag': '🇷🇴',
    },
  ];

  @override
  void initState() {
    super.initState();
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    selectedLanguageCode = localizationService.currentLocale.languageCode;
  }

  // Compact Header with Logo Only
  Widget _buildHeaderSection(BuildContext context) {
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
            // Logo Only
            Center(
              child: Image.asset(
                'assets/images/home-logo.png',
                width: 200, // Slightly smaller
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final localizationService = Provider.of<LocalizationService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Compact Header
          _buildHeaderSection(context),
          
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), // Reduced space
                  
                  // Back Button Row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        localizations.back,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20), // Reduced space
                  
                  // Page Title
                  Text(
                    localizations.languageSelection,
                    style: const TextStyle(
                      fontSize: 22, // Slightly smaller
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 6), // Reduced space
                  
                  // Subtitle
                  
                  
                  const SizedBox(height: 24), // Reduced space
                  
                  // Language Options - More Compact
                  Expanded(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                      itemCount: languages.length,
                      itemBuilder: (context, index) {
                        final language = languages[index];
                        final isSelected = selectedLanguageCode == language['code'];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12), // Reduced margin
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10), // Slightly smaller radius
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFFF6B35) 
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8, // Reduced shadow
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
                            onTap: () {
                              setState(() {
                                selectedLanguageCode = language['code'];
                              });
                            },
                            leading: Container(
                              width: 40, // Smaller flag container
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  language['flag'],
                                  style: const TextStyle(fontSize: 20), // Smaller flag
                                ),
                              ),
                            ),
                            title: Text(
                              language['nativeName'],
                              style: TextStyle(
                                fontSize: 15, // Slightly smaller text
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? const Color(0xFFFF6B35) 
                                    : Colors.black,
                              ),
                            ),
                            // subtitle: Text(
                            //  " language['name']",
                            //   style: TextStyle(
                            //     fontSize: 13, // Smaller subtitle
                            //     color: Colors.grey.shade600,
                            //   ),
                            // ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFFF6B35),
                                    size: 22, // Smaller icon
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.grey.shade400,
                                    size: 22,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Confirm Button
                  Container(
                    width: double.infinity,
                    height: 50, // Slightly smaller button
                    margin: const EdgeInsets.only(bottom: 20), // Reduced margin
                    child: ElevatedButton(
                      onPressed: () async {
                        await localizationService.changeLanguage(selectedLanguageCode);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(localizations.languageChanged),
                            backgroundColor: const Color(0xFFFF6B35),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        localizations.confirm,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Developer Credit - More Compact
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 3, // Thinner line
                          width: 100, // Shorter line
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          localizations.developedBy,
                          style: const TextStyle(
                            fontSize: 11, // Smaller text
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15), // Reduced bottom space
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}