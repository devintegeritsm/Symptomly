//
//  Symptom.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Symptom {
    var name: String
    var severity: Int
    var timestamp: Date
    var notes: String?
    
    init(name: String, severity: Int, timestamp: Date = Date(), notes: String? = nil) {
        self.name = name
        self.severity = severity
        self.timestamp = timestamp
        self.notes = notes

    }
    
    var severityEnum: Severity {
        return Severity(rawValue: self.severity) ?? .mild
    }
    
    var isResolved: Bool {
        return self.severityEnum == .resolved
    }
} 
