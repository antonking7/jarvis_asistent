//
//  JarvisApp.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//

import SwiftUI
import SwiftData
import Foundation

@main
struct JarvisApp: App {
//    init() {
//        // Удаляем старую базу данных при запуске
//        deleteOldDatabase()
//    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Chat.self,
            Message.self,
            Settings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }()
    
    private func deleteOldDatabase() {
        if let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let databaseURL = appSupportDirectory.appendingPathComponent("default.store")
            if FileManager.default.fileExists(atPath: databaseURL.path) {
                do {
                    try FileManager.default.removeItem(at: databaseURL)
                    print("Старая база данных успешно удалена")
                } catch {
                    print("Ошибка удаления базы данных: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ChatListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
