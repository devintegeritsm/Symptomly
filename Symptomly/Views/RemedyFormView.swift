//
//  RemedyFormView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 6/19/25.
//

import SwiftUI
import SwiftData

struct RemedyFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingRemedies: [Remedy]
    
    // Configuration for the view's behavior
    let mode: ViewMode
    let remedy: Remedy?
    
    // Form fields
    @State private var name: String
    @State private var potency: String
    @State private var customPotency: String
    @State private var takenTimestamp: Date
    @State private var prescribedTimestamp: Date
    @State private var notes: String
    
    // Wait and watch settings
    @State private var waitValue: Int
    @State private var waitUnit: Calendar.Component
    @State private var effectivenessDueDate: Date
    @State private var stepperDate: Date
    @State private var dueDateUpdated: Bool = false
    @State private var waitUnitUpdated: Bool = false
    
    // Recurrence properties
    @State private var hasRecurrence: Bool
    @State private var recurrenceRule: String
    @State private var recurrenceFrequency: Int
    @State private var recurrenceInterval: Int
    @State private var recurrenceEndDate: Date
    
    // UI state
    @State private var showSuggestions: Bool = false
    @State private var filteredSuggestions: [String] = []
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
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
    
    // View mode enum for configuring the view
    enum ViewMode {
        case create
        case edit
    }
    
    // Initialize for creating a new remedy
    init() {
        self.mode = .create
        self.remedy = nil
        
        // Initialize with default values
        _name = State(initialValue: "")
        _potency = State(initialValue: RemedyPotency.potency30C.rawValue)
        _customPotency = State(initialValue: "")
        _takenTimestamp = State(initialValue: Date())
        _prescribedTimestamp = State(initialValue: Date())
        _notes = State(initialValue: "")
        
        // Wait and watch defaults
        _waitValue = State(initialValue: 1)
        _waitUnit = State(initialValue: .weekOfMonth)
        _effectivenessDueDate = State(initialValue: Calendar.current.date(byAdding: .weekOfMonth, value: 1, to: Date()) ?? Date())
        _stepperDate = State(initialValue: Date())
        
        // Recurrence defaults
        _hasRecurrence = State(initialValue: false)
        _recurrenceRule = State(initialValue: RecurrenceRule.daily.rawValue)
        _recurrenceFrequency = State(initialValue: 2)
        _recurrenceInterval = State(initialValue: 12)
        _recurrenceEndDate = State(initialValue: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
        
        // Default to editing mode since we're creating
        _isEditing = State(initialValue: true)
    }
    
    // Initialize for viewing/editing an existing remedy
    init(remedy: Remedy, mode: ViewMode = .edit) {
        self.mode = mode
        self.remedy = remedy
        
        // Initialize state from the remedy
        _name = State(initialValue: remedy.name)
        _potency = State(initialValue: remedy.potency)
        _customPotency = State(initialValue: remedy.customPotency ?? "")
        _takenTimestamp = State(initialValue: remedy.takenTimestamp)
        _prescribedTimestamp = State(initialValue: remedy.prescribedTimestamp)
        _effectivenessDueDate = State(initialValue: remedy.effectivenessDueDate)
        _notes = State(initialValue: remedy.notes ?? "")
        
        // Calculate wait and watch values from the remedy
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .weekOfMonth, .month], 
                                              from: remedy.takenTimestamp, 
                                              to: remedy.effectivenessDueDate)
        
        // Calculate total hours for better unit selection
        let totalHours = (components.hour ?? 0) +
                        (components.day ?? 0) * 24 +
                        (components.weekOfMonth ?? 0) * 7 * 24 + 
                        (components.month ?? 0) * 30 * 24
                        
        // Select most appropriate unit
        var waitUnit: Calendar.Component = .hour
        var waitValue: Int = 1
        
        if totalHours <= 72 {
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
        
        _waitValue = State(initialValue: waitValue)
        _waitUnit = State(initialValue: waitUnit)
        _stepperDate = State(initialValue: remedy.effectivenessDueDate)
        
        // Recurrence properties
        _hasRecurrence = State(initialValue: remedy.hasRecurrence)
        _recurrenceRule = State(initialValue: remedy.recurrenceRule ?? RecurrenceRule.daily.rawValue)
        _recurrenceFrequency = State(initialValue: remedy.recurrenceFrequency ?? 2)
        _recurrenceInterval = State(initialValue: remedy.recurrenceInterval ?? 12)
        _recurrenceEndDate = State(initialValue: remedy.recurrenceEndDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60))
        
        _isEditing = State(initialValue: mode == .edit)
    }
    
    var body: some View {
        let content = Group {
            editFormView
        }
        
        if mode == .create {
            NavigationStack {
                content
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
            }
            .backgroundStyle(.thickMaterial)
        } else {
            content
                .navigationTitle("Edit Remedy")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                            Button("Save") {
                                saveChanges()
                                isEditing = false
                            }
                            .disabled(name.isEmpty || (potency == RemedyPotency.other.rawValue && customPotency.isEmpty))
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
    
    // MARK: - Edit Form View
    
    private var editFormView: some View {
        Form {
            Section("Remedy Information") {
                TextField("Enter remedy name", text: $name)
                    .autocorrectionDisabled(true)
                    .onChange(of: name) { _, newValue in
                        if !newValue.isEmpty && mode == .create {
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
                            if !waitUnitUpdated {
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
                            } else {
                                waitUnitUpdated = false
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
        .onAppear {
            if mode == .create {
                // Set default wait and watch period based on selected potency
                updateDefaultWaitPeriod()
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
            waitUnitUpdated = true;
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        return Utils.formatDateTime(date)
    }
    
    // MARK: - Save, Update and Delete Methods
    
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
    
    private func saveChanges() {
        guard let remedy = remedy else { return }
        
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
        guard let remedy = remedy else { return }
        
        // Cancel notifications before deletion
        NotificationManager.shared.cancelNotifications(identifiers: remedy.notificationIdentifiers)
        
        modelContext.delete(remedy)
        
        // Notify that a remedy was deleted
        NotificationCenter.default.post(name: NSNotification.Name("DidDeleteRemedy"), object: nil)
        
        dismiss()
    }
}

#Preview("Create") {
    RemedyFormView()
}

#Preview("Edit") {
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
        RemedyFormView(remedy: sampleRemedy, mode: .edit)
    }
    .modelContainer(container)
} 
