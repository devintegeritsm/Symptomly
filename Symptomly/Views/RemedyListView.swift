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
    
    @State private var remedyToDelete: Remedy?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Remedies")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            showingRemedyLog = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
                
                RemedyListContent(allRemedies: allRemedies, remedyToDelete: $remedyToDelete, showDeleteConfirmation: $showDeleteConfirmation)
            }
            .sheet(isPresented: $showingRemedyLog) {
                RemedyFormView()
            }
            .alert("Delete Remedy", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    remedyToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let remedy = remedyToDelete {
                        deleteRemedy(remedy)
                        remedyToDelete = nil
                    }
                }
            } message: {
                if let remedy = remedyToDelete {
                    Text("Are you sure you want to delete '\(remedy.name)'? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this remedy? This action cannot be undone.")
                }
            }
        }
    }
    
    private func deleteRemedy(_ remedy: Remedy) {
        // Cancel notifications before deletion
        NotificationManager.shared.cancelNotifications(identifiers: remedy.notificationIdentifiers)
        
        modelContext.delete(remedy)
        
        // Notify that a remedy was deleted
        NotificationCenter.default.post(name: NSNotification.Name("DidDeleteRemedy"), object: nil)
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
    @Environment(\.modelContext) private var modelContext
    let allRemedies: [Remedy]
    @Binding var remedyToDelete: Remedy?
    @Binding var showDeleteConfirmation: Bool
    
    var body: some View {
        List {
            if allRemedies.isEmpty {
                EmptyRemedyView()
            } else {
                ForEach(allRemedies) { remedy in
                    RemedyRow(remedy: remedy, remedyStatus: determineRemedyStatus(remedy: remedy))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                remedyToDelete = remedy
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            NavigationLink {
                                RemedyFormView(remedy: remedy, mode: .edit)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
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

// Empty state view
struct EmptyRemedyView: View {
    var body: some View {
        ContentUnavailableView(
            "No Remedies",
            systemImage: "flask",
            description: Text("You haven't logged any remedies yet.")
        )
        .padding(.top, 50)
    }
}
