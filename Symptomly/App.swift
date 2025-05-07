//
//  App.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI
import SwiftData
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize settings to trigger notification setup
        let settings = SettingsViewModel()
        settings.checkNotificationAuthorization()
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even if the app is in foreground
        completionHandler([.banner, .sound])
    }
}

@main
struct SymptomlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Symptom.self,
            Remedy.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                DailySymptomView()
                    .tabItem {
                        Image(systemName: "list.clipboard")
                        Text("Symptoms")
                    }
                
                RemedyListView(selectedDate: .constant(Date()))
                    .tabItem {
                        Image(systemName: "pill")
                        Text("Remedies")
                    }
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
} 
