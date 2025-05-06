import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Daily Reminder")) {
                    Toggle("Enable Reminder", isOn: $viewModel.reminderEnabled)
                        .disabled(!viewModel.notificationsAuthorized)
                    
                    if viewModel.reminderEnabled {
                        DatePicker("Reminder Time", 
                                  selection: $viewModel.reminderTime,
                                  displayedComponents: .hourAndMinute)
                            .disabled(!viewModel.notificationsAuthorized)
                    }
                    
                    if !viewModel.notificationsAuthorized {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Notifications are disabled. Please enable them in Settings.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        Button("Open Settings") {
                            viewModel.openSystemSettings()
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
} 