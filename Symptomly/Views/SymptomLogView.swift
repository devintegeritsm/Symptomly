//
//  SymptomLogView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI
import SwiftData

struct SymptomLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingSymptoms: [Symptom]
    
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
    
    @Query private var allRemedies: [Remedy]
    
    // Initialize with a selected date but keep the current time
    init(selectedDate: Date = Date()) {
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
    
    var activeRemedies: [Remedy] {
        allRemedies.filter { remedy in
            remedy.isActiveAtDate(timestamp)
        }
        .sorted { $0.takenTimestamp > $1.takenTimestamp }
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
                                resolutionDate = Date()
                                showResolutionDatePicker = true
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
                    }
                    
                    Section("When did it occur?") {
                        VStack(alignment: .leading) {
                            Text("Time:")
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
                            NavigationLink(destination: RemedyDetailView(remedy: remedy)) {
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
            .navigationTitle("Log Symptom")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveSymptom()
                    }
                    .disabled(name.isEmpty)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            // For dismissing keyboard when tapping outside, you might need this on a scrollable container or the Form
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
    
    private func saveSymptom() {
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
    
    
}




