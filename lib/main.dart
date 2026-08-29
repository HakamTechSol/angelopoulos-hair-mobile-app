import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loyalty_app/Auth/auth_chacker.dart';
import 'package:loyalty_app/Services/language_service.dart';
import 'package:loyalty_app/screen/notifications_screen.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'firebase_options.dart';

// ✅ Global navigator key - MUST be defined before MyApp
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ Store pending notification for when app is closed
RemoteMessage? _pendingNotification;

// ✅ Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Handling a background message: ${message.messageId}");
  print("📱 Background message data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Firebase Messaging
  await _initializeFirebaseMessaging();

  // Initialize WebView platform
  WebViewPlatform.instance ??= AndroidWebViewPlatform();

  final localizationService = LocalizationService();
  await localizationService.initialize();

  runApp(MyApp(localizationService: localizationService));
}

Future<void> _initializeFirebaseMessaging() async {
  // Get FCM token
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print("🆓 FCM Token: $fcmToken");
  
  // Request permissions
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  
  print('📢 Notification permission granted: ${settings.authorizationStatus}');
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Handle token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print('🔄 FCM Token refreshed: $newToken');
  });
}

class MyApp extends StatelessWidget {
  final LocalizationService localizationService;

  const MyApp({super.key, required this.localizationService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocalizationService>(
      create: (context) => localizationService,
      child: Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
          return MaterialApp(
            title: 'Angelopoulos Rewards',
            locale: localizationService.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LocalizationService.supportedLocales,
            home: const MainScreenWithNotificationHandler(),
            theme: ThemeData(fontFamily: GoogleFonts.roboto().fontFamily),
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
          );
        },
      ),
    );
  }
}

class MainScreenWithNotificationHandler extends StatefulWidget {
  const MainScreenWithNotificationHandler({super.key});

  @override
  State<MainScreenWithNotificationHandler> createState() => _MainScreenWithNotificationHandlerState();
}

class _MainScreenWithNotificationHandlerState extends State<MainScreenWithNotificationHandler> {
  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
    _checkPendingNotification();
  }

  void _checkPendingNotification() {
    // Check if there's a pending notification from when app was closed
    if (_pendingNotification != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(_pendingNotification!);
        _pendingNotification = null;
      });
    }
  }

  void _setupNotificationHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Got a message whilst in the foreground!');
      _showInAppNotification(message);
    });
    
    // When app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Notification clicked from background!');
      _handleNotificationNavigation(message);
    });
    
    // When app is completely closed and opened via notification
    _handleInitialNotification();
  }
  
  Future<void> _handleInitialNotification() async {
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('🚀 App opened from terminated state via notification');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationNavigation(initialMessage);
        });
      }
    } catch (e) {
      print('❌ Error handling initial notification: $e');
    }
  }
void _handleNotificationNavigation(RemoteMessage message) {
  Future.delayed(Duration(milliseconds: 300), () {
    try {
      final Map<String, String> data = message.data.map(
        (key, value) => MapEntry(key, value.toString())
      );
      
      String? targetScreen = data['screen'];
      String? notificationId = data['notification_id'];
      String? notificationTitle = data['notification_title'];
      String? notificationBody = data['notification_body'];

      BuildContext? context = navigatorKey.currentContext;
      if (context == null) {
        print('⚠️ Context null, storing for later');
        _pendingNotification = message;
        return;
      }

      if (targetScreen == 'specific_notification' && notificationId != null) {
        // ✅ Pehle NotificationsScreen open karo with initialNotificationId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationsScreen(
              initialNotificationId: notificationId,
            ),
          ),
        );
      } else {
        // Default: Just open notifications list
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      }

      print('✅ Navigation successful');
    } catch (e) {
      print('❌ Navigation error: $e');
    }
  });
}
  
  void _showInAppNotification(RemoteMessage message) {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification?.body ?? 'New notification received'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleNotificationNavigation(message),
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AuthChecker();
  }
}