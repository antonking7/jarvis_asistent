//
//  ChatDetailView.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//


// ChatDetailView.swift
import SwiftUI
import SwiftData

struct ChatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let chat: Chat
    @State private var messageText: String = ""

    var body: some View {
        VStack {
            List(chat.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                Text(message.content)
                    .contextMenu {
                        Button(action: copyMessage(message)) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        // Add other options as needed (delete, etc.)
                    }
            }
            HStack {
                TextField("Type a message...", text: $messageText)
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
            let newMessage = Message(content: messageText)
            chat.messages.append(newMessage)
            modelContext.insert(newMessage)
            messageText = ""
        }
    }

    private func copyMessage(_ message: Message) -> () -> Void {
        return {
            UIPasteboard.general.string = message.content
        }
    }
}
