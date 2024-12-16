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
    @State private var editedChatIndex: Int? // Индекс редактируемого чата
    @State private var newName: String = ""

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(chats.indices, id: \.self) { index in
                    if let editedIndex = editedChatIndex, editedIndex == index {
                        HStack {
                            TextField("Rename Chat", text: $newName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    renameChat(index: index, newName: newName)
                                }
                            Button(action: {
                                renameChat(index: index, newName: newName)
                            }) {
                                Image(systemName: "checkmark")
                            }
                        }
                    } else {
                        NavigationLink {
                            ChatDetailView(chat: chats[index])
                        } label: {
                            Text(chats[index].name)
                        }
                        .contextMenu {
                            Button(action: {
                                startEditing(index: index)
                            }) {
                                Label("Rename Chat", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                deleteChats(offsets: IndexSet(integer: index))
                            }) {
                                Label("Delete Chat", systemImage: "trash")
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
                                editedChatIndex = nil // Сброс редактируемого индекса при выходе из режима редактирования
                            }
                        }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addChat) {
                        Label("Add Chat", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select a chat")
        }
    }

    private func startEditing(index: Int) {
        editedChatIndex = index
        newName = chats[index].name
    }

    private func renameChat(index: Int, newName: String) {
        guard !newName.isEmpty else { return } // Проверка на пустое имя
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !chats.contains(where: { $0.name == trimmedNewName && $0.id != chats[index].id }) {
            chats[index].name = trimmedNewName
            modelContext.insert(chats[index]) // Обновление модели
        } else {
            print("Chat with this name already exists")
        }
        
        editedChatIndex = nil
    }

    private func addChat() {
        withAnimation {
            let newChat = Chat(name: "New Chat")
            modelContext.insert(newChat)
        }
    }

    private func deleteChats(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(chats[index])
            }
        }
    }
}

#Preview {
    ChatListView()
        .modelContainer(for: [Chat.self, Message.self], inMemory: true)
}
