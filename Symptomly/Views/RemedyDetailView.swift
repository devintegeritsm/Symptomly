//
//  RemedyDetailView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 6/19/25.
//

import SwiftUI
import SwiftData

struct RemedyDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let remedy: Remedy
    
    @State private var name: String
    @State private var potency: String
    @State private var customPotency: String
    @State private var takenTimestamp: Date
    @State private var prescribedTimestamp: Date
    @State private var effectivenessDueDate: Date
    @State private var notes: String
    @State private var hasRecurrence: Bool
    @State private var recurrenceRule: String
    @State private var recurrenceFrequency: Int
    @State private var recurrenceInterval: Int
    @State private var recurrenceEndDate: Date
    
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    init(remedy: Remedy) {
        self.remedy = remedy
        
        // Initialize state from the remedy
        _name = State(initialValue: remedy.name)
        _potency = State(initialValue: remedy.potency)
        _customPotency = State(initialValue: remedy.customPotency ?? "")
        _takenTimestamp = State(initialValue: remedy.takenTimestamp)
        _prescribedTimestamp = State(initialValue: remedy.prescribedTimestamp)
        _effectivenessDueDate = State(initialValue: remedy.effectivenessDueDate)
        _notes = State(initialValue: remedy.notes ?? "")
        _hasRecurrence = State(initialValue: remedy.hasRecurrence)
        _recurrenceRule = State(initialValue: remedy.recurrenceRule ?? RecurrenceRule.daily.rawValue)
        _recurrenceFrequency = State(initialValue: remedy.recurrenceFrequency ?? 2)
        _recurrenceInterval = State(initialValue: remedy.recurrenceInterval ?? 12)
        _recurrenceEndDate = State(initialValue: remedy.recurrenceEndDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with name and potency
                HStack {
                    Text(remedy.name)
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    Text(remedy.displayPotency)
                        .font(.title3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.teal.opacity(0.2))
                        .foregroundColor(.teal)
                        .cornerRadius(12)
                }
                .padding(.bottom, 8)
                
                if isEditing && potency == RemedyPotency.other.rawValue {
                    TextField("Custom potency", text: $customPotency)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Divider()
                
                // Timing information
                VStack(alignment: .leading, spacing: 12) {
                    
                    HStack {
                        if isEditing {
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock").foregroundColor(.secondary)
                                    Text("Prescribed on:")
                                }
                                CustomDatePicker(selection: $prescribedTimestamp)
                            }
                        } else {
                            let calendar = Calendar.current
                            if !calendar.isDate(remedy.prescribedTimestamp, inSameDayAs: remedy.takenTimestamp) {
                                Image(systemName: "calendar.badge.clock").foregroundColor(.secondary)
                                Text("Prescribed on \(formatDateTime(remedy.prescribedTimestamp))")
                            }
                        }
                    }
                    
                    HStack {
                        if isEditing {
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "calendar").foregroundColor(.secondary)
                                    Text("Taken on:")
                                }
                                CustomDatePicker(selection: $takenTimestamp, includeTime: true)
                            }
                        } else {
                            Image(systemName: "calendar").foregroundColor(.secondary)
                            Text("Taken on \(formatDateTime(remedy.takenTimestamp))")
                        }
                    }
                    
                    HStack {
                        if isEditing {
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "timer").foregroundColor(.secondary)
                                    Text("Wait and watch until:")
                                }
                                CustomDatePicker(selection: $effectivenessDueDate, includeTime: true)
                            }
                        } else {
                            Image(systemName: "timer").foregroundColor(.secondary)
                            Text("Wait and watch until \(formatDateTime(remedy.effectivenessDueDate))")
                                .foregroundColor(remedy.isActive ? .green : .gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Recurrence information
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.secondary)
                        
                        if isEditing {
                            Toggle("", isOn: $hasRecurrence)
                                .labelsHidden()
                            
                            Text("Repeat Schedule")
                        } else {
                            Text(remedy.hasRecurrence ? "Repeating" : "No repetition")
                        }
                    }
                    
                    if isEditing && hasRecurrence {
                        Picker("Recurrence", selection: $recurrenceRule) {
                            ForEach(RecurrenceRule.allCases, id: \.rawValue) { rule in
                                Text(rule.rawValue).tag(rule.rawValue)
                            }
                        }
                        
                        if recurrenceRule == RecurrenceRule.multipleTimesPerDay.rawValue {
                            Stepper(value: $recurrenceFrequency, in: 2...12) {
                                Text("\(recurrenceFrequency) times per day")
                            }
                            
                            Stepper(value: $recurrenceInterval, in: 1...12) {
                                Text("Every \(recurrenceInterval) hours")
                            }
                        }
                        
                        CustomDatePicker("End Repeat", selection: $recurrenceEndDate)
                    } else if remedy.hasRecurrence {
                        HStack {
                            Text("Rule:")
                                .foregroundColor(.secondary)
                            Text(remedy.recurrenceRule ?? "")
                        }
                        
                        if remedy.recurrenceRuleEnum == .multipleTimesPerDay, 
                           let frequency = remedy.recurrenceFrequency, 
                           let interval = remedy.recurrenceInterval {
                            HStack {
                                Text("Frequency:")
                                    .foregroundColor(.secondary)
                                Text("\(frequency) times per day (every \(interval) hours)")
                            }
                        }
                        
                        if let endDate = remedy.recurrenceEndDate {
                            HStack {
                                Text("Ends on:")
                                    .foregroundColor(.secondary)
                                Text(formatDate(endDate))
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    if isEditing {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    } else {
                        if let notes = remedy.notes, !notes.isEmpty {
                            Text(notes)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            Text("No notes")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .padding()
            .navigationTitle("Remedy Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                            isEditing = false
                        }
                        .disabled(name.isEmpty || (potency == RemedyPotency.other.rawValue && customPotency.isEmpty))
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert("Delete Remedy", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteRemedy()
                }
            } message: {
                Text("Are you sure you want to delete this remedy? This action cannot be undone.")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func saveChanges() {
        remedy.name = name
        remedy.potency = potency
        remedy.customPotency = potency == RemedyPotency.other.rawValue ? customPotency : nil
        remedy.takenTimestamp = takenTimestamp
        remedy.prescribedTimestamp = prescribedTimestamp
        remedy.effectivenessDueDate = effectivenessDueDate
        remedy.notes = notes.isEmpty ? nil : notes
        remedy.hasRecurrence = hasRecurrence
        
        if hasRecurrence {
            remedy.recurrenceRule = recurrenceRule
            
            if recurrenceRule == RecurrenceRule.multipleTimesPerDay.rawValue {
                remedy.recurrenceFrequency = recurrenceFrequency
                remedy.recurrenceInterval = recurrenceInterval
            } else {
                remedy.recurrenceFrequency = nil
                remedy.recurrenceInterval = nil
            }
            
            remedy.recurrenceEndDate = recurrenceEndDate
            
            // Update notifications
            NotificationManager.shared.cancelNotifications(identifiers: remedy.notificationIdentifiers)
            let newIdentifiers = NotificationManager.shared.scheduleRemedyNotifications(for: remedy)
            remedy.notificationIdentifiers = newIdentifiers
        } else {
            remedy.recurrenceRule = nil
            remedy.recurrenceFrequency = nil
            remedy.recurrenceInterval = nil
            remedy.recurrenceEndDate = nil
            
            // Cancel any notifications
            NotificationManager.shared.cancelNotifications(identifiers: remedy.notificationIdentifiers)
            remedy.notificationIdentifiers = []
        }
        
        // Recalculate wait and watch period
        let waitPeriodSeconds = Int(effectivenessDueDate.timeIntervalSince(takenTimestamp))
        remedy.waitAndWatchPeriod = waitPeriodSeconds
        
        // Notify that remedy was updated
        NotificationCenter.default.post(name: NSNotification.Name("DidUpdateRemedy"), object: nil)
    }
    
    private func deleteRemedy() {
        // Cancel notifications before deletion
        NotificationManager.shared.cancelNotifications(identifiers: remedy.notificationIdentifiers)
        
        modelContext.delete(remedy)
        
        // Notify that a remedy was deleted
        NotificationCenter.default.post(name: NSNotification.Name("DidDeleteRemedy"), object: nil)
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Remedy.self, configurations: config)
    
    let sampleRemedy = Remedy(
        name: "Arnica",
        potency: "30C",
        takenTimestamp: Date(),
        prescribedTimestamp: Date(),
        waitAndWatchPeriod: 7 * 24 * 60 * 60,
        effectivenessDueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
        notes: "For muscle soreness after workout"
    )
    
    return NavigationStack {
        RemedyDetailView(remedy: sampleRemedy)
    }
    .modelContainer(container)
} 
