//
//  ChatDetailView.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//

import SwiftUI
import SwiftData
import Foundation

struct ChatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    let chat: Chat
    @State private var messageText: String = ""
    @State private var llmService: LLMService

    init(chat: Chat) {
        self.chat = chat
        // Инициализируем LLMService с дефолтным URL
        _llmService = State(initialValue: LLMService())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(chat.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                            MessageView(
                                message: message,
                                isFromUser: message.role == "user"
                            )
                            .id(message.id)
                            .contextMenu {
                                Button(action: copyMessage(message)) {
                                    Label("Копировать", systemImage: "doc.on.doc")
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: chat.messages.count) { _, _ in
                    if let lastMessage = chat.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                TextField("Введите сообщение...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
        .navigationTitle(chat.name)
        .onAppear {
            // Обновляем URL при появлении view
            if let currentSettings = settings.first {
                llmService.updateServerUrl(currentSettings.serverUrl)
            }
        }
        .onChange(of: settings) { _, newSettings in
            // Обновляем URL при изменении настроек
            if let currentSettings = newSettings.first {
                llmService.updateServerUrl(currentSettings.serverUrl)
            }
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        withAnimation {
            let userMessage = Message(role: "user", content: messageText)
            chat.messages.append(userMessage)
            modelContext.insert(userMessage)

            let assistantMessage = Message(role: "assistant", content: "", isPrinting: true)
            chat.messages.append(assistantMessage)
            modelContext.insert(assistantMessage)
            
            llmService.fetchResponse(
                for: messageText,
                withContext: Array(chat.messages.dropLast())
            ) { response in
                DispatchQueue.main.async {
                    assistantMessage.content = response
                    assistantMessage.isPrinting = response.isEmpty
                    
                    do {
                        try modelContext.save()
                    } catch {
                        print("Не удалось сохранить изменения: \(error)")
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
