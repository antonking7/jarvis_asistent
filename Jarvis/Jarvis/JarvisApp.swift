//
//  JarvisApp.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//

// JarvisApp.swift (updated)
import SwiftUI
import SwiftData

@main
struct JarvisApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Chat.self,
            Message.self,
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
            ChatListView()
        }
        .modelContainer(sharedModelContainer)
    }
}

