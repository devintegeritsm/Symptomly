import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
                Form {
                    Section(header: Text("Daily Reminder")) {
                        Toggle("Enable Reminder", isOn: $viewModel.reminderEnabled)
                            .disabled(!viewModel.notificationsAuthorized)
                        
                        if viewModel.reminderEnabled {
                            HStack {
                                Text("Reminder Time")
                                Spacer()
                                Button(action: {
                                    showTimePicker()
                                }) {
                                    Text(formatTime(viewModel.reminderTime))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(!viewModel.notificationsAuthorized)
                            }
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
            }
        }
    }
    
    private func showTimePicker() {
        // Create a temporary alert controller to host our time picker
        let alert = UIAlertController(title: "Select Reminder Time", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        
        // Create a time picker
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.date = viewModel.reminderTime
        
        // Add constraints to position the picker
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(timePicker)
        
        NSLayoutConstraint.activate([
            timePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            timePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 40),
            timePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 0),
            timePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: 0)
        ])
        
        // Add actions
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            viewModel.reminderTime = timePicker.date
        })
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 
