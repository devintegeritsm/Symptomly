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
    @State private var showingCalendarPicker = false
    
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
                    
                    Spacer()
                    
                    Button(action: {
                        showingCalendarPicker.toggle()
                    }) {
                        Text(formattedDate(selectedDate))
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .sheet(isPresented: $showingCalendarPicker) {
                        CalendarPickerView(selectedDate: $selectedDate, onDateSelected: {
                            showingCalendarPicker = false
                        })
                        .frame(width: 340, height: 400)
                        .padding()
                        .presentationDetents([.height(450)])
                        .presentationDragIndicator(.visible)
                    }
                    
                    Spacer()
                    
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
                SymptomLogView(selectedDate: selectedDate)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DidSaveRemedy"))) { _ in
            // No longer need to switch tabs here
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 
