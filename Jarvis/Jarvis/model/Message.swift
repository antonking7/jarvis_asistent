//
//  Message.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//


// Message.swift
import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID = UUID()
    var content: String
    var timestamp: Date
    
    init(content: String, timestamp: Date = Date()) {
        self.content = content
        self.timestamp = timestamp
    }
}
