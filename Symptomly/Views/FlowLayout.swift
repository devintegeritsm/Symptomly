//
//  FlowLayout.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/8/25.
//

import SwiftUI
import SwiftData

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 10) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for size in sizes {
            let spacingNeeded = rowWidth > 0 ? spacing : 0
            
            if rowWidth + spacingNeeded + size.width > maxWidth {
                // Start a new row
                height += rowHeight + (height > 0 ? spacing : 0)
                rowWidth = size.width
                rowHeight = size.height
            } else {
                // Add to current row
                rowWidth += spacingNeeded + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        
        // Add the last row
        height += rowHeight
        
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var rowOriginY: CGFloat = bounds.minY
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            var spacingNeeded = rowWidth > 0 ? spacing : 0
            
            if rowWidth + spacingNeeded + size.width > bounds.width {
                // Start a new row
                rowOriginY += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
                spacingNeeded = 0  // No spacing needed for first item in new row
            }
            
            let point = CGPoint(
                x: bounds.minX + rowWidth + spacingNeeded,
                y: rowOriginY
            )
            
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
            
            rowWidth += spacingNeeded + size.width
            rowHeight = max(rowHeight, size.height)
        }
    }
}
