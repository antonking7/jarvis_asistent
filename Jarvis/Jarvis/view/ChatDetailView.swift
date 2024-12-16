//
//  ChatDetailView.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//

import SwiftUI
import SwiftData

struct ChatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let chat: Chat
    @State private var messageText: String = ""
    @State private var llmService = LLMService()

    var body: some View {
        VStack {
            List(chat.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                Text(message.content)
                    .contextMenu {
                        Button(action: copyMessage(message)) {
                            Label("Копировать", systemImage: "doc.on.doc")
                        }
                        // Добавьте другие опции по мере необходимости (удаление и т.д.)
                    }
            }
            HStack {
                TextField("Введите сообщение...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle(chat.name)
    }

    private func sendMessage() {
        withAnimation {
            // Создаём сообщение пользователя
            let userMessage = Message(role: "user", content: messageText)
            chat.messages.append(userMessage)
            modelContext.insert(userMessage)

            // Создаём сообщение ассистента
            let assistantMessage = Message(role: "assistant", content: "", isPrinting: true)
            chat.messages.append(assistantMessage)
            modelContext.insert(assistantMessage)

            llmService.fetchResponse(for: messageText) { response in
                DispatchQueue.main.async {
                    assistantMessage.content = ""
                    for (index, char) in response.enumerated() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(index)) {
                            assistantMessage.content.append(char)
                            if index == response.count - 1 {
                                assistantMessage.isPrinting = false
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Не удалось сохранить изменения: \(error)")
                                }
                            }
                        }
                    }
                }
            }
            messageText = ""
        }
    }

    private func copyMessage(_ message: Message) -> () -> Void {
        return {
            UIPasteboard.general.string = message.content
        }
    }
}

final class LLMService {
    private let endpoint = URL(string: "http://localhost:1234/v1/chat/completions")!

    func fetchResponse(for prompt: String, completion: @escaping (String) -> Void) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "qwen2.5-coder-32b-instruct",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Ошибка сети: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                return
            }

            do {
                // Декодируем JSON и извлекаем "content"
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content) // Передаём "content" в замыкание
                } else {
                    print("Неправильный формат ответа")
                }
            } catch {
                print("Ошибка декодирования JSON: \(error)")
            }
        }
        task.resume()
    }
}
