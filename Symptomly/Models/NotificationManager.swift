import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleReminderNotification(at date: Date, enabled: Bool) {
        // Cancel any existing notifications first
        cancelNotifications(withIdentifier: "dailySymptomReminder")
        
        // If reminders are disabled, just return after canceling
        if !enabled {
            return
        }
        
        // Extract hour and minute components from the date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        // Create a date for today with the specified time
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Daily Symptom Check"
        content.body = "Don't forget to log your symptoms for today!"
        content.sound = .default
        
        // Create a daily trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "dailySymptomReminder",
            content: content,
            trigger: trigger
        )
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleRemedyNotifications(for remedy: Remedy) -> [String] {
        // Cancel any existing notifications for this remedy
        cancelNotifications(identifiers: remedy.notificationIdentifiers)
        
        var notificationIdentifiers: [String] = []
        
        // If no recurrence, we don't need to schedule anything
        guard remedy.hasRecurrence, 
              let recurrenceRule = remedy.recurrenceRuleEnum,
              let endDate = remedy.recurrenceEndDate else {
            return notificationIdentifiers
        }
        
        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Remedy Reminder"
        content.body = "Time to take \(remedy.name) \(remedy.displayPotency)"
        content.sound = .default
        
        // Calculate and schedule notifications based on recurrence rule
        switch recurrenceRule {
        case .daily:
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: remedy.takenTimestamp)
            
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "remedy-\(UUID().uuidString)"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
            
            notificationIdentifiers.append(identifier)
            
        case .multipleTimesPerDay:
            guard let frequency = remedy.recurrenceFrequency,
                  let interval = remedy.recurrenceInterval else {
                break
            }
            
            // Calculate multiple times per day
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let secondsInDay = 24 * 60 * 60
            let intervalSeconds = secondsInDay / frequency
            
            for i in 0..<frequency {
                let offsetSeconds = i * intervalSeconds
                if let notificationTime = calendar.date(byAdding: .second, value: offsetSeconds, to: startOfDay) {
                    // Schedule a notification at this time
                    let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
                    
                    var dateComponents = DateComponents()
                    dateComponents.hour = components.hour
                    dateComponents.minute = components.minute
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let identifier = "remedy-\(UUID().uuidString)"
                    
                    let request = UNNotificationRequest(
                        identifier: identifier,
                        content: content,
                        trigger: trigger
                    )
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling notification: \(error)")
                        }
                    }
                    
                    notificationIdentifiers.append(identifier)
                }
            }
            
        case .everyOtherDay, .weekly, .biweekly, .monthly:
            // These are more complex and would require calculating specific dates
            // For now, we'll schedule just one notification at the same time
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: remedy.takenTimestamp)
            
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            
            // Add appropriate weekday for weekly/biweekly
            if recurrenceRule == .weekly || recurrenceRule == .biweekly {
                dateComponents.weekday = calendar.component(.weekday, from: remedy.takenTimestamp)
            }
            
            // Add day of month for monthly
            if recurrenceRule == .monthly {
                dateComponents.day = calendar.component(.day, from: remedy.takenTimestamp)
            }
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "remedy-\(UUID().uuidString)"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
            
            notificationIdentifiers.append(identifier)
        }
        
        return notificationIdentifiers
    }
    
    func cancelNotifications(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelNotifications(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 