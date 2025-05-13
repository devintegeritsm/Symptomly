//
//  RemedyRow.swift
//  Symptomly
//
//  Created by Bastien Villefort on 6/19/25.
//

import SwiftUI

enum RemedyStatus {
    case waitAndWatch
    case repeatedSchedule
    case completed
}

struct RemedyRow: View {
    let remedy: Remedy
    let isPlaceholder: Bool
    let remedyStatus: RemedyStatus
    
    init(remedy: Remedy, isPlaceholder: Bool = false, remedyStatus: RemedyStatus = .completed) {
        self.remedy = remedy
        self.isPlaceholder = isPlaceholder
        self.remedyStatus = remedyStatus
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            
            HStack {
                Image(systemName: "flask").foregroundColor(.secondary)
                
                Text(remedy.name)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(remedy.displayPotency)
                    .font(.subheadline)
                    .foregroundColor(.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.teal.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                Text(formatDate(remedy.takenTimestamp))
                    .font(.caption)
            }
            .opacity(isPlaceholder ? 0.6 : 1.0)
            
            HStack {
                Text("Taken on")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                Text(Utils.formatDateTime(remedy.takenTimestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if remedy.hasRecurrence {
                HStack {
                    Image(systemName: "repeat")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .opacity(isPlaceholder ? 0.4 : 0.8)
            }
            
            if let notes = remedy.notes, !notes.isEmpty {
                HStack {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .opacity(isPlaceholder ? 0.4 : 0.8)
                }
                .foregroundColor(.secondary)
                .opacity(isPlaceholder ? 0.4 : 0.8)
            }
            
            HStack {
                if isPlaceholder {
                    Text("Future")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                } else {
                    switch remedyStatus {
                    case .waitAndWatch:
                        Text("Wait & Watch")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    case .repeatedSchedule:
                        Text("Repeating")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    case .completed:
                        Text("Completed")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Text("Until \(Utils.formatDateTime(remedy.effectivenessDueDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct RemedyPill: View {
    let remedy: Remedy
    
    var body: some View {
        HStack(spacing: 4) {
            Text(remedy.name)
                .font(.caption2)
                .fontWeight(.bold)
            
            Text("•").font(.caption2)
            
            Text(remedy.displayPotency)
                .font(.caption2)
            
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.teal.opacity(0.2))
        .foregroundColor(.teal)
        .cornerRadius(12)
    }
} 
