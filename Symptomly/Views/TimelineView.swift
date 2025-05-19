import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Combine

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
    
    // Pagination state
    @State private var pageSize = 50
    @State private var currentPage = 0
    @State private var hasMoreItems = true
    @State private var isLoading = false
    @State private var timelineItems: [TimelineItem] = []
    @State private var totalItemCount = 0
    
    // Cancellables for async operations
    private var cancellables = Set<AnyCancellable>()
    
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
                            if !isSearching {
                                searchText = ""
                                searchFilter = .all
                                resetAndReloadData()
                            }
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
                                    resetAndReloadData()
                                }
                            )
//                            .frame(width: 320, height: 610)
//                            .padding()
//                            .presentationDetents([.height(630)])
//                            .presentationDragIndicator(.visible)
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
            //                .frame(width: 340, height: 700)
            //                .padding()
            //                .presentationDetents([.height(720)])
            //                .presentationDragIndicator(.visible)
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
                            resetAndReloadData()
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
                                .onSubmit {
                                    resetAndReloadData()
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    resetAndReloadData()
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
                                        resetAndReloadData()
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
                if timelineItems.isEmpty && !isLoading {
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
                    List {
                        ForEach(timelineItems) { item in
                            TimelineItemRow(item: item)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .onAppear {
                                    // Load more when we're near the end
                                    if item.id == timelineItems.last?.id && hasMoreItems && !isLoading {
                                        loadNextPage()
                                    }
                                }
                        }
                        
                        if hasMoreItems && !timelineItems.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .onAppear {
                                loadNextPage()
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(.systemGroupedBackground))
                    .overlay(
                        Group {
                            if isLoading && timelineItems.isEmpty {
                                ProgressView("Loading timeline...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .background(Color(.systemBackground).opacity(0.8))
                                    .cornerRadius(10)
                                    .padding()
                            }
                        }
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dateSelected)) { notification in
                if let selectedDate = notification.userInfo?["selectedDate"] as? Date {
                    self.selectedDate = selectedDate
                    updateDateRange(from: selectedDate)
                    resetAndReloadData()
                }
            }
            //
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
            .task {
                await countTotalItems()
                resetAndReloadData()
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func resetAndReloadData() {
        timelineItems = []
        currentPage = 0
        hasMoreItems = true
        loadNextPage()
    }
    
    private func loadNextPage() {
        guard hasMoreItems && !isLoading else { return }
        
        isLoading = true
        
        // Perform the data loading on a background thread
        Task {
            // Fetch symptoms with predicates
            let symptomPredicate = buildSymptomPredicate()
            let symptomDescriptor = buildSymptomFetchDescriptor(predicate: symptomPredicate)
            
            // Fetch remedies with predicates
            let remedyPredicate = buildRemedyPredicate()
            let remedyDescriptor = buildRemedyFetchDescriptor(predicate: remedyPredicate)
            
            // Perform both fetches
            let symptoms = (try? modelContext.fetch(symptomDescriptor)) ?? []
            let remedies = (try? modelContext.fetch(remedyDescriptor)) ?? []
            
            // Process the fetched data into timeline items
            var newItems: [TimelineItem] = []
            
            // Create timeline items
            for symptom in symptoms {
                newItems.append(TimelineItem(
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
            
            for remedy in remedies {
                newItems.append(TimelineItem(
                    timestamp: remedy.takenTimestamp,
                    type: .remedy,
                    name: remedy.name,
                    details: "Potency: \(remedy.displayPotency)" + (remedy.notes != nil ? " - \(remedy.notes!)" : ""),
                    color: .blue
                ))
            }
            
            // Sort combined items by timestamp (descending)
            newItems.sort { $0.timestamp > $1.timestamp }
            
            // Update UI on main thread
            await MainActor.run {
                if !newItems.isEmpty {
                    timelineItems.append(contentsOf: newItems)
                    currentPage += 1
                }
                
                // Check if we've reached the end
                hasMoreItems = newItems.count >= pageSize
                isLoading = false
            }
        }
    }
    
    private func countTotalItems() async {
        let symptomPredicate = buildSymptomPredicate()
        let remedyPredicate = buildRemedyPredicate()
        
        // Use count descriptors
        var symptomDescriptor = FetchDescriptor<Symptom>(predicate: symptomPredicate)
        var remedyDescriptor = FetchDescriptor<Remedy>(predicate: remedyPredicate)
        
        // For counting only
        symptomDescriptor.fetchLimit = 0
        remedyDescriptor.fetchLimit = 0
        
        let symptomCount = (try? modelContext.fetchCount(symptomDescriptor)) ?? 0
        let remedyCount = (try? modelContext.fetchCount(remedyDescriptor)) ?? 0
        
        await MainActor.run {
            self.totalItemCount = symptomCount + remedyCount
            
            // Adjust page size based on total count
            if totalItemCount > 1000 {
                self.pageSize = 30
            } else if totalItemCount > 500 {
                self.pageSize = 40
            } else {
                self.pageSize = 50
            }
        }
    }
    
    // MARK: - Predicate Builders
    
    private func buildSymptomPredicate() -> Predicate<Symptom> {
        var predicates: [Predicate<Symptom>] = []
        
        // Date range filter
        if isDateRangeActive {
            let dateRangePredicate = #Predicate<Symptom> {
                $0.timestamp >= startDate && $0.timestamp <= endDate
            }
            predicates.append(dateRangePredicate)
        }
        
        // Search text filter
        if !searchText.isEmpty {
            let searchTextLowercased = searchText.lowercased()
            let textPredicate = #Predicate<Symptom> {
                $0.name.localizedStandardContains(searchTextLowercased) ||
                ($0.notes != nil && $0.notes!.localizedStandardContains(searchTextLowercased))
            }
            predicates.append(textPredicate)
        }
        
        // Search filter category
        switch searchFilter {
        case .symptoms:
            // Already getting symptoms, no additional predicate needed
            break
        case .remedies:
            // Exclude all symptoms by using an always-false predicate
            return #Predicate<Symptom> { _ in false }
        case .mild:
            predicates.append(#Predicate<Symptom> { $0.severity == 1 })
        case .moderate:
            predicates.append(#Predicate<Symptom> { $0.severity == 2 })
        case .severe:
            predicates.append(#Predicate<Symptom> { $0.severity == 3 })
        case .extreme:
            predicates.append(#Predicate<Symptom> { $0.severity == 4 })
        case .resolved:
            predicates.append(#Predicate<Symptom> { $0.severity == 0 })
        case .all:
            break
        }
        
        // Combine all predicates with AND
        if predicates.isEmpty {
            return #Predicate<Symptom> { _ in true }
        } else if predicates.count == 1 {
            return predicates[0]
        } else {
            // Combine predicates properly
            var finalPredicate = predicates[0]
            for i in 1..<predicates.count {
                finalPredicate = #Predicate<Symptom> {
                    predicates[0].evaluate($0) && predicates[i].evaluate($0)
                }
            }
            return finalPredicate
        }
    }
    
    private func buildRemedyPredicate() -> Predicate<Remedy> {
        var predicates: [Predicate<Remedy>] = []
        
        // Date range filter
        if isDateRangeActive {
            let dateRangePredicate = #Predicate<Remedy> {
                $0.takenTimestamp >= startDate && $0.takenTimestamp <= endDate
            }
            predicates.append(dateRangePredicate)
        }
        
        // Search text filter
        if !searchText.isEmpty {
            let searchTextLowercased = searchText.lowercased()
            let textPredicate = #Predicate<Remedy> {
                $0.name.localizedStandardContains(searchTextLowercased) ||
                ($0.notes != nil && $0.notes!.localizedStandardContains(searchTextLowercased)) ||
                $0.potency.localizedStandardContains(searchTextLowercased) ||
                ($0.customPotency != nil && $0.customPotency!.localizedStandardContains(searchTextLowercased))
            }
            predicates.append(textPredicate)
        }
        
        // Search filter category
        switch searchFilter {
        case .remedies:
            // Already getting remedies, no additional predicate needed
            break
        case .symptoms, .mild, .moderate, .severe, .extreme, .resolved:
            // Exclude all remedies
            return #Predicate<Remedy> { _ in false }
        case .all:
            break
        }
        
        // Combine all predicates with AND
        if predicates.isEmpty {
            return #Predicate<Remedy> { _ in true }
        } else if predicates.count == 1 {
            return predicates[0]
        } else {
            // Combine predicates properly
            var finalPredicate = predicates[0]
            for i in 1..<predicates.count {
                finalPredicate = #Predicate<Remedy> {
                    predicates[0].evaluate($0) && predicates[i].evaluate($0)
                }
            }
            return finalPredicate
        }
    }
    
    private func buildSymptomFetchDescriptor(predicate: Predicate<Symptom>) -> FetchDescriptor<Symptom> {
        var descriptor = FetchDescriptor<Symptom>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        descriptor.fetchOffset = currentPage * pageSize
        descriptor.fetchLimit = pageSize
        return descriptor
    }
    
    private func buildRemedyFetchDescriptor(predicate: Predicate<Remedy>) -> FetchDescriptor<Remedy> {
        var descriptor = FetchDescriptor<Remedy>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.takenTimestamp, order: .reverse)]
        descriptor.fetchOffset = currentPage * pageSize
        descriptor.fetchLimit = pageSize
        return descriptor
    }
    
    // MARK: - Helper Methods
    
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
    
    // MARK: - Export Timeline Functions
    
    private func exportTimeline(from startDate: Date, to endDate: Date) {
        self.exportStartDate = startDate
        self.exportEndDate = endDate
        
        // Use a background task for export
        Task {
            // Generate markdown in the background
            let markdown = await generateMarkdown(from: startDate, to: endDate)
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
                
                // Update UI on main thread
                await MainActor.run {
                    // Set URL which will trigger the sheet presentation via onChange
                    self.exportedFileURL = url
                }
                
            } catch {
                print("Error setting resource value: \(error)")
            }
        }
    }
    
    private func generateMarkdown(from startDate: Date, to endDate: Date) async -> String {
        // Find all items in the date range using optimized queries
        let symptomPredicate = #Predicate<Symptom> { 
            $0.timestamp >= startDate && $0.timestamp <= endDate
        }
        let remedyPredicate = #Predicate<Remedy> {
            $0.takenTimestamp >= startDate && $0.takenTimestamp <= endDate
        }
        
        var symptomDescriptor = FetchDescriptor<Symptom>(predicate: symptomPredicate)
        var remedyDescriptor = FetchDescriptor<Remedy>(predicate: remedyPredicate)
        
        symptomDescriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        remedyDescriptor.sortBy = [SortDescriptor(\.takenTimestamp, order: .reverse)]
        
        // Fetch the data
        let exportSymptoms = (try? modelContext.fetch(symptomDescriptor)) ?? []
        let exportRemedies = (try? modelContext.fetch(remedyDescriptor)) ?? []
        
        // Process into timeline items
        var allItems: [TimelineItem] = []
        
        // Process symptoms
        for symptom in exportSymptoms {
            allItems.append(TimelineItem(
                timestamp: symptom.timestamp,
                type: .symptom,
                name: symptom.name,
                details: (symptom.isResolved ? "Resolved" : "Severity: \(symptom.severityEnum.displayName)") + (symptom.notes != nil ? " - \(symptom.notes!)" : ""),
                color: symptom.severityEnum.color
            ))
        }
        
        // Process remedies
        for remedy in exportRemedies {
            allItems.append(TimelineItem(
                timestamp: remedy.takenTimestamp,
                type: .remedy,
                name: remedy.name,
                details: "Potency: \(remedy.displayPotency)" + (remedy.notes != nil ? " - \(remedy.notes!)" : ""),
                color: .blue
            ))
        }
        
        // Sort by timestamp
        allItems.sort { $0.timestamp > $1.timestamp }
        
        // Generate markdown content
        let calendar = Calendar.current
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


