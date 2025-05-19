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