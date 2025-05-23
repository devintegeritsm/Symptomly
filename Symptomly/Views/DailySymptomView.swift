//
//  DailySymptomView.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI
import SwiftData

// NotificationCenter name for date selection
extension Notification.Name {
    static let dateSelected = Notification.Name("dateSelectedFromSymptomView")
}

struct DailySymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingSymptomLog = false
    @State private var selectedDate = Date()
    @State private var showingCalendarPicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Symptoms")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            showingSymptomLog = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
                
                HStack {
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        publishSelectedDate()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    
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
                            publishSelectedDate()
                        })
                        .frame(width: 340, height: 400)
                        .padding()
                        .presentationDetents([.height(450)])
                        .presentationDragIndicator(.visible)
                    }
                    
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        publishSelectedDate()
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(Calendar.current.isDateInToday(selectedDate) || Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
                }
                .padding(.horizontal)
                
                // Content
                SymptomListView(selectedDate: $selectedDate)
            
            }
            .sheet(isPresented: $showingSymptomLog) {
                SymptomFormView(selectedDate: selectedDate)
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
    
    private func publishSelectedDate() {
        NotificationCenter.default.post(
            name: .dateSelected,
            object: nil,
            userInfo: ["selectedDate": selectedDate]
        )
    }
} 
