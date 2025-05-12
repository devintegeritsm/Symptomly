//
//  SymptomRow.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftData
import SwiftUI

struct SymptomRow: View {
    let symptom: Symptom
    @Query private var allRemedies: [Remedy]
    
    var activeRemedies: [Remedy] {
        allRemedies.filter { remedy in
            remedy.isActiveAtDate(symptom.timestamp)
        }
        .prefix(3) // Limit to 3 remedies to avoid UI clutter
        .sorted { $0.takenTimestamp > $1.takenTimestamp }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(symptom.name)
                    .font(.headline)
                Spacer()
                Text(symptom.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                SeverityIndicator(severity: symptom.severityEnum)
                
                if symptom.isResolved, let resolutionDate = symptom.resolutionDate {
                    Text("Resolved \(resolutionDate.formatted(.dateTime.month().day().hour().minute()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let notes = symptom.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            if !activeRemedies.isEmpty {
                VStack(alignment: .leading) {
                    ForEach(activeRemedies) { remedy in
                        RemedyPill(remedy: remedy)
                    }
                    
                    if allRemedies.filter({ $0.isActiveAtDate(symptom.timestamp) }).count > 3 {
                        Text("+ more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}
