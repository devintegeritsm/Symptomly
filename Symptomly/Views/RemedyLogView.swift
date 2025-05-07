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
            return 12...48
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
                        Text("Prescribed on:")
                        DatePicker("", selection: $prescribedTimestamp, displayedComponents: [.date])
                        .alignmentGuide(.trailing) { d in d[HorizontalAlignment.trailing] }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Taken on:")
                        DatePicker("", selection: $takenTimestamp, displayedComponents: [.date, .hourAndMinute])
                        .onChange(of: takenTimestamp) { _, _ in
                            updateEffectivenessDueDate()
                        }
                        .alignmentGuide(.trailing) { d in d[HorizontalAlignment.trailing] }
                    }
                }
                
                Section("Wait and Watch Period") {
                    VStack(alignment: .leading) {
                        Text("Duration:")
                        HStack {
                            Text("\(waitValue)")
                                .frame(width: 40, alignment: .trailing)
                            
                            Picker("", selection: $waitUnit) {
                                Text("Hours").tag(Calendar.Component.hour)
                                Text("Days").tag(Calendar.Component.day)
                                Text("Weeks").tag(Calendar.Component.weekOfMonth)
                                Text("Months").tag(Calendar.Component.month)
                            }
                            .pickerStyle(.menu)
                            .onChange(of: waitUnit) { _, newUnit in
                                // Adjust the wait value if switching to a unit where
                                // the current value exceeds the range
                                if waitValue > waitValueRange.upperBound {
                                    waitValue = waitValueRange.upperBound
                                }
                                updateEffectivenessDueDate()
                            }
                            .onChange(of: waitValue) { _, _ in
                                updateEffectivenessDueDate()
                            }
                            
                            Stepper(value: $waitValue, in: waitValueRange) { }
//                            .alignmentGuide(.trailing) { d in d[HorizontalAlignment.trailing] }
                        }
                        
                        
                    }
                    
                    DatePicker("Effectiveness due date:", selection: $effectivenessDueDate, displayedComponents: [.date])
                        .onChange(of: effectivenessDueDate) { _, newValue in
                            updateWaitAndWatchFromDueDate(newValue)
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
                        
                        DatePicker("End Repeat", selection: $recurrenceEndDate, displayedComponents: [.date])
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
        let calendar = Calendar.current
        effectivenessDueDate = calendar.date(byAdding: waitUnit, value: waitValue, to: takenTimestamp) ?? Date()
    }
    
    private func updateWaitAndWatchFromDueDate(_ dueDate: Date) {
        // This is a simplified approach - for real apps we'd calculate the exact difference
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .weekOfMonth, .month], from: takenTimestamp, to: dueDate)
        
        let days = (components.weekOfMonth ?? 0) * 7 + (components.month ?? 0) * 30 + (components.day ?? 0)
        if days > 0 {
            // Convert to hours for short durations
            if days <= 2 {
                waitValue = days * 24 + (components.hour ?? 0)
                waitUnit = .hour
            }
            // Use days for moderate durations
            else if days <= 180 {
                waitValue = days
                waitUnit = .day
            } 
            // Use weeks for longer durations
            else if days <= 364 {
                waitValue = days / 7
                waitUnit = .weekOfMonth
            } 
            // Use months for very long durations
            else {
                waitValue = days / 30
                waitUnit = .month
            }
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
