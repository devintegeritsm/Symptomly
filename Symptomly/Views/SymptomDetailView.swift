//
//  SymptomDetailView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI
import SwiftData

struct SymptomDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var symptom: Symptom
    
    @State private var name: String
    @State private var severity: Int
    @State private var notes: String
    @State private var timestamp: Date
    
    @Query private var allRemedies: [Remedy]
    
    var activeRemedies: [Remedy] {
        allRemedies.filter { remedy in
            remedy.isActiveAtDate(symptom.timestamp)
        }
        .sorted { $0.takenTimestamp > $1.takenTimestamp }
    }
    
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
                    
                    HStack {
                        SeverityIndicator(severity: Severity(rawValue: severity) ?? .mild)
                        Spacer()
                    }
                }
                
                Section("When did it occur?") {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.secondary)
                            Text("Time:")
                        }
                    }
                    DatePicker("", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                        .alignmentGuide(.trailing) { d in d[HorizontalAlignment.trailing] }
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
                                        Text(remedy.name).fontWeight(.medium)
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
                
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        deleteSymptom()
                    } label: {
                        Image(systemName: "trash")
                    }
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
    
    private func deleteSymptom() {
        modelContext.delete(symptom)
        dismiss()
    }
}
