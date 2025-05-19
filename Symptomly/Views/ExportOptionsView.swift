//
//  ExportOptionsView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/18/25.
//

import Foundation
import SwiftUI


struct ExportOptionsView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss
    let onExport: (Date, Date) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Timeline")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Date Range:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 16) {
                        DatePicker("From", selection: $startDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                        
                        DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                Button(action: {
                    onExport(startDate, endDate)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Timeline")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
