import SwiftUI
import SwiftData

struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isActive: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPickerTab: Int = 0
    @State private var selectedStartDate: Date
    @State private var selectedEndDate: Date 
    @State private var showingPresetOptions = false
    
    private let calendar = Calendar.current
    var onDateRangeSelected: (() -> Void)?
    var onExport: ((Date, Date) -> Void)?
    
    enum DateRangePreset: String, CaseIterable, Identifiable {
        case today = "Today"
        case yesterday = "Yesterday"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case custom = "Custom Range"
        
        var id: String { rawValue }
    }
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, isActive: Binding<Bool>, onDateRangeSelected: (() -> Void)? = nil) {
        self._startDate = startDate
        self._endDate = endDate 
        self._isActive = isActive
        self._selectedStartDate = State(initialValue: startDate.wrappedValue)
        self._selectedEndDate = State(initialValue: endDate.wrappedValue)
        self.onDateRangeSelected = onDateRangeSelected
        self.onExport = nil
    }
    
    // Initialize for export functionality
    init(startDate: Binding<Date>, endDate: Binding<Date>, onExport: @escaping (Date, Date) -> Void) {
        self._startDate = startDate
        self._endDate = endDate
        self._isActive = .constant(true) // Not used in export mode
        self._selectedStartDate = State(initialValue: startDate.wrappedValue)
        self._selectedEndDate = State(initialValue: endDate.wrappedValue)
        self.onExport = onExport
        self.onDateRangeSelected = nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 7) {
                Text(onExport != nil ? "Export Timeline" : "Select Date Range")
                    .font(.title3)
                    .fontWeight(.bold)  
                    .padding(.top)
                
                // Presets button
                Button(action: {
                    showingPresetOptions = true
                }) {
                    HStack {
                        Text("Presets")
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .confirmationDialog("Select Date Range Preset", isPresented: $showingPresetOptions, titleVisibility: .visible) {
                    ForEach(DateRangePreset.allCases) { preset in
                        Button(preset.rawValue) {
                            selectPreset(preset)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                
                // Tab selection for start/end date pickers
                Picker("", selection: $selectedPickerTab) {
                    Text("Start Date").tag(0)
                    Text("End Date").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Calendar view for selected tab
                if selectedPickerTab == 0 {
                    CalendarPickerView(selectedDate: $selectedStartDate)
                        .frame(maxHeight: .infinity)
                } else {
                    CalendarPickerView(selectedDate: $selectedEndDate)
                        .frame(maxHeight: .infinity)
                }
                
                // Date range summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Date:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(selectedStartDate))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("End Date:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(selectedEndDate))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                
                // Action button (Apply Filter or Export)
                Button(action: {
                    if onExport != nil {
                        onExport?(selectedStartDate, selectedEndDate)
                    } else {
                        applyDateRange()
                    }
                }) {
                    HStack {
                        if onExport != nil {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Timeline")
                                .fontWeight(.medium)
                        } else {
                            Text("Apply Filter")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isValidDateRange() ? (onExport != nil ? Color.blue : Color.accentColor) : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!isValidDateRange())
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .onChange(of: selectedStartDate) { validateEndDate() }
            .onChange(of: selectedEndDate) { validateStartDate() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents(onExport != nil ? [.height(400)] : [.height(720)])
        .presentationDragIndicator(.visible)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func applyDateRange() {
        startDate = calendar.startOfDay(for: selectedStartDate)
        endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedEndDate) ?? selectedEndDate
        isActive = true
        onDateRangeSelected?()
    }
    
    private func isValidDateRange() -> Bool {
        return selectedEndDate >= selectedStartDate
    }
    
    private func validateEndDate() {
        if calendar.isDate(selectedEndDate, inSameDayAs: selectedStartDate) {
            selectedEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedStartDate) ?? selectedStartDate
        } else if selectedEndDate < selectedStartDate {
            selectedEndDate = selectedStartDate
        }
    }
    
    private func validateStartDate() {
        if calendar.isDate(selectedEndDate, inSameDayAs: selectedStartDate) {
            selectedStartDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: selectedEndDate) ?? selectedEndDate
        } else if selectedStartDate > selectedEndDate {
            selectedStartDate = selectedEndDate
        }
    }
    
    private func selectPreset(_ preset: DateRangePreset) {
        let now = Date()
        
        switch preset {
        case .today:
            // Today
            selectedStartDate = calendar.startOfDay(for: now)
            selectedEndDate = now
            
        case .yesterday:
            // Yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                selectedStartDate = calendar.startOfDay(for: yesterday)
                selectedEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? yesterday
            }
            
        case .last7Days:
            // Last 7 days
            if let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: now) {
                selectedStartDate = calendar.startOfDay(for: sevenDaysAgo)
                selectedEndDate = now
            }
            
        case .last30Days:
            // Last 30 days
            if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: now) {
                selectedStartDate = calendar.startOfDay(for: thirtyDaysAgo)
                selectedEndDate = now
            }
            
        case .thisMonth:
            // This month
            var components = calendar.dateComponents([.year, .month], from: now)
            if let firstDay = calendar.date(from: components) {
                selectedStartDate = firstDay
                
                // Get the last day of the month
                components.month = components.month! + 1
                components.day = 0
                if let lastDay = calendar.date(from: components) {
                    selectedEndDate = lastDay
                } else {
                    selectedEndDate = now
                }
            }
            
        case .lastMonth:
            // Last month
            var components = calendar.dateComponents([.year, .month], from: now)
            components.month = components.month! - 1
            
            if let firstDay = calendar.date(from: components) {
                selectedStartDate = firstDay
                
                // Get the last day of the last month
                components.month = components.month! + 1
                components.day = 0
                if let lastDay = calendar.date(from: components) {
                    selectedEndDate = lastDay
                } else {
                    selectedEndDate = now
                }
            }
            
        case .custom:
            // Keep current selection
            break
        }
    }
} 
