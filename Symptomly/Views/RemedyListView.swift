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
    @State private var showingRemedyLog = false
    
    @Query(sort: \Remedy.takenTimestamp, order: .reverse) private var allRemedies: [Remedy]
    
    var body: some View {
        NavigationStack {
            VStack {
                RemedyListContent(allRemedies: allRemedies)
            }
            .navigationTitle("Remedies")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingRemedyLog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingRemedyLog) {
                RemedyLogView()
            }
        }
    }
    
    private func determineRemedyStatus(remedy: Remedy) -> RemedyStatus {
        let currentDate = Date()
        
        // Check if in wait and watch period
        if currentDate <= remedy.effectivenessDueDate {
            return .waitAndWatch
        }
        
        // Check if on a repeated schedule
        if remedy.hasRecurrence && remedy.recurrenceEndDate != nil && remedy.recurrenceEndDate! > currentDate {
            return .repeatedSchedule
        }
        
        // Not in wait period and not on schedule
        return .completed
    }
}

// Extracted content view to simplify the main view hierarchy
struct RemedyListContent: View {
    let allRemedies: [Remedy]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if allRemedies.isEmpty {
                    EmptyRemedyView()
                } else {
                    RemedyListSection(remedies: allRemedies)
                }
            }
            .padding()
        }
    }
}

// Empty state view
struct EmptyRemedyView: View {
    var body: some View {
        ContentUnavailableView(
            "No Remedies",
            systemImage: "pill",
            description: Text("You haven't logged any remedies yet.")
        )
        .padding(.top, 50)
    }
}

// Section containing the list of remedies
struct RemedyListSection: View {
    let remedies: [Remedy]
    
    var body: some View {
        Section {
            ForEach(remedies) { remedy in
                RemedyRowLink(remedy: remedy)
                Divider()
            }
        } header: {
            Text("All Remedies")
                .font(.headline)
                .padding(.bottom, 8)
        }
    }
}

// Navigation link with remedy row
struct RemedyRowLink: View {
    let remedy: Remedy
    
    var body: some View {
        NavigationLink(destination: RemedyDetailView(remedy: remedy)) {
            RemedyRow(remedy: remedy, remedyStatus: determineRemedyStatus(remedy: remedy))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func determineRemedyStatus(remedy: Remedy) -> RemedyStatus {
        let currentDate = Date()
        
        // Check if in wait and watch period
        if currentDate <= remedy.effectivenessDueDate {
            return .waitAndWatch
        }
        
        // Check if on a repeated schedule
        if remedy.hasRecurrence && remedy.recurrenceEndDate != nil && remedy.recurrenceEndDate! > currentDate {
            return .repeatedSchedule
        }
        
        // Not in wait period and not on schedule
        return .completed
    }
} 
