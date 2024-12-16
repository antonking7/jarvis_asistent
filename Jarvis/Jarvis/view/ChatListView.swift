//
//  ChatListView.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//

import SwiftUI
import SwiftData

struct ChatListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Chat.timestamp, order: .reverse)]) private var chats: [Chat]
    @State private var editing = false
    @State private var editedChatID: UUID? // Идентификатор редактируемого чата
    @State private var newName: String = ""

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(chats) { chat in
                    if let editedID = editedChatID, editedID == chat.id {
                        HStack {
                            TextField("Переименовать чат", text: $newName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    renameChat(chat: chat, newName: newName)
                                }
                            Button(action: {
                                renameChat(chat: chat, newName: newName)
                            }) {
                                Image(systemName: "checkmark")
                            }
                        }
                    } else {
                        NavigationLink {
                            ChatDetailView(chat: chat)
                        } label: {
                            Text(chat.name)
                        }
                        .contextMenu {
                            Button(action: {
                                startEditing(chat: chat)
                            }) {
                                Label("Переименовать чат", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                deleteChat(chat: chat)
                            }) {
                                Label("Удалить чат", systemImage: "trash")
                            }
                        }
                    }
                }
                .onDelete(perform: deleteChats)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled(chats.isEmpty)
                        .onChange(of: editing) { newValue, _ in
                            self.editing = newValue
                            if !newValue {
                                editedChatID = nil // Сброс редактируемого чата при выходе из режима редактирования
                            }
                        }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addChat) {
                        Label("Добавить чат", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Выберите чат")
        }
    }

    private func startEditing(chat: Chat) {
        editedChatID = chat.id
        newName = chat.name
    }

    private func renameChat(chat: Chat, newName: String) {
        guard !newName.isEmpty else { return } // Проверка на пустое имя
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !chats.contains(where: { $0.name == trimmedNewName && $0.id != chat.id }) {
            chat.name = trimmedNewName
            modelContext.insert(chat) // Обновление модели
            do {
                try modelContext.save() // Явное сохранение изменений
            } catch {
                print("Не удалось сохранить изменения: \(error)")
            }
        } else {
            print("Чат с таким именем уже существует")
        }
        
        editedChatID = nil
    }

    private func addChat() {
        withAnimation {
            let newChat = Chat(name: "Новый чат")
            modelContext.insert(newChat)
            do {
                try modelContext.save() // Явное сохранение изменений
            } catch {
                print("Не удалось сохранить изменения: \(error)")
            }
        }
    }

    private func deleteChat(chat: Chat) {
        withAnimation {
            modelContext.delete(chat)
            do {
                try modelContext.save() // Явное сохранение изменений
            } catch {
                print("Не удалось сохранить изменения: \(error)")
            }
        }
    }

    private func deleteChats(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                if index < chats.count { // Проверка, чтобы индекс был в допустимом диапазоне
                    let chatToDelete = chats[index]
                    modelContext.delete(chatToDelete)
                    do {
                        try modelContext.save() // Явное сохранение изменений
                    } catch {
                        print("Не удалось сохранить изменения: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    ChatListView()
        .modelContainer(for: [Chat.self, Message.self], inMemory: true)
}
