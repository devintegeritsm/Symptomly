import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var showingCalendarPicker = false
    
    // Date range filter
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var endDate = Date()
    @State private var isDateRangeActive = false
    
    // Search state
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchFilter: SearchFilter = .all
    
    // Export state
    @State private var showingExportOptions = false
    @State private var exportStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var exportEndDate = Date()
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
        
    @Query private var symptoms: [Symptom]
    @Query private var remedies: [Remedy]
    
    @State private var timelineItems: [TimelineItem] = []

    // Search filter enum
    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case symptoms = "Symptoms"
        case remedies = "Remedies"
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"
        case extreme = "Extreme"
        case resolved = "Resolved"
    }
    
    init() {
        self._symptoms = Query(sort: \Symptom.timestamp, order: .reverse)
        self._remedies = Query(sort: \Remedy.takenTimestamp, order: .reverse)
    }
    
    private func reloadTimelineItems() {
        var items: [TimelineItem] = []
        
        // Add symptoms to timeline
        for symptom in symptoms {
            items.append(TimelineItem(
                timestamp: symptom.timestamp,
                type: .symptom,
                name: symptom.name,
                details: (symptom.isResolved
                          ? "Resolved"
                          : "Severity: \(symptom.severityEnum.displayName)")
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
        
        self.timelineItems.removeAll()
        self.timelineItems.append(contentsOf: items.sorted { $0.timestamp > $1.timestamp })
    }
        
    var filteredItems: [TimelineItem] {
        // First, filter by date range if active
        var items = timelineItems
        
        if isDateRangeActive {
            items = items.filter { item in
                let calendar = Calendar.current
                let itemDate = calendar.startOfDay(for: item.timestamp)
                let startOfStartDate = calendar.startOfDay(for: startDate)
                let endOfEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!
                
                return itemDate >= startOfStartDate && itemDate <= endOfEndDate
            }
        }
        
        // Then apply search and category filters
        if searchText.isEmpty && searchFilter == .all {
            return items
        }
        
        return items.filter { item in
            var matchesFilter = true
            
            // Apply category filter
            switch searchFilter {
            case .symptoms:
                matchesFilter = item.type == .symptom
            case .remedies:
                matchesFilter = item.type == .remedy
            case .mild, .moderate, .severe, .extreme, .resolved:
                // Only apply to symptoms
                if item.type == .symptom {
                    let severityString = searchFilter.rawValue
                    matchesFilter = item.details.contains("Severity: \(severityString)") || 
                                   (searchFilter == .resolved && item.details.contains("Resolved"))
                } else {
                    matchesFilter = false
                }
            case .all:
                matchesFilter = true
            }
            
            // If no search text, just return the filter result
            if searchText.isEmpty {
                return matchesFilter
            }
            
            // Apply text search if we have search text
            let searchLowercased = searchText.lowercased()
            
            // Search in name
            let nameMatch = item.name.lowercased().contains(searchLowercased)
            
            // Search in details (notes and potency)
            let detailsMatch = item.details.lowercased().contains(searchLowercased)
            
            return matchesFilter && (nameMatch || detailsMatch)
        }
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
                        Button(action: {
                            isSearching.toggle()
                        }) {
                            Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                                .font(.system(size: 18))
                        }
                        
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
                                .overlay(
                                    isDateRangeActive ? 
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 7, y: 7) : nil
                                )
                        }
                        .sheet(isPresented: $showingCalendarPicker) {
                            DateRangePickerView(
                                startDate: $startDate,
                                endDate: $endDate,
                                isActive: $isDateRangeActive,
                                onDateRangeSelected: {
                                    showingCalendarPicker = false
                                }
                            )
                            .frame(width: 340, height: 700)
                            .padding()
                            .presentationDetents([.height(720)])
                            .presentationDragIndicator(.visible)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
                
                // Date range indicator
                if isDateRangeActive {
                    HStack {
                        Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            isDateRangeActive = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                }
                
                // Search bar
                if isSearching {
                    VStack(spacing: 8) {
                        // Search text field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search symptoms, remedies...", text: $searchText)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SearchFilter.allCases, id: \.self) { filter in
                                    FilterChip(
                                        text: filter.rawValue,
                                        isSelected: searchFilter == filter,
                                        color: filterColor(for: filter)
                                    ) {
                                        searchFilter = filter
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut, value: isSearching)
                }
                
                // Timeline content
                if filteredItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.top, 60)
                        
                        if !searchText.isEmpty || searchFilter != .all {
                            Text("No matching items")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Try changing your search or filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.8))
                        } else if isDateRangeActive {
                            Text("No events in this period")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Try selecting a different date range")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.8))
                        } else {
                            Text("No events to display")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Add symptoms or remedies to see them here")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(filteredItems) { item in
                                TimelineItemRow(item: item)
                                    .padding(.horizontal)
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
                DateRangePickerView(
                    startDate: $exportStartDate,
                    endDate: $exportEndDate,
                    onExport: { startDate, endDate in
                        exportTimeline(from: startDate, to: endDate)
                        showingExportOptions = false
                    }
                )
                .frame(width: 340, height: 700)
                .padding()
                .presentationDetents([.height(720)])
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
            .onAppear() {
                reloadTimelineItems()
            }
        }
    }

    private func updateDateRange(from date: Date) {
        // Set date range to a single day
        startDate = Calendar.current.startOfDay(for: date)
        endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        isDateRangeActive = true
    }
    
    private func filterColor(for filter: SearchFilter) -> Color {
        switch filter {
        case .all, .symptoms, .remedies:
            return .blue
        case .mild:
            return .yellow
        case .moderate:
            return .orange
        case .severe:
            return .red
        case .extreme:
            return .purple
        case .resolved:
            return .green
        }
    }
    
    // Export Timeline Functions
    private func exportTimeline(from startDate: Date, to endDate: Date) {
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
                    details: (symptom.isResolved ? "Resolved" : "Severity: \(symptom.severityEnum.displayName)") + (symptom.notes != nil ? " - \(symptom.notes!)" : ""),
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


// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
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


