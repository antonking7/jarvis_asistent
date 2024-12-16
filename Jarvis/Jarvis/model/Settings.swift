import Foundation
import SwiftData

@Model
final class Settings {
    var serverHost: String
    var serverPort: String
    @Attribute var speakResponses: Bool?
    
    init(serverHost: String = "localhost", serverPort: String = "1234", speakResponses: Bool? = false) {
        self.serverHost = serverHost
        self.serverPort = serverPort
        self.speakResponses = speakResponses
    }
    
    var serverUrl: String {
        "http://\(serverHost):\(serverPort)/v1/chat/completions"
    }
} 