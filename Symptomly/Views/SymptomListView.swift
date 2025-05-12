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
                                    toggleResolvedStatus(for: symptom)
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
                                deleteSymptom(symptom)
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
    }
    
    private func toggleResolvedStatus(for symptom: Symptom) {
        if symptom.isResolved {
            // Mark as active with mild severity
            symptom.severity = Severity.mild.rawValue
            symptom.resolutionDate = nil
        } else {
            // Mark as resolved
            symptom.severity = Severity.resolved.rawValue
            symptom.resolutionDate = Date()
        }
    }
    
    private func deleteSymptom(_ symptom: Symptom) {
        modelContext.delete(symptom)
    }
}
