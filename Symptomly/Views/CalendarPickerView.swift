import SwiftUI
import SwiftData

struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Query private var allSymptoms: [Symptom]
    @Query private var allRemedies: [Remedy]
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    @State private var displayedMonth: Date
    @State private var showingMonthView = false
    var onDateSelected: (() -> Void)?
    
    init(selectedDate: Binding<Date>, onDateSelected: (() -> Void)? = nil) {
        self._selectedDate = selectedDate
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
        self.onDateSelected = onDateSelected
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Month navigation header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    showingMonthView.toggle()
                }) {
                    Text(monthYearText(from: displayedMonth))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingMonthView) {
                    MonthPickerView(selectedDate: $displayedMonth, closeAction: { showingMonthView = false })
                        .presentationDetents([.height(300)])
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: daysInWeek), spacing: 6) {
//                ForEach(daysInMonth(), id: \.self) { date in
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { idx, date in
                    if let date = date {
                        let hasSymptom = hasSymptomOnDate(date)
                        let hasRemedy = hasRemedyOnDate(date)
                        
                        Button(action: {
                            selectedDate = date
                            onDateSelected?()
                        }) {
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 20, weight: calendar.isDateInToday(date) ? .heavy : calendar.isDate(date, inSameDayAs: selectedDate) ? .medium : .regular
                                                  ))
                                    .foregroundStyle(
                                        calendar.isDate(date, inSameDayAs: selectedDate) ? .white :
//                                        calendar.isDateInToday(date) ? .accentColor :
                                        isCurrentMonth(date) ? .primary : .secondary
                                    )
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Group {
                                            if calendar.isDate(date, inSameDayAs: selectedDate) {
                                                Circle()
                                                    .fill(Color.accentColor)
                                            } else {
                                                Color.clear
                                            }
                                        }
                                    )
                                
                                // Indicators
                                HStack(spacing: 2) {
                                    if hasSymptom {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 6, height: 6)
                                    }
                                    
                                    if hasRemedy {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 45)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                    } else {
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 35)
                    }
                }
            }
            .id(UUID())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
    
    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let startWeekday = calendar.component(.weekday, from: startOfMonth)
        let numberOfDays = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
        
        var days: [Date?] = Array(repeating: nil, count: startWeekday - 1)
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Add padding to complete the grid if needed
        let remainingCells = (7 - (days.count % 7)) % 7
        days.append(contentsOf: Array(repeating: nil, count: remainingCells))
        
        return days
    }
    
    private func hasSymptomOnDate(_ date: Date) -> Bool {
        return allSymptoms.contains { symptom in
            calendar.isDate(symptom.timestamp, inSameDayAs: date)
        }
    }
    
    private func hasRemedyOnDate(_ date: Date) -> Bool {
        return allRemedies.contains { remedy in
            calendar.isDate(remedy.takenTimestamp, inSameDayAs: date)
        }
    }
    
    private func getBackgroundColor(date: Date, hasSymptom: Bool, hasRemedy: Bool) -> Color {
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            return .accentColor
        } else if hasSymptom && hasRemedy {
            // When both exist, use a blend or priority based on design preference
            return .purple // Blend of blue and green
        } else if hasSymptom {
            return .blue
        } else if hasRemedy {
            return .green
        } else if calendar.isDateInToday(date) {
            return .gray
        } else {
            return .clear
        }
    }
    
    private func getBackgroundOpacity(date: Date, hasSymptom: Bool, hasRemedy: Bool) -> Double {
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            return 1.0
        } else if hasSymptom || hasRemedy {
            return 0.3
        } else if calendar.isDateInToday(date) {
            return 0.2
        } else {
            return 0.0
        }
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        return calendar.component(.month, from: date) == calendar.component(.month, from: displayedMonth)
    }
    
    private func monthYearText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
}

// Helper view for month selection
struct MonthPickerView: View {
    @Binding var selectedDate: Date
    let closeAction: () -> Void
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            Text("Select Month")
                .font(.headline)
                .padding(.top)
            
            HStack {
                Button(action: previousYear) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(yearText(from: selectedDate))
                    .font(.title3)
                
                Spacer()
                
                Button(action: nextYear) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                ForEach(0..<12, id: \.self) { month in
                    Button(action: {
                        selectMonth(month)
                        closeAction()
                    }) {
                        Text(monthName(month))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelectedMonth(month) ? Color.accentColor : Color.clear)
                                    .opacity(isSelectedMonth(month) ? 0.3 : 0)
                            )
                            .foregroundStyle(isSelectedMonth(month) ? .primary : .secondary)
                            

                    }
                    .id(UUID())
                }
            }
            .padding()
            .id(UUID())
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var components = DateComponents()
        components.month = month + 1
        components.day = 1
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }
    
    private func isSelectedMonth(_ month: Int) -> Bool {
        return month + 1 == calendar.component(.month, from: selectedDate)
    }
    
    private func selectMonth(_ month: Int) {
        var components = calendar.dateComponents([.year, .day], from: selectedDate)
        components.month = month + 1
        if let newDate = calendar.date(from: components) {
            selectedDate = newDate
        }
    }
    
    private func yearText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private func previousYear() {
        if let newDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextYear() {
        if let newDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
} 
