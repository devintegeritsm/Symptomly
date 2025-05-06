//
//  DailySymptomView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUICore
import SwiftUI


struct DailySymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingSymptomLog = false
    @State private var showingRemedyLog = false
    @State private var selectedDate = Date()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                // Date navigation
                HStack {
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(Calendar.current.isDateInToday(selectedDate) || Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
                }
                .padding(.horizontal)
                
                // Tabs for Symptoms and Remedies
                Picker("View", selection: $selectedTab) {
                    Text("Symptoms").tag(0)
                    Text("Remedies").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    SymptomListView(selectedDate: $selectedDate)
                } else {
                    RemedyListView(selectedDate: $selectedDate)
                }
            }
            .navigationTitle("Symptomly")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingSymptomLog = true
                        } label: {
                            Label("Log Symptom", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingRemedyLog = true
                        } label: {
                            Label("Log Remedy", systemImage: "pill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSymptomLog) {
                SymptomLogView()
            }
            .sheet(isPresented: $showingRemedyLog) {
                RemedyLogView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DidSaveRemedy"))) { _ in
            // Switch to Remedies tab when a remedy is saved
            selectedTab = 1
        }
    }
} 
