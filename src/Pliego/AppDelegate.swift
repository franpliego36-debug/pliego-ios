import UIKit
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Si el cliente ya dio permiso, pedimos a Apple el código del móvil en cada arranque.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async { application.registerForRemoteNotifications() }
            }
        }
        return true
    }

    // Apple nos da el código del móvil: se lo pasamos a la web, que lo apunta en Pliego.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        enviarTokenAWeb(token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        sendPushToWebView(userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

func enviarTokenAWeb(_ token: String) {
    if (!Pliego.webView.isHidden && !Pliego.webView.isLoading) {
        DispatchQueue.main.async {
            Pliego.webView.evaluateJavaScript("window.__apnsToken='\(token)';window.dispatchEvent(new CustomEvent('push-token-apns', { detail: '\(token)' }))")
        }
    } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { enviarTokenAWeb(token) }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner, .list, .sound]])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        sendPushClickToWebView(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
}
