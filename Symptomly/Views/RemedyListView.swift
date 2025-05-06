//
//  RemedyListView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 6/19/25.
//

import SwiftUI
import SwiftData

struct RemedyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDate: Date
    
    @Query private var allRemedies: [Remedy]
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
    }
    
    var remediesForSelectedDate: [Remedy] {
        allRemedies.filter { remedy in
            let calendar = Calendar.current
            
            // For non-recurring remedies, check if taken on the selected date
            if !remedy.hasRecurrence {
                return calendar.isDate(remedy.takenTimestamp, inSameDayAs: selectedDate)
            }
            
            // For recurring remedies, check if there's an occurrence on the selected date
            return remedy.hasOccurrenceOnDate(selectedDate)
        }
        .sorted { $0.takenTimestamp > $1.takenTimestamp }
    }
    
    // Future occurrences of recurring remedies
    var futureRemedies: [Remedy] {
        guard Calendar.current.isDateInToday(selectedDate) else {
            return []
        }
        
        return allRemedies.filter { remedy in
            remedy.hasRecurrence && 
            remedy.recurrenceEndDate != nil && 
            remedy.recurrenceEndDate! > Date() &&
            !Calendar.current.isDate(remedy.takenTimestamp, inSameDayAs: Date())
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if remediesForSelectedDate.isEmpty && futureRemedies.isEmpty {
                    ContentUnavailableView(
                        "No Remedies",
                        systemImage: "pill",
                        description: Text("You haven't logged any remedies for this date.")
                    )
                    .padding(.top, 50)
                } else {
                    if !remediesForSelectedDate.isEmpty {
                        Section {
                            ForEach(remediesForSelectedDate) { remedy in
                                NavigationLink(destination: RemedyDetailView(remedy: remedy)) {
                                    RemedyRow(remedy: remedy)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                            }
                        } header: {
                            Text("Remedies")
                                .font(.headline)
                                .padding(.bottom, 8)
                        }
                    }
                    
                    if !futureRemedies.isEmpty {
                        Section {
                            ForEach(futureRemedies) { remedy in
                                RemedyRow(remedy: remedy, isPlaceholder: true)
                                Divider()
                            }
                        } header: {
                            Text("Upcoming Remedies")
                                .font(.headline)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
        }
    }
} 