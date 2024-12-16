//
//  Chat.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//


// Chat.swift
import Foundation
import SwiftData

@Model
final class Chat {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var timestamp: Date = Date()
    @Relationship(deleteRule: .cascade) var messages: [Message] = []

    init(name: String, messages: [Message] = []) {
        self.name = name
        self.messages = messages
    }
}
