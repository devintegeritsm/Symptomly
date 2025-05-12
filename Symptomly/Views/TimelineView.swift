import SwiftUI
import SwiftData

struct TimelineItem: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: ItemType
    let name: String
    let details: String
    let color: Color
    
    enum ItemType {
        case symptom
        case remedy
    }
}

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var showingCalendarPicker = false
    
    // Pagination
    @State private var currentPage = 0
    @State private var itemsPerPage = 20
    @State private var isLoadingMore = false
    @State private var hasMoreContent = true
    
    // Date range for query
    @State private var startDate: Date?
    @State private var endDate: Date?
    
    @Query private var symptoms: [Symptom]
    @Query private var remedies: [Remedy]
    
    init() {
        // Default to showing current date range
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        self._startDate = State(initialValue: startOfWeek)
        self._endDate = State(initialValue: endOfWeek)
        
        // Create query predicates for date filtering
        let symptomPredicate = #Predicate<Symptom> { 
            $0.timestamp >= startOfWeek && $0.timestamp <= endOfWeek
        }
        let remedyPredicate = #Predicate<Remedy> {
            $0.takenTimestamp >= startOfWeek && $0.takenTimestamp <= endOfWeek
        }
        
        self._symptoms = Query(filter: symptomPredicate, sort: \Symptom.timestamp, order: .reverse)
        self._remedies = Query(filter: remedyPredicate, sort: \Remedy.takenTimestamp, order: .reverse)
    }
    
    var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        
        // Add symptoms to timeline
        for symptom in symptoms {
            items.append(TimelineItem(
                timestamp: symptom.timestamp,
                type: .symptom,
                name: symptom.name,
                details: "Severity: \(symptom.severityEnum.rawValue)" + (symptom.notes != nil ? " - \(symptom.notes!)" : ""),
                color: symptom.severityEnum.color
            ))
        }
        
        // Add remedies to timeline
        for remedy in remedies {
            items.append(TimelineItem(
                timestamp: remedy.takenTimestamp,
                type: .remedy,
                name: remedy.name,
                details: "Potency: \(remedy.displayPotency)" + (remedy.notes != nil ? " - \(remedy.notes!)" : ""),
                color: .blue
            ))
        }
        
        // Sort all items by timestamp
        return items.sorted { $0.timestamp > $1.timestamp }
    }
    
    var paginatedItems: [TimelineItem] {
        if timelineItems.isEmpty {
            return []
        }
        
        // With continuous scrolling, we'll show all loaded items
        let endIndex = min((currentPage + 1) * itemsPerPage, timelineItems.count)
        return Array(timelineItems[0..<endIndex])
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with calendar access
                HStack {
                    Text("Timeline")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingCalendarPicker.toggle()
                    }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                    }
                    .sheet(isPresented: $showingCalendarPicker) {
                        CalendarPickerView(selectedDate: $selectedDate, onDateSelected: {
                            updateDateRange(from: selectedDate)
                            showingCalendarPicker = false
                        })
                        .frame(width: 340, height: 400)
                        .padding()
                        .presentationDetents([.height(450)])
                        .presentationDragIndicator(.visible)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
                
                // Timeline content
                if paginatedItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.top, 60)
                        
                        Text("No events in this period")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Try selecting a different date range")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(paginatedItems) { item in
                                TimelineItemRow(item: item)
                                    .padding(.horizontal)
                                    .onAppear {
                                        // If this is one of the last items, load more
                                        if item.id == paginatedItems.last?.id && !isLoadingMore && hasMoreContent {
                                            loadMoreContent()
                                        }
                                    }
                            }
                            
                            if isLoadingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                            
                            if !hasMoreContent && !paginatedItems.isEmpty {
                                Text("End of timeline")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dateSelected)) { notification in
                if let selectedDate = notification.userInfo?["selectedDate"] as? Date {
                    self.selectedDate = selectedDate
                    updateDateRange(from: selectedDate)
                }
            }
        }
    }
    
    var formattedDateRange: String {
        guard let start = startDate, let end = endDate else {
            return "All Events"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    var isCurrentPeriod: Bool {
        guard let end = endDate else { return false }
        let today = Date()
        return Calendar.current.isDate(end, inSameDayAs: today) || end > today
    }
    
    private func loadMoreContent() {
        guard !isLoadingMore && hasMoreContent else { return }
        
        isLoadingMore = true
        
        // Simulate a small delay for better UX when loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Check if we have more content to load
            let nextPageStart = (currentPage + 1) * itemsPerPage
            
            if nextPageStart < timelineItems.count {
                currentPage += 1
                hasMoreContent = (currentPage + 1) * itemsPerPage < timelineItems.count
            } else {
                hasMoreContent = false
            }
            
            isLoadingMore = false
        }
    }
    
    private func resetPagination() {
        currentPage = 0
        isLoadingMore = false
        hasMoreContent = true
    }
    
    private func updateDateRange(from date: Date) {
        let calendar = Calendar.current
        
        // Set up a weekly range (centered on selected date)
        let startOfWeek = calendar.date(byAdding: .day, value: -3, to: date)!
        let endOfWeek = calendar.date(byAdding: .day, value: 3, to: date)!
        
        startDate = startOfWeek
        endDate = endOfWeek
        
        // Reset pagination when date range changes
        resetPagination()
    }
    
    private func navigateToPreviousPeriod() {
        guard let start = startDate else { return }
        
        let calendar = Calendar.current
        let newStart = calendar.date(byAdding: .day, value: -7, to: start)!
        let newEnd = calendar.date(byAdding: .day, value: -7, to: endDate!)!
        
        startDate = newStart
        endDate = newEnd
        
        // Reset pagination when date range changes
        resetPagination()
    }
    
    private func navigateToNextPeriod() {
        guard let end = endDate, !isCurrentPeriod else { return }
        
        let calendar = Calendar.current
        let newStart = calendar.date(byAdding: .day, value: 7, to: startDate!)!
        let newEnd = calendar.date(byAdding: .day, value: 7, to: end)!
        
        startDate = newStart
        endDate = newEnd
        
        // Reset pagination when date range changes
        resetPagination()
    }
}

struct TimelineItemRow: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column for time
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(item.timestamp))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formatDate(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 75)
            
            // Center vertical line with dot
            VStack(spacing: 0) {
                Circle()
                    .fill(item.color)
                    .frame(width: 10, height: 10)
                
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            
            // Right column with content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: item.type == .symptom ? "list.clipboard" : "flask")
                        .foregroundColor(item.color)
                    
                    Text(item.type == .symptom ? "Symptom" : "Remedy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                }
                
                Text(item.name)
                    .font(.headline)
                
                Text(item.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

