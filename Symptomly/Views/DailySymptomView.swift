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
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            SymptomListView(selectedDate: $selectedDate)
                .navigationTitle("Symptomly")
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .topBarLeading) {
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
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showingSymptomLog = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                    #endif
                }
                .sheet(isPresented: $showingSymptomLog) {
                    SymptomLogView()
                }
        }
    }
} 
