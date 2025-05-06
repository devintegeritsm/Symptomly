//
//  RemedyRow.swift
//  Symptomly
//
//  Created by Bastien Villefort on 6/19/25.
//

import SwiftUI

struct RemedyRow: View {
    let remedy: Remedy
    let isPlaceholder: Bool
    
    init(remedy: Remedy, isPlaceholder: Bool = false) {
        self.remedy = remedy
        self.isPlaceholder = isPlaceholder
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(remedy.name)
                        .font(.headline)
                    
                    Text("•")
                    
                    Text(remedy.displayPotency)
                        .font(.subheadline)
                }
                .opacity(isPlaceholder ? 0.6 : 1.0)
                
                HStack {
                    Text(formatTime(remedy.takenTimestamp))
                        .font(.caption)
                    
                    if remedy.hasRecurrence {
                        Image(systemName: "repeat")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                .opacity(isPlaceholder ? 0.4 : 0.8)
                
                if let notes = remedy.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .opacity(isPlaceholder ? 0.4 : 0.8)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if isPlaceholder {
                    Text("Future")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                } else if remedy.isActive {
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                } else {
                    Text("Ended")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Text("Until \(formatDate(remedy.effectivenessDueDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .opacity(isPlaceholder ? 0.6 : 1.0)
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
            
            Text("•")
                .font(.caption2)
            
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