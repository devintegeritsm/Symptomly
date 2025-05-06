//
//  App.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/6/25.
//

import SwiftUI
import SwiftData


@main
struct SymptomlyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Symptom.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DailySymptomView()
        }
        .modelContainer(sharedModelContainer)
    }
} 
