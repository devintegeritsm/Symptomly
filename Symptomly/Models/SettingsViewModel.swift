import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var reminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
            scheduleReminder()
        }
    }
    
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
            scheduleReminder()
        }
    }
    
    @Published var notificationsAuthorized: Bool = false
    
    init() {
        // Set default values if not present in UserDefaults
        if UserDefaults.standard.object(forKey: "reminderEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "reminderEnabled")
        }
        
        if UserDefaults.standard.object(forKey: "reminderTime") == nil {
            // Default to 8:00 PM
            var components = DateComponents()
            components.hour = 20
            components.minute = 0
            let defaultTime = Calendar.current.date(from: components) ?? Date()
            UserDefaults.standard.set(defaultTime, forKey: "reminderTime")
        }
        
        self.reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        self.reminderTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date ?? Date()
        
        // Check if notifications are authorized
        checkNotificationAuthorization()
    }
    
    func checkNotificationAuthorization() {
        NotificationManager.shared.requestPermission { granted in
            self.notificationsAuthorized = granted
            if granted {
                self.scheduleReminder()
            }
        }
    }
    
    func scheduleReminder() {
        NotificationManager.shared.scheduleReminderNotification(
            at: reminderTime,
            enabled: reminderEnabled
        )
    }
    
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
} 