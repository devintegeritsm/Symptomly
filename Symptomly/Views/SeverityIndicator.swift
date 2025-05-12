//
//  SeverityIndicator.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI


struct SeverityIndicator: View {
    let severity: Severity
    
    var body: some View {
        HStack(spacing: 4) {
            if severity == .resolved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(severity.color)
                    .font(.caption)
            } else {
                ForEach(1...Severity.allCases.count - 1, id: \.self) { level in
                    Circle()
                        .fill(level <= severity.rawValue ? severity.color : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(severity.displayName)
                .font(.caption)
                .foregroundColor(severity.color)
        }
    }
} 
