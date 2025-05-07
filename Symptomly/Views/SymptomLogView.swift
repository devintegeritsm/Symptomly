//
//  SymptomLogView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUICore
import SwiftUI
import _SwiftData_SwiftUI

struct SymptomLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingSymptoms: [Symptom]
    
    @State private var name: String = ""
    @State private var severity: Int = 3  // Default to moderate
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
                            }) {
                                Text(suggestion)
                            }
                        }
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
                        .scaledToFit()
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
        }
    }
    
    private func updateSuggestions(query: String) {
        let uniqueSymptomNames = Set(existingSymptoms.map { $0.name })
        filteredSuggestions = Array(uniqueSymptomNames).filter { 
            $0.lowercased().contains(query.lowercased()) && $0 != query 
        }
    }
    
    private func saveSymptom() {
        let newSymptom = Symptom(
            name: name,
            severity: severity,
            timestamp: timestamp,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(newSymptom)
        
        dismiss()
    }
}
