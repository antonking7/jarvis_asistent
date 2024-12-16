//
//  Message.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//

import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID = UUID()
    var role: String? // "user" или "assistant"
    var content: String
    var timestamp: Date
    var isPrinting: Bool = false

    init(role: String, content: String, timestamp: Date = Date(), isPrinting: Bool = false) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isPrinting = isPrinting
    }
}
