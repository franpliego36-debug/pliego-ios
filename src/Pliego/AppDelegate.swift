import UIKit
import WebKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Asignar delegado para recibir avisos incluso con la app abierta
        UNUserNotificationCenter.current().delegate = self

        // Pedir permiso al usuario para recibir notificaciones
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    // Apple nos entrega el token del dispositivo
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        UserDefaults.standard.set(token, forKey: "apns_device_token")

        // Inyectar en la web para que se registre automáticamente
        NotificationCenter.default.post(name: NSNotification.Name("APNSDeviceTokenReceived"), object: token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error al registrar notificaciones remotas en Apple: \(error.localizedDescription)")
    }

    // Mostrar el aviso cuando el usuario tiene la app abierta en pantalla
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }

    // Al pulsar sobre el aviso recibido
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let urlDestino = userInfo["url"] as? String {
            NotificationCenter.default.post(name: NSNotification.Name("AbrirRutaApp"), object: urlDestino)
        }
        completionHandler()
    }
}
