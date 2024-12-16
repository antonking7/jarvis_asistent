import Foundation
import SwiftData

final class LLMService: NSObject, URLSessionDataDelegate {
    private var serverUrl: String
    private let maxTokens = 25000
    private let averageCharsPerToken = 4
    private var responseBuffer = ""
    private var currentCompletion: ((String) -> Void)?
    private var accumulatedResponse = ""
    private var onComplete: ((Bool) -> Void)?
    
    init(serverUrl: String = "http://localhost:1234/v1/chat/completions") {
        self.serverUrl = serverUrl
        super.init()
    }
    
    func updateServerUrl(_ newUrl: String) {
        self.serverUrl = newUrl
    }
    
    private func prepareMessages(_ messages: [Message]) -> [[String: String]] {
        var result: [[String: String]] = []
        var currentTokenCount = 0
        
        for message in messages.reversed() {
            let messageTokens = message.content.count / averageCharsPerToken
            if currentTokenCount + messageTokens > maxTokens {
                break
            }
            result.insert([
                "role": message.role ?? "user",
                "content": message.content
            ], at: 0)
            currentTokenCount += messageTokens
        }
        return result
    }
    
    func fetchResponse(
        for prompt: String, 
        withContext messages: [Message], 
        onComplete: @escaping (Bool) -> Void,
        completion: @escaping (String) -> Void
    ) {
        guard let endpoint = URL(string: serverUrl) else {
            completion("Ошибка: неверный URL сервера")
            return
        }
        
        accumulatedResponse = ""
        currentCompletion = completion
        responseBuffer = ""
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let contextMessages = prepareMessages(messages)
        let body: [String: Any] = [
            "model": "qwen2.5-coder-32b-instruct",
            "messages": contextMessages + [["role": "user", "content": prompt]],
            "stream": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("Отправляем запрос с телом: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request)
        
        self.onComplete = { completed in
            DispatchQueue.main.async {
                onComplete(completed)
            }
        }
        
        task.resume()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let str = String(data: data, encoding: .utf8) else { return }
        print("Получены данные: \(str)")
        
        responseBuffer += str
        let lines = responseBuffer.components(separatedBy: "\n")
        
        for line in lines.dropLast() {
            processLine(line)
        }
        
        responseBuffer = lines.last ?? ""
    }
    
    private func processLine(_ line: String) {
        guard !line.isEmpty else { return }
        
        if line == "data: [DONE]" {
            print("Получен маркер завершения")
            DispatchQueue.main.async {
                self.onComplete?(true)
            }
            return
        }
        
        guard line.hasPrefix("data: ") else { return }
        let jsonString = String(line.dropFirst(6))
        
        do {
            if let jsonData = jsonString.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let delta = firstChoice["delta"] as? [String: Any],
               let content = delta["content"] as? String {
                accumulatedResponse += content
                print("Получена часть ответа: \(content)")
                currentCompletion?(accumulatedResponse)
            }
        } catch {
            print("Ошибка парсинга JSON: \(error)")
            print("Проблемная строка: \(jsonString)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Ошибка сессии: \(error)")
            currentCompletion?("Извините, произошла ошибка при обработке запроса.")
        } else {
            print("Сессия завершена успешно")
            if !responseBuffer.isEmpty {
                processLine(responseBuffer)
            }
        }
        
        // Очищаем состояние
        responseBuffer = ""
        currentCompletion = nil
    }
} 