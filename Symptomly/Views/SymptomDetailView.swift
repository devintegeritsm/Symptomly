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
    @State private var isResolved: Bool
    @State private var resolutionDate: Date
    @State private var showResolutionDatePicker: Bool = false
    
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
        _isResolved = State(initialValue: symptom.severityEnum == .resolved)
        _resolutionDate = State(initialValue: symptom.resolutionDate ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Symptom Name") {
                    TextField("Enter symptom name", text: $name)
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
        
        // Update resolution date only if symptom is resolved
        if isResolved {
            symptom.resolutionDate = resolutionDate
        } else {
            symptom.resolutionDate = nil
        }
        
        dismiss()
    }
    
    private func deleteSymptom() {
        modelContext.delete(symptom)
        dismiss()
    }
}
