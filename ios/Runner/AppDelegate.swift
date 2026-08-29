import UIKit
import Flutter
import FirebaseCore
import FirebaseAuth // ✅ REQUIRED for Phone Auth
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)
        
        // Register for APNS
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // ✅ CRITICAL: This allows Firebase to handle the reCAPTCHA redirect URL
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // If Firebase Auth can handle the URL (reCAPTCHA), let it.
        if Auth.auth().canHandle(url) {
            return true
        }
        // Otherwise, let the Flutter app handle it.
        return super.application(app, open: url, options: options)
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // ✅ REQUIRED: Pass the token to BOTH Auth and Messaging for verification
        #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        #endif
        Messaging.messaging().apnsToken = deviceToken
        
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // ✅ REQUIRED when FirebaseAppDelegateProxyEnabled is false:
    // lets Firebase Auth handle silent push verification (avoids reCAPTCHA fallback)
    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM Registration Token: \(fcmToken ?? "N/A")")
    }
}
