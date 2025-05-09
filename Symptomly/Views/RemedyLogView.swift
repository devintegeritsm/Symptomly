//
//  RemedyLogView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 6/19/25.
//

import SwiftUI
import SwiftData

struct RemedyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingRemedies: [Remedy]
    
    @State private var name: String = ""
    @State private var potency: String = RemedyPotency.potency30C.rawValue
    @State private var customPotency: String = ""
    @State private var takenTimestamp: Date = Date()
    @State private var prescribedTimestamp: Date = Date()
    @State private var notes: String = ""
    @State private var showSuggestions: Bool = false
    @State private var filteredSuggestions: [String] = []
    
    // Wait and watch settings
    @State private var waitValue: Int = 1
    @State private var waitUnit: Calendar.Component = .weekOfMonth
    @State private var effectivenessDueDate: Date = {
        let calendar = Calendar.current
        return calendar.date(byAdding: .weekOfMonth, value: 1, to: Date()) ?? Date()
    }()
    @State private var stepperDate: Date = Date()
    @State private var dueDateUpdated: Bool = false

    
    // Recurrence properties
    @State private var hasRecurrence: Bool = false
    @State private var recurrenceRule: String = RecurrenceRule.daily.rawValue
    @State private var recurrenceFrequency: Int = 2
    @State private var recurrenceInterval: Int = 12
    @State private var recurrenceEndDate: Date = {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }()
    
    // Range limits for wait values based on unit
    private var waitValueRange: ClosedRange<Int> {
        switch waitUnit {
        case .hour:
            return 1...72
        case .day:
            return 1...180
        case .weekOfMonth, .weekOfYear:
            return 1...52
        case .month:
            return 1...24
        default:
            return 1...180
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Remedy Information") {
                    TextField("Enter remedy name", text: $name)
                        .autocorrectionDisabled(true)
                        .onChange(of: name) { _, newValue in
                            if !newValue.isEmpty {
                                updateSuggestions(query: newValue)
                                showSuggestions = !filteredSuggestions.isEmpty
                            } else {
                                showSuggestions = false
                            }
                        }
                    
                    if showSuggestions {
                        List(filteredSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                name = suggestion
                                showSuggestions = false
                            }) {
                                Text(suggestion)
                            }
                        }
                    }
                    
                    Picker("Potency", selection: $potency) {
                        ForEach(RemedyPotency.allCases, id: \.rawValue) { potencyLevel in
                            Text(potencyLevel.rawValue).tag(potencyLevel.rawValue)
                        }
                    }
                    .onChange(of: potency) { _, _ in
                        updateDefaultWaitPeriod()
                    }
                    
                    if potency == RemedyPotency.other.rawValue {
                        TextField("Custom potency", text: $customPotency)
                    }
                }
                
                Section("Timing") {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "calendar.badge.clock").foregroundColor(.secondary)
                            Text("Prescribed on:")
                        }
                        CustomDatePicker(selection: $prescribedTimestamp)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.secondary)
                            Text("Taken on:")
                        }
                        CustomDatePicker(selection: $takenTimestamp, includeTime: true)
                        .onChange(of: takenTimestamp) { _, _ in
                            updateEffectivenessDueDate()
                        }
                    }
                }
                
                Section("Wait and Watch Period") {
                    VStack(alignment: .leading) {
                        Text("Duration:")
                        HStack {
                            Spacer()
                            Text("\(waitValue)")
                                .monospacedDigit()
                            
                            Stepper("", value: $waitValue, in: waitValueRange)
                                .labelsHidden()
                                .fixedSize()
                               
                            Picker("", selection: $waitUnit) {
                                Text("Hours").tag(Calendar.Component.hour)
                                Text("Days").tag(Calendar.Component.day)
                                Text("Weeks").tag(Calendar.Component.weekOfMonth)
                                Text("Months").tag(Calendar.Component.month)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .onChange(of: waitUnit) { oldUnit, newUnit in
                                
                                var pervHours: Int
                                switch oldUnit {
                                case .day:
                                    pervHours = waitValue * 24
                                case .weekOfMonth, .weekOfYear:
                                    pervHours = waitValue * 24 * 7
                                case .month:
                                    pervHours = waitValue * 24 * 30
                                default:
                                    pervHours = waitValue
                                }
                                
                                switch newUnit {
                                case .day:
                                    waitValue = pervHours / 24
                                case .weekOfMonth, .weekOfYear:
                                    waitValue = pervHours / (24 * 7)
                                case .month:
                                    waitValue = pervHours / (24 * 30)
                                default:
                                    waitValue = pervHours
                                }
                                
                                
                                if waitValue > waitValueRange.upperBound {
                                    waitValue = waitValueRange.upperBound
                                } else if waitValue < waitValueRange.lowerBound {
                                    waitValue = waitValueRange.lowerBound
                                }
                                updateEffectivenessDueDate()
                            }
                        }
                        .onChange(of: waitValue) { _, _ in
                            updateEffectivenessDueDate()
                        }
                    }
                                        
                    VStack(alignment: .leading) {
                        Text("Wait and Watch until:")
                        CustomDatePicker(selection: $effectivenessDueDate, includeTime: true)
                            .onChange(of: effectivenessDueDate) { _, newValue in
                                updateWaitAndWatchFromDueDate(newValue)
                        }
                    }
                }
                
                Section {
                    Toggle("Repeat Schedule", isOn: $hasRecurrence)
                    
                    if hasRecurrence {
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
                    }
                } header: {
                    Text("Recurrence")
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Log Remedy")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRemedy()
                    }
                    .disabled(name.isEmpty || (potency == RemedyPotency.other.rawValue && customPotency.isEmpty))
                }
            }
            .onAppear {
                // Set default wait and watch period based on selected potency
                updateDefaultWaitPeriod()
            }
        }
        .backgroundStyle(.thickMaterial)
    }
    
    private func updateSuggestions(query: String) {
        // Get user's previously entered remedy names
        let uniqueUserRemedyNames = Set(existingRemedies.map { $0.name })
        
        // Combine with predefined remedies, giving priority to user's entries
        var allRemedyNames = uniqueUserRemedyNames
        allRemedyNames.formUnion(PredefinedData.remedyNames)
        
        // Filter based on query
        filteredSuggestions = Array(allRemedyNames).filter { 
            $0.lowercased().contains(query.lowercased()) && $0 != query 
        }
        .sorted()  // Sort alphabetically for better UX
    }
    
    private func updateDefaultWaitPeriod() {
        if let potencyEnum = RemedyPotency(rawValue: potency) {
            let defaultPeriod = potencyEnum.defaultWaitPeriod
            waitValue = defaultPeriod.value
            waitUnit = defaultPeriod.unit
            updateEffectivenessDueDate()
        }
    }
    
    private func updateEffectivenessDueDate() {
        if dueDateUpdated {
            dueDateUpdated = false
            return
        }
        let calendar = Calendar.current
        effectivenessDueDate = calendar.date(byAdding: waitUnit, value: waitValue, to: takenTimestamp) ?? Date()
        stepperDate = effectivenessDueDate
    }
    
    
    private func updateWaitAndWatchFromDueDate(_ dueDate: Date) {
        if dueDate == stepperDate {
            return
        }
        dueDateUpdated = true
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .weekOfMonth, .month], from: takenTimestamp, to: dueDate)
        
        
        // Calculate total days for better unit selection
        let totalHours = (components.hour ?? 0) +
                        (components.day ?? 0) * 24 +
                        (components.weekOfMonth ?? 0) * 7 * 24 + 
                        (components.month ?? 0) * 30 * 24
        
        print("\(components)")
        
        // Select most appropriate unit
        if totalHours <= 48 {
            waitUnit = .hour
            waitValue = max(1, totalHours)
        } else if totalHours <= 180 * 24 {
            waitUnit = .day
            waitValue = max(1, totalHours / 24)
        } else if totalHours <= 52 * 7 * 24 {
            waitUnit = .weekOfMonth
            waitValue = max(1, totalHours / (7 * 24))
        } else {
            waitUnit = .month
            waitValue = max(1, totalHours / (30 * 24))
        }
        
        // Ensure value is within allowed range
        if waitValue > waitValueRange.upperBound {
            waitValue = waitValueRange.upperBound
        }
    }
    
    private func calculateWaitAndWatchPeriodInSeconds() -> Int {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: waitUnit, value: waitValue, to: takenTimestamp) ?? Date()
        return Int(endDate.timeIntervalSince(takenTimestamp))
    }
    
    private func saveRemedy() {
        let waitPeriodSeconds = calculateWaitAndWatchPeriodInSeconds()
        
        let newRemedy = Remedy(
            name: name,
            potency: potency,
            customPotency: potency == RemedyPotency.other.rawValue ? customPotency : nil,
            takenTimestamp: takenTimestamp,
            prescribedTimestamp: prescribedTimestamp,
            waitAndWatchPeriod: waitPeriodSeconds,
            effectivenessDueDate: effectivenessDueDate,
            notes: notes.isEmpty ? nil : notes,
            hasRecurrence: hasRecurrence,
            recurrenceRule: hasRecurrence ? recurrenceRule : nil,
            recurrenceFrequency: hasRecurrence && recurrenceRule == RecurrenceRule.multipleTimesPerDay.rawValue ? recurrenceFrequency : nil,
            recurrenceInterval: hasRecurrence && recurrenceRule == RecurrenceRule.multipleTimesPerDay.rawValue ? recurrenceInterval : nil,
            recurrenceEndDate: hasRecurrence ? recurrenceEndDate : nil
        )
        
        modelContext.insert(newRemedy)
        
        // Schedule notifications if remedy has recurrence
        if newRemedy.hasRecurrence {
            let notificationIdentifiers = NotificationManager.shared.scheduleRemedyNotifications(for: newRemedy)
            newRemedy.notificationIdentifiers = notificationIdentifiers
        }
        
        // Notify that a remedy was saved (for UI updates)
        NotificationCenter.default.post(name: NSNotification.Name("DidSaveRemedy"), object: nil)
        
        dismiss()
    }
}

#Preview {
    RemedyLogView()
} 
