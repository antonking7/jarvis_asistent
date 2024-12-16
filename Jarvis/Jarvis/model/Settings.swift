import Foundation
import SwiftData

@Model
final class Settings {
    var serverHost: String
    var serverPort: String
    
    init(serverHost: String = "localhost", serverPort: String = "1234") {
        self.serverHost = serverHost
        self.serverPort = serverPort
    }
    
    var serverUrl: String {
        "http://\(serverHost):\(serverPort)/v1/chat/completions"
    }
} 