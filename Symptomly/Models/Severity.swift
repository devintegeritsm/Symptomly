//
//  Severity.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import Foundation
import SwiftUI

enum Severity: Int, Codable, CaseIterable, Identifiable {
    case resolved = 0
    case mild = 1
    case moderate = 2
    case severe = 3
    case extreme = 4
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .resolved: return "Resolved"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .extreme: return "Extreme"
        }
    }
    
    var color: Color {
        switch self {
        case .resolved: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        case .extreme: return .purple
        }
    }
} 
