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
    @State private var timestamp: Date = Date()
    @State private var showSuggestions: Bool = false
    @State private var filteredSuggestions: [String] = []
    


    
    var body: some View {
        NavigationStack {
            Form {
                Section("Symptom Name") {
                    TextField("Enter symptom name", text: $name)
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
                                // Optionally, dismiss keyboard here if desired
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }) {
                                Text(suggestion)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading) // Make tappable area wider
                            }
                            .buttonStyle(.plain) // Often good for list-like buttons
                        }
                        .padding(.vertical, 4)
                        .transition(.opacity.combined(with: .move(edge: .top))) // Optional: add a transition
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
//                            .labelsHidden()
                            .alignmentGuide(.trailing) { d in d[HorizontalAlignment.trailing] }
                    }
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
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
    }
    

    
    private func updateSuggestions(query: String) {
        
//        let uniqueSymptomNames = Set(existingSymptoms.map { $0.name })
//        filteredSuggestions = Array(uniqueSymptomNames).filter { 
//            $0.lowercased().contains(query.lowercased()) && $0 != query 
//        }
        
        let lowercasedQuery = query.lowercased()
        // Fetch unique names once or efficiently if this list changes frequently
        let uniqueSymptomNames = Set(existingSymptoms.map { $0.name })
        // Filter more efficiently
        // Also, ensure the query itself isn't immediately shown as a suggestion if it's a full match
        // unless that's desired behavior.
        filteredSuggestions = Array(uniqueSymptomNames).filter {
            $0.lowercased().contains(lowercasedQuery) && $0.lowercased() != lowercasedQuery
        }.sorted() // Optional: sort suggestions
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


