//
//  Severity.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import Foundation
import SwiftUI

enum Severity: Int, Codable, CaseIterable {
    case mild = 1
    case moderate = 2
    case severe = 3
    case verySevere = 4
    case extreme = 5
    
    var displayName: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .verySevere: return "Very Severe"
        case .extreme: return "Extreme"
        }
    }
    
    var color: Color {
        switch self {
        case .mild: return .green
        case .moderate: return .yellow
        case .severe: return .orange
        case .verySevere: return .red
        case .extreme: return .purple
        }
    }
} 