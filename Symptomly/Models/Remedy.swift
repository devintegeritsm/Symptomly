//
//  Remedy.swift
//  Symptomly
//
//  Created by Bastien Villefort on 6/19/25.
//

import Foundation
import SwiftData
import SwiftUI

enum RemedyPotency: String, Codable, CaseIterable {
    case potency6C = "6C"
    case potency30C = "30C"
    case potency200C = "200C"
    case potency1M = "1M"
    case other = "Other"
    
    var defaultWaitPeriod: (value: Int, unit: Calendar.Component) {
        switch self {
        case .potency6C:
            return (1, .day)
        case .potency30C:
            return (1, .weekOfMonth)
        case .potency200C:
            return (1, .month)
        case .potency1M:
            return (2, .month)
        case .other:
            return (1, .weekOfMonth) // Default for custom potency
        }
    }
}

enum RecurrenceRule: String, Codable, CaseIterable {
    case daily = "Daily"
    case multipleTimesPerDay = "Multiple times per day"
    case everyOtherDay = "Every other day"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
}

@Model
final class Remedy {
    var name: String
    var potency: String
    var customPotency: String?
    var takenTimestamp: Date
    var prescribedTimestamp: Date
    var waitAndWatchPeriod: Int // Stored in seconds for flexibility
    var effectivenessDueDate: Date
    var notes: String?
    
    // Recurrence properties
    var hasRecurrence: Bool
    var recurrenceRule: String?
    var recurrenceFrequency: Int? // For multiple times per day
    var recurrenceInterval: Int? // For multiple times per day
    var recurrenceEndDate: Date?
    
    var notificationIdentifiers: [String] = []
    
    init(name: String, 
         potency: String, 
         customPotency: String? = nil,
         takenTimestamp: Date = Date(), 
         prescribedTimestamp: Date = Date(),
         waitAndWatchPeriod: Int, 
         effectivenessDueDate: Date,
         notes: String? = nil,
         hasRecurrence: Bool = false,
         recurrenceRule: String? = nil,
         recurrenceFrequency: Int? = nil,
         recurrenceInterval: Int? = nil,
         recurrenceEndDate: Date? = nil) {
        
        self.name = name
        self.potency = potency
        self.customPotency = customPotency
        self.takenTimestamp = takenTimestamp
        self.prescribedTimestamp = prescribedTimestamp
        self.waitAndWatchPeriod = waitAndWatchPeriod
        self.effectivenessDueDate = effectivenessDueDate
        self.notes = notes
        self.hasRecurrence = hasRecurrence
        self.recurrenceRule = recurrenceRule
        self.recurrenceFrequency = recurrenceFrequency
        self.recurrenceInterval = recurrenceInterval
        self.recurrenceEndDate = recurrenceEndDate
    }
    
    var potencyEnum: RemedyPotency {
        return RemedyPotency(rawValue: self.potency) ?? .other
    }
    
    var recurrenceRuleEnum: RecurrenceRule? {
        if let rule = recurrenceRule {
            return RecurrenceRule(rawValue: rule)
        }
        return nil
    }
    
    var displayPotency: String {
        if potencyEnum == .other && customPotency != nil {
            return customPotency!
        } else {
            return potency
        }
    }
    
    var isActive: Bool {
        return Date() <= effectivenessDueDate
    }
    
    func isActiveAtDate(_ date: Date) -> Bool {
        return date <= effectivenessDueDate && date >= takenTimestamp
    }
    
    func hasOccurrenceOnDate(_ date: Date) -> Bool {
        // Check if it's within the active period
        guard date >= takenTimestamp && (!hasRecurrence || date <= recurrenceEndDate!) else {
            return false
        }
        
        // Simple case: single occurrence
        if !hasRecurrence {
            return Calendar.current.isDate(date, inSameDayAs: takenTimestamp)
        }
        
        // Handle recurrence
        guard let rule = recurrenceRuleEnum else { return false }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .weekOfYear, .month, .year], from: takenTimestamp, to: date)
        
        switch rule {
        case .daily:
            return calendar.isDate(date, inSameDayAs: date) // Any day is valid
            
        case .multipleTimesPerDay:
            // This is complex and would require precise time calculations
            // For now, just check same day
            return calendar.isDate(date, inSameDayAs: date)
            
        case .everyOtherDay:
            guard let days = components.day else { return false }
            return days % 2 == 0
            
        case .weekly:
            guard let weeks = components.weekOfYear else { return false }
            return weeks % 1 == 0 && 
                  calendar.component(.weekday, from: date) == calendar.component(.weekday, from: takenTimestamp)
            
        case .biweekly:
            guard let weeks = components.weekOfYear else { return false }
            return weeks % 2 == 0 && 
                  calendar.component(.weekday, from: date) == calendar.component(.weekday, from: takenTimestamp)
            
        case .monthly:
            guard let months = components.month else { return false }
            return months % 1 == 0 && 
                  calendar.component(.day, from: date) == calendar.component(.day, from: takenTimestamp)
        }
    }
} 