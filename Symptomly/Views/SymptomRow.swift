//
//  SymptomLogView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUICore

struct SymptomRow: View {
    let symptom: Symptom
    
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
                
                if let notes = symptom.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
