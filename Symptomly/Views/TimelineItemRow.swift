//
//  TimelineItemRow.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/18/25.
//

import SwiftUICore


struct TimelineItemRow: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column for time
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(item.timestamp))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formatTime(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 75)
            
            // Center vertical line with dot
            VStack(spacing: 0) {
                Circle()
                    .fill(item.color)
                    .frame(width: 10, height: 10)
                
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            
            // Right column with content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: item.type == .symptom ? "thermometer.medium" : "flask")
                        .foregroundColor(item.color)
                    
                    Text(item.type == .symptom ? "Symptom" : "Remedy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                }
                
                Text(item.name)
                    .font(.headline)
                
                if item.type == .symptom {
                    // Show severity indicator for symptoms using dots
                    let severity = getSeverityFromDetails(item.details)
                    SeverityIndicator(severity: severity)
                    
                    if let notes = extractNotes(from: item.details), !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    // For remedies, keep showing the original details
                    Text(item.details)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // Function to extract severity from the details string
    private func getSeverityFromDetails(_ details: String) -> Severity {
        if details.contains("Resolved") {
            return .resolved
        }
        
        // Expected format: "Severity: X - Notes"
        let components = details.split(separator: ":")
        if components.count >= 2, let severityString = components[safe: 1]?.split(separator: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines) {
            switch severityString {
            case "Mild": return .mild
            case "Moderate": return .moderate
            case "Severe": return .severe
            case "Extreme": return .extreme
            default: return .mild
            }
        }
        
        return .mild // Default to mild if parsing fails
    }
    
    // Function to extract notes from the details
    private func extractNotes(from details: String) -> String? {
        // Expected format for symptoms: "Severity: X - Notes" or "Resolved - Notes"
        if details.contains(" - ") {
            let components = details.split(separator: " - ", maxSplits: 1)
            if components.count > 1 {
                return String(components[1])
            }
        }
        return nil
    }
}
