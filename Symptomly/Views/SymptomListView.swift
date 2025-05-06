//
//  SymptomListView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUICore
import SwiftUI
import _SwiftData_SwiftUI

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
                        .swipeActions {
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
    
    private func deleteSymptom(_ symptom: Symptom) {
        modelContext.delete(symptom)
    }
}
