//
//  TimelineItem.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/18/25.
//

import Foundation
import SwiftUI


struct TimelineItem: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: ItemType
    let name: String
    let details: String
    let color: Color
    
    enum ItemType {
        case symptom
        case remedy
    }
}
