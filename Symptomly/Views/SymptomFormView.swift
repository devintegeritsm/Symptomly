//
//  SymptomFormView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI
import SwiftData

struct SymptomFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Mode of operation
    enum Mode {
        case create
        case edit(Symptom)
    }
    
    let mode: Mode
    
    // Optional symptom (only used in edit mode)
    private var symptom: Symptom? {
        if case .edit(let symptom) = mode {
            return symptom
        }
        return nil
    }
    
    @State private var name: String = ""
    @State private var severity: Int = 2  // Default to moderate
    @State private var notes: String = ""
    @State private var timestamp: Date
    @State private var isResolved: Bool = false
    @State private var resolutionDate: Date = Date()
    @State private var showResolutionDatePicker: Bool = false
    @State private var showSuggestions: Bool = false
    @State private var skipSuggestions: Bool = false
    @State private var filteredSuggestions: [String] = []
    @State private var dictionaryCompletions: [String] = []
    @FocusState private var isNameFieldFocused: Bool
    
    @Query private var existingSymptoms: [Symptom]
    @Query private var allRemedies: [Remedy]
    
    var activeRemedies: [Remedy] {
        allRemedies.filter { remedy in
            remedy.isActiveAtDate(timestamp)
        }
        .sorted { $0.takenTimestamp > $1.takenTimestamp }
    }
    
    // Initialize with a create mode and optional selected date
    init(selectedDate: Date = Date()) {
        self.mode = .create
        
        // Set up the timestamp for a new symptom
        let calendar = Calendar.current
        let now = Date()
        
        // Combine the selected date with the current time
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        
        let combinedDate = calendar.date(from: components) ?? now
        _timestamp = State(initialValue: combinedDate)
    }
    
    // Initialize with an existing symptom for editing
    init(symptom: Symptom) {
        self.mode = .edit(symptom)
        
        _name = State(initialValue: symptom.name)
        _severity = State(initialValue: symptom.severity)
        _notes = State(initialValue: symptom.notes ?? "")
        _timestamp = State(initialValue: symptom.timestamp)
        _isResolved = State(initialValue: symptom.severityEnum == .resolved)
        _resolutionDate = State(initialValue: symptom.resolutionDate ?? Date())
    }
    
    var navigationTitle: String {
        switch mode {
        case .create:
            return "Log Symptom"
        case .edit:
            return "Edit Symptom"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Symptom Name") {
                    TextField("Enter symptom name", text: $name)
                        .focused($isNameFieldFocused)
                        .onChange(of: name) { _, newValue in
                            if !newValue.isEmpty {
                                if skipSuggestions {
                                    skipSuggestions = false
                                    return
                                }
                                updateSuggestions(query: newValue)
                            } else {
                                showSuggestions = false
                            }
                        }
                        .autocorrectionDisabled(true)
                    
                    if showSuggestions {
                        VStack(alignment: .leading) {
                            ScrollView {
                                if !filteredSuggestions.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Previously used symptoms:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        FlowLayout(spacing: 8) {
                                            ForEach(filteredSuggestions, id: \.self) { suggestion in
                                                Button(action: {
                                                    name = suggestion
                                                    showSuggestions = false
                                                    skipSuggestions = true
                                                    hideKeyboard()
                                                }) {
                                                    Text(suggestion)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Color.accentColor.opacity(0.1))
                                                        .foregroundColor(.accentColor)
                                                        .cornerRadius(16)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 16)
                                                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                                        )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                                
                                if !dictionaryCompletions.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Dictionary suggestions:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        FlowLayout(spacing: 8) {
                                            ForEach(dictionaryCompletions, id: \.self) { suggestion in
                                                Button(action: {
                                                    name = suggestion
                                                    showSuggestions = false
                                                    skipSuggestions = true
                                                    hideKeyboard()
                                                }) {
                                                    Text(suggestion)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut, value: showSuggestions)
                    }
                }
                
                Section {
                    Toggle("Mark as resolved", isOn: $isResolved)
                        .onChange(of: isResolved) { oldValue, newValue in
                            if newValue {
                                severity = Severity.resolved.rawValue
                                // Only set resolution date to now if not previously resolved
                                if !oldValue {
                                    resolutionDate = Date()
                                    showResolutionDatePicker = true
                                }
                            } else {
                                severity = Severity.mild.rawValue
                            }
                        }
                    
                    if isResolved {
                        Button(action: {
                            showResolutionDatePicker.toggle()
                        }) {
                            HStack {
                                Text("Resolution Date")
                                Spacer()
                                Text(resolutionDate.formatted(.dateTime.month().day().hour().minute()))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showResolutionDatePicker {
                            CustomDatePicker(selection: $resolutionDate, includeTime: true)
                        }
                    }
                }
                
                if !isResolved {
                    Section("Severity") {
                        Picker("Severity", selection: $severity) {
                            ForEach(Array(Severity.allCases.filter { $0 != .resolved }), id: \.rawValue) { severityLevel in
                                Text(severityLevel.displayName).tag(severityLevel.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // Only show severity indicator in edit mode
                        if case .edit = mode {
                            HStack {
                                SeverityIndicator(severity: Severity(rawValue: severity) ?? .mild)
                                Spacer()
                            }
                        }
                    }
                    
                    Section("When did it occur?") {
                        VStack(alignment: .leading) {
                            HStack {
                                if case .edit = mode {
                                    Image(systemName: "calendar").foregroundColor(.secondary)
                                }
                                Text("Time:")
                            }
                            CustomDatePicker(selection: $timestamp, includeTime: true)
                        }
                    }
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                if !activeRemedies.isEmpty {
                    Section("Active Remedies") {
                        ForEach(activeRemedies) { remedy in
                            NavigationLink(destination: RemedyFormView(remedy: remedy)) {
                                VStack(alignment: .leading) {
                                    HStack(spacing: 4) {
                                        Text(remedy.name)
                                            .fontWeight(.medium)
                                        
                                        Text("•")
                                        
                                        Text(remedy.displayPotency)
                                    }
                                    HStack(spacing: 4) {
                                        Text("Taken \(Utils.formatTimeAgo(from: remedy.takenTimestamp))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        switch mode {
                        case .create:
                            saveNewSymptom()
                        case .edit:
                            updateExistingSymptom()
                        }
                    }
                    .disabled(name.isEmpty)
                }
                
                // Only show delete button in edit mode
                if case .edit = mode {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            deleteSymptom()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .onAppear {
            // Automatically focus the field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isNameFieldFocused = true
            }
        }
    }
    
    private func updateSuggestions(query: String) {
        let lowercasedQuery = query.lowercased()
        // Fetch unique names once or efficiently if this list changes frequently
        let uniqueSymptomNames = Set(existingSymptoms.map { $0.name })
        // Filter more efficiently
        // Also, ensure the query itself isn't immediately shown as a suggestion if it's a full match
        // unless that's desired behavior.
        filteredSuggestions = Array(uniqueSymptomNames).filter {
            $0.lowercased().contains(lowercasedQuery) && $0.lowercased() != lowercasedQuery
        }.sorted()
        showSuggestions = !filteredSuggestions.isEmpty
        
        // Get completions only for the last word in the query
        if let lastWord = query.components(separatedBy: .whitespacesAndNewlines).last, !lastWord.isEmpty {
            let textChecker = UITextChecker()
            let nsString = lastWord as NSString
            let wordRange = NSRange(location: 0, length: nsString.length)
            let preferredLanguage = Locale.preferredLanguages.first ?? "en_US"
            let completions = textChecker.completions(forPartialWordRange: wordRange, in: lastWord, language: preferredLanguage) ?? []
            
            if !completions.isEmpty {
                let suggestionsSet = Set(filteredSuggestions)
                // Get the prefix of the query without the last word
                let prefix = query.dropLast(lastWord.count).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Create full suggestions by combining prefix with completions
                dictionaryCompletions = completions.map { completion in
                    prefix.isEmpty ? completion : "\(prefix) \(completion)"
                }
                .filter { !suggestionsSet.contains($0) }
                .filter { $0 != query }
                
                dictionaryCompletions = Array(dictionaryCompletions.prefix(5))
                
                showSuggestions = showSuggestions || !dictionaryCompletions.isEmpty
            } else {
                dictionaryCompletions = []
            }
        } else {
            dictionaryCompletions = []
        }
    }
    
    private func hideKeyboard() {
        Utils.hideKeyboard()
    }
    
    private func saveNewSymptom() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolutionDateValue = isResolved ? resolutionDate : nil
        let newSymptom = Symptom(
            name: trimmedName,
            severity: severity,
            timestamp: timestamp,
            notes: notes.isEmpty ? nil : notes,
            resolutionDate: resolutionDateValue
        )
        
        modelContext.insert(newSymptom)
        dismiss()
    }
    
    private func updateExistingSymptom() {
        guard let symptom = self.symptom else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        symptom.name = trimmedName
        symptom.severity = severity
        symptom.timestamp = timestamp
        symptom.notes = notes.isEmpty ? nil : notes
        
        // Update resolution date only if symptom is resolved
        if isResolved {
            symptom.resolutionDate = resolutionDate
        } else {
            symptom.resolutionDate = nil
        }
        
        dismiss()
    }
    
    private func deleteSymptom() {
        if case .edit(let symptom) = mode {
            modelContext.delete(symptom)
            dismiss()
        }
    }
} 