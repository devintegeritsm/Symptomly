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
    let isRecentlyResolved: Bool
    let resolutionTimestamp: Date?
    var onResolutionTap: ((Date) -> Void)?
    @Query private var allRemedies: [Remedy]
    
    init(symptom: Symptom, 
         isRecentlyResolved: Bool = false, 
         resolutionTimestamp: Date? = nil,
         onResolutionTap: ((Date) -> Void)? = nil) {
        self.symptom = symptom
        self.isRecentlyResolved = isRecentlyResolved
        self.resolutionTimestamp = resolutionTimestamp
        self.onResolutionTap = onResolutionTap
    }
    
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
                Image(systemName: "thermometer.medium").foregroundColor(.secondary)
                Text(symptom.name)
                    .font(.headline)
                if isRecentlyResolved && !symptom.isResolved {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                        .font(.caption)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let resolutionTime = resolutionTimestamp, let onTap = onResolutionTap {
                                onTap(resolutionTime)
                            }
                        }
                }
                Spacer()
                Text(symptom.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            SeverityIndicator(severity: symptom.severityEnum)
            
            if let notes = symptom.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if isRecentlyResolved && !symptom.isResolved, let resolutionTime = resolutionTimestamp {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.green)
                    if Calendar.current.isDate(resolutionTime, inSameDayAs: symptom.timestamp) {
                        Text("Resolved on the same day")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("Resolved on: \(resolutionTime, format: .dateTime.month().day().hour().minute())")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.green.opacity(0.7))
                    }
                }
                .padding(5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.green.opacity(0.1))
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if let onTap = onResolutionTap {
                        onTap(resolutionTime)
                    }
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
