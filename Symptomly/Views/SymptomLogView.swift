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
    @State private var showSuggestions: Bool = false
    @State private var skipSuggestions: Bool = false
    @State private var filteredSuggestions: [String] = []
    @State private var dicCompletions: [String] = []
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
                                
                                if !dicCompletions.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Dictionary suggestions:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        FlowLayout(spacing: 8) {
                                            ForEach(dicCompletions, id: \.self) { suggestion in
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
                
                Section("Severity") {
                    Picker("Severity", selection: $severity) {
                        ForEach(Severity.allCases, id: \.rawValue) { severityLevel in
                            Text(severityLevel.displayName).tag(severityLevel.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("When did it occur?") {
                    VStack(alignment: .leading) {
                        Text("Time:")
                        DatePicker("", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                            .alignmentGuide(.trailing) { d in d[HorizontalAlignment.trailing] }
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSymptom()
                    }
                    .disabled(name.isEmpty)
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
        
        let textChecker = UITextChecker()
        let nsString = query as NSString
        let wordRange = NSRange(location: 0, length: nsString.length)
        let preferredLanguage = Locale.preferredLanguages.first ?? "en_US"
//        let completions = textChecker.completions(forPartialWordRange: wordRange, in: query, language: "en_US") ?? []
        let completions = textChecker.guesses(forWordRange: wordRange, in: query, language: preferredLanguage) ?? []
        if !completions.isEmpty {
            let suggestionsSet = Set(filteredSuggestions)
            dicCompletions = completions.filter { !suggestionsSet.contains($0) }
            showSuggestions = showSuggestions || !dicCompletions.isEmpty
        }
    }
    
    private func saveSymptom() {
        let newSymptom = Symptom(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            severity: severity,
            timestamp: timestamp,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Ensure name is not empty after trimming
        guard !newSymptom.name.isEmpty else {
            // Optionally show an alert to the user
            print("Symptom name cannot be empty after trimming.")
            return
        }
        
        modelContext.insert(newSymptom)
        
        dismiss()
    }
    
    
}




