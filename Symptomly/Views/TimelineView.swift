import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
    
    // Export state
    @State private var showingExportOptions = false
    @State private var exportStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var exportEndDate = Date()
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    
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
                details: (symptom.isResolved
                          ? "Resolved: \(Utils.formatDateTime(symptom.timestamp))"
                          : "Severity: \(symptom.severityEnum.rawValue)")
                    + (symptom.notes != nil ? " - \(symptom.notes!)" : ""),
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
                    
                    HStack(spacing: 16) {
                        // Export button
                        Button(action: {
                            showingExportOptions = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                        }
                        
                        // Calendar button
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
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(
                    startDate: $exportStartDate,
                    endDate: $exportEndDate,
                    onExport: { startDate, endDate, action in
                        exportTimeline(from: startDate, to: endDate, action: action)
                        showingExportOptions = false
                    }
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: exportedFileURL) { _, newURL in
                // When URL changes and is not nil, update the sheet presentation
                if newURL != nil && !showingShareSheet {
                    showingShareSheet = true
                }
            }
            .sheet(isPresented: $showingShareSheet, onDismiss: {
                // Clear URL on dismiss
                self.exportedFileURL = nil
            }) {
                if let url = self.exportedFileURL {
                    ShareSheet(items: [url])
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
    
    // Export Timeline Functions
    private func exportTimeline(from startDate: Date, to endDate: Date, action: ExportAction) {
        self.exportStartDate = startDate
        self.exportEndDate = endDate
        
        // Generate markdown content
        let markdown = generateMarkdown(from: startDate, to: endDate)
        print("Generated markdown content with \(markdown.count) characters")
        
        // Create file for sharing
        guard let url = createTemporaryFile(content: markdown) else {
            print("Failed to create temporary file")
            return
        }
            
        print("Successfully created file at: \(url.path)")
        
        // Set file attributes to make sure it's accessible
        do {
            try (url as NSURL).setResourceValue(true, forKey: .isReadableKey)
            
            // Set URL which will trigger the sheet presentation via onChange
            self.exportedFileURL = url
            
        } catch {
            print("Error setting resource value: \(error)")
        }
    }
    
    private func generateMarkdown(from startDate: Date, to endDate: Date) -> String {
        // Find all items in the date range
        let calendar = Calendar.current
        let allItems = fetchTimelineItems(from: startDate, to: endDate)
            .sorted { $0.timestamp > $1.timestamp }
        
        var markdown = "# Symptomly Timeline Export\n\n"
        markdown += "**Export Date:** \(formatDate(Date()))\n"
        markdown += "**Period:** \(formatDate(startDate)) to \(formatDate(endDate))\n\n"
        
        // Group by date
        var currentDateString = ""
        
        for item in allItems {
            let dateString = formatDate(calendar.startOfDay(for: item.timestamp))
            
            if dateString != currentDateString {
                currentDateString = dateString
                markdown += "\n## \(dateString)\n\n"
            }
            
            // Format time
            let timeString = formatTime(item.timestamp)
            
            // Item details
            let itemType = item.type == .symptom ? "Symptom" : "Remedy"
            markdown += "### \(timeString) - \(itemType): \(item.name)\n\n"
            markdown += "\(item.details)\n\n"
            markdown += "---\n\n"
        }
        
        return markdown
    }
    
    private func fetchTimelineItems(from startDate: Date, to endDate: Date) -> [TimelineItem] {
        var items: [TimelineItem] = []
        
        // We need to fetch data for the specified date range, not the currently displayed range
        let symptomPredicate = #Predicate<Symptom> { 
            $0.timestamp >= startDate && $0.timestamp <= endDate
        }
        let remedyPredicate = #Predicate<Remedy> {
            $0.takenTimestamp >= startDate && $0.takenTimestamp <= endDate
        }
        
        let exportSymptoms = try? modelContext.fetch(FetchDescriptor<Symptom>(predicate: symptomPredicate, sortBy: [SortDescriptor(\.timestamp, order: .reverse)]))
        let exportRemedies = try? modelContext.fetch(FetchDescriptor<Remedy>(predicate: remedyPredicate, sortBy: [SortDescriptor(\.takenTimestamp, order: .reverse)]))
        
        // Process symptoms
        if let exportSymptoms {
            for symptom in exportSymptoms {
                items.append(TimelineItem(
                    timestamp: symptom.timestamp,
                    type: .symptom,
                    name: symptom.name,
                    details: "Severity: \(symptom.severityEnum.rawValue)" + (symptom.notes != nil ? " - \(symptom.notes!)" : ""),
                    color: symptom.severityEnum.color
                ))
            }
        }
        
        // Process remedies
        if let exportRemedies {
            for remedy in exportRemedies {
                items.append(TimelineItem(
                    timestamp: remedy.takenTimestamp,
                    type: .remedy,
                    name: remedy.name,
                    details: "Potency: \(remedy.displayPotency)" + (remedy.notes != nil ? " - \(remedy.notes!)" : ""),
                    color: .blue
                ))
            }
        }
        
        return items
    }
    
    private func createTemporaryFile(content: String) -> URL? {
        // Use the app's documents directory for better sharing support
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return nil
        }
        
        do {
            // Create a unique filename with timestamp
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "Symptomly_Timeline_\(formatFileDate(Date()))_\(timestamp).md"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            print("Attempting to create file at: \(fileURL.path)")
            
            // Make sure content is not empty
            guard !content.isEmpty else {
                print("Cannot create file with empty content")
                return nil
            }
            
            // Remove any existing file
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("Removed existing file")
            }
            
            // Write the content to the file
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Verify file was created successfully
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0
                print("File created successfully. Size: \(fileSize) bytes")
                
                // Make sure the file has the right attributes for sharing
                try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: fileURL.path)
                return fileURL
            } else {
                print("File does not exist after writing")
                return nil
            }
        } catch {
            print("Error creating file: \(error.localizedDescription)")
            return nil
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
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatFileDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
                    Image(systemName: item.type == .symptom ? "thermometer.medium" : "flask")
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
                
                if item.type == .symptom {
                    // Show severity indicator for symptoms using dots
                    let severity = getSeverityFromDetails(item.details)
                    SeverityIndicator(severity: severity)
                    
                    if let notes = extractNotes(from: item.details), !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    // For remedies, keep showing the original details
                    Text(item.details)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
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
    
    // Function to extract severity from the details string
    private func getSeverityFromDetails(_ details: String) -> Severity {
        if details.contains("Resolved:") {
            return .resolved
        }
        
        // Expected format: "Severity: X - Notes"
        let components = details.split(separator: ":")
        if components.count >= 2, let severityString = components[safe: 1]?.split(separator: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines) {
            switch severityString {
            case "Mild": return .mild
            case "Moderate": return .moderate
            case "Severe": return .severe
            case "Extreme": return .extreme
            default: return .mild
            }
        }
        
        return .mild // Default to mild if parsing fails
    }
    
    // Function to extract notes from the details
    private func extractNotes(from details: String) -> String? {
        // Expected format for symptoms: "Severity: X - Notes" or "Resolved: <date> - Notes"
        if details.contains(" - ") {
            let components = details.split(separator: " - ", maxSplits: 1)
            if components.count > 1 {
                return String(components[1])
            }
        }
        return nil
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Export options view
enum ExportAction {
    case share
}

struct ExportOptionsView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss
    let onExport: (Date, Date, ExportAction) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Timeline")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Date Range:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 16) {
                        DatePicker("From", selection: $startDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                        
                        DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                Button(action: {
                    onExport(startDate, endDate, .share)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Timeline")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// ShareSheet for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Process items to ensure file URLs are handled properly
        let processedItems = items.map { item -> Any in
            guard let url = item as? URL else { return item }
            
            // For file URLs, create an activity item source that handles the file properly
            return URLActivityItemSource(url: url)
        }
        
        let controller = UIActivityViewController(activityItems: processedItems, applicationActivities: nil)
        
        // Ensure the controller works properly on iPad
        if let popoverController = controller.popoverPresentationController {
            popoverController.sourceView = UIView()
            popoverController.permittedArrowDirections = []
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Custom activity item source to properly handle file URLs
class URLActivityItemSource: NSObject, UIActivityItemSource {
    let url: URL
    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Symptomly Timeline"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.plainText.identifier
    }
}

