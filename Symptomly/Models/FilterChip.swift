//
//  FilterChip.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/18/25.
//

import SwiftUI


// Filter chip for the search UI
struct FilterChip: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.footnote)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color(.systemGray5))
                )
        }
    }
}
