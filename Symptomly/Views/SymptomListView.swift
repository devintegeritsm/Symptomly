//
//  SymptomListView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI
import SwiftData

struct SymptomListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDate: Date
    @Query private var allSymptoms: [Symptom]
    
    @State private var symptomToResolve: Symptom?
    @State private var showResolutionDatePicker = false
    @State private var temporaryResolutionDate = Date()
    @State private var temporaryNotes: String = ""
    
    @State private var symptomToDelete: Symptom?
    @State private var showDeleteConfirmation = false
    
    var filteredSymptoms: [Symptom] {
        return allSymptoms.filter { symptom in
            Calendar.current.isDate(symptom.timestamp, inSameDayAs: selectedDate)
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        List {
            if filteredSymptoms.isEmpty {
                ContentUnavailableView(
                    "No Symptoms",
                    systemImage: "clipboard",
                    description: Text("You haven't logged any symptoms for this day.")
                )
            } else {
                ForEach(filteredSymptoms) { symptom in
                    SymptomRow(symptom: symptom)
                        .swipeActions(edge: .leading) {
                            if !symptom.isResolved {
                                Button {
                                    symptomToResolve = symptom
                                    temporaryResolutionDate = Date()
                                    temporaryNotes = symptom.notes ?? ""
                                    showResolutionDatePicker = true
                                } label: {
                                    Label("Mark Resolved", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            } else {
                                Button {
                                    toggleResolvedStatus(for: symptom)
                                } label: {
                                    Label("Mark Active", systemImage: "exclamationmark.circle")
                                }
                                .tint(.orange)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                symptomToDelete = symptom
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            NavigationLink {
                                SymptomDetailView(symptom: symptom)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .sheet(isPresented: $showResolutionDatePicker) {
            ResolutionDatePickerView(
                resolutionDate: $temporaryResolutionDate,
                notes: $temporaryNotes,
                onSave: {
                    if let symptom = symptomToResolve {
                        markAsResolved(
                            symptom: symptom, 
                            resolutionDate: temporaryResolutionDate, 
                            notes: temporaryNotes.isEmpty ? nil : temporaryNotes
                        )
                        symptomToResolve = nil
                    }
                    showResolutionDatePicker = false
                },
                onCancel: {
                    symptomToResolve = nil
                    showResolutionDatePicker = false
                }
            )
        }
        .alert("Delete Symptom", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                symptomToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let symptom = symptomToDelete {
                    deleteSymptom(symptom)
                    symptomToDelete = nil
                }
            }
        } message: {
            if let symptom = symptomToDelete {
                Text("Are you sure you want to delete '\(symptom.name)'? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this symptom? This action cannot be undone.")
            }
        }
    }
    
    private func markAsResolved(symptom: Symptom, resolutionDate: Date, notes: String?) {
        symptom.severity = Severity.resolved.rawValue
        symptom.resolutionDate = resolutionDate
        symptom.notes = notes
    }
    
    private func toggleResolvedStatus(for symptom: Symptom) {
        if symptom.isResolved {
            // Mark as active with mild severity
            symptom.severity = Severity.mild.rawValue
            symptom.resolutionDate = nil
        } else {
            // This case should not be reached directly as we now use the sheet
            symptomToResolve = symptom
            temporaryResolutionDate = Date()
            temporaryNotes = symptom.notes ?? ""
            showResolutionDatePicker = true
        }
    }
    
    private func deleteSymptom(_ symptom: Symptom) {
        modelContext.delete(symptom)
    }
}

struct ResolutionDatePickerView: View {
    @Binding var resolutionDate: Date
    @Binding var notes: String
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Resolution Date") {
                    CustomDatePicker(selection: $resolutionDate, includeTime: true)
                }
                
                Section("Resolution Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                    
                    if notes.isEmpty {
                        Text("Add any notes about how this symptom was resolved")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Symptom Resolution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
