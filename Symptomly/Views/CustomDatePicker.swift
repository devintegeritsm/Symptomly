import SwiftUI
import SwiftData

struct CustomDatePicker: View {
    @Binding var selection: Date
    @State private var showingCalendar = false
    @State private var showingTimePicker = false
    let label: String
    let includeTime: Bool
    
    @Query private var allSymptoms: [Symptom]
    @Query private var allRemedies: [Remedy]
    
    init(_ label: String = "", selection: Binding<Date>, includeTime: Bool = false) {
        self.label = label
        self._selection = selection
        self.includeTime = includeTime
    }
    
    var body: some View {
        HStack {
            if !label.isEmpty {
                Text(label)
            }
            
            Spacer()
            
//            VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                // Date button
                Button(action: {
                    showingCalendar.toggle()
                }) {
                    Text(formatDate(selection))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray6))
                        )
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingCalendar) {
                    VStack(spacing: 0) {
                        VStack {
                            HStack {
                                Button("Cancel") {
                                    showingCalendar = false
                                }
                                .padding(.leading)
                                
                                Spacer()
                                
                                Text("Select Date")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Done") {
                                    showingCalendar = false
                                }
                                .padding(.trailing)
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        }
                        
                        CalendarPickerView(selectedDate: $selection, onDateSelected: {
                            showingCalendar = false
                        })
                        .padding(.horizontal)
                    }
                    .presentationDetents([.height(450)])
                    .presentationDragIndicator(.visible)
                }
                
                // Time picker if needed
                if includeTime {
                    Button(action: {
                        showingTimePicker.toggle()
                    }) {
                        Text(formatTime(selection))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingTimePicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Button("Cancel") {
                                    showingTimePicker = false
                                }
                                .padding(.leading)
                                
                                Spacer()
                                
                                Text("Select Time")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Done") {
                                    showingTimePicker = false
                                }
                                .padding(.trailing)
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                            
                            DatePicker("", selection: $selection, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                        }
                        .presentationDetents([.height(300)])
                        .presentationDragIndicator(.visible)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 
