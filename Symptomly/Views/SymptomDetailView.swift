//
//  SymptomDetailView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUICore
import SwiftUI


struct SymptomDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var symptom: Symptom
    
    @State private var name: String
    @State private var severity: Int
    @State private var notes: String
    @State private var timestamp: Date
    
    init(symptom: Symptom) {
        self.symptom = symptom
        _name = State(initialValue: symptom.name)
        _severity = State(initialValue: symptom.severity)
        _notes = State(initialValue: symptom.notes ?? "")
        _timestamp = State(initialValue: symptom.timestamp)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Symptom Name") {
                    TextField("Enter symptom name", text: $name)
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
                    DatePicker("Time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Symptom")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateSymptom()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func updateSymptom() {
        symptom.name = name
        symptom.severity = severity
        symptom.timestamp = timestamp
        symptom.notes = notes.isEmpty ? nil : notes
        
        dismiss()
    }
}
