//
//  DailySymptomView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI


struct DailySymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingSymptomLog = false
    @State private var selectedDate = Date()
    
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
                
                // Content
                SymptomListView(selectedDate: $selectedDate)
            }
            .navigationTitle("Symptoms")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSymptomLog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSymptomLog) {
                SymptomLogView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DidSaveRemedy"))) { _ in
            // No longer need to switch tabs here
        }
    }
} 
