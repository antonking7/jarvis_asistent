//
//  ChatDetailView.swift
//  Jarvis
//
//  Created by Антон Николаев on 16/12/2024.
//

import SwiftUI
import SwiftData
import Foundation

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ChatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    let chat: Chat
    @State private var messageText: String = ""
    @State private var llmService: LLMService
    @StateObject private var speechRecognizer = SpeechRecognitionService()
    @State private var isRecording = false
    @State private var hasRecordingPermission = false
    @State private var recognizedText: String = ""
    @GestureState private var isLongPressing = false
    private let speechSynthesizer = SpeechSynthesizer()
    @State private var shouldSpeak = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var textHeight: CGFloat = 40
    
    private let minHeight: CGFloat = 40
    private let maxHeight: CGFloat = 120

    init(chat: Chat) {
        self.chat = chat
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
                ZStack(alignment: .leading) {
                    TextEditor(text: $messageText)
                        .frame(height: textHeight)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ViewHeightKey.self,
                                    value: geometry.size.height
                                )
                            }
                        )
                        .focused($isTextFieldFocused)
                    
                    if messageText.isEmpty {
                        Text("Введите сообщение...")
                            .foregroundColor(.gray)
                            .padding(.leading, 5)
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.leading)
                
                HStack(spacing: 8) {
                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isRecording ? .red : .blue)
                            .symbolEffect(.bounce, value: isRecording)
                    }
                    
                    Button(action: sendWithHaptic) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isRecording)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            .onPreferenceChange(ViewHeightKey.self) { height in
                textHeight = min(max(minHeight, height), maxHeight)
            }
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        isTextFieldFocused = false
                    }
            )
        }
        .navigationTitle(chat.name)
        .onAppear {
            if let currentSettings = settings.first {
                llmService.updateServerUrl(currentSettings.serverUrl)
            }
            
            speechRecognizer.requestAuthorization { authorized in
                hasRecordingPermission = authorized
            }
            
            speechRecognizer.onRecognizedText = { text in
                messageText = text
                recognizedText = text
            }
        }
        .onChange(of: settings) { _, newSettings in
            if let currentSettings = newSettings.first {
                llmService.updateServerUrl(currentSettings.serverUrl)
            }
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if isRecording {
            speechRecognizer.stopRecording()
            isRecording = false
        }
        
        withAnimation {
            let userMessage = Message(role: "user", content: messageText)
            chat.messages.append(userMessage)
            modelContext.insert(userMessage)
            
            let assistantMessage = Message(role: "assistant", content: "", isPrinting: true)
            chat.messages.append(assistantMessage)
            modelContext.insert(assistantMessage)
            
            shouldSpeak = false
            
            llmService.fetchResponse(
                for: messageText,
                withContext: Array(chat.messages.dropLast()),
                onComplete: { completed in
                    shouldSpeak = completed
                    
                    if completed {
                        if let currentSettings = settings.first,
                           currentSettings.speakResponses == true {
                            print("Начинаю озвучивание полного ответа: \(assistantMessage.content)")
                            self.speechSynthesizer.speak(assistantMessage.content)
                        }
                    }
                }
            ) { response in
                DispatchQueue.main.async {
                    assistantMessage.content = response
                    assistantMessage.isPrinting = !shouldSpeak
                    
                    do {
                        try modelContext.save()
                    } catch {
                        print("Не удалось сохранить изменения: \(error)")
                    }
                }
            }
            messageText = ""
            recognizedText = ""
        }
    }

    private func copyMessage(_ message: Message) -> () -> Void {
        return {
            UIPasteboard.general.string = message.content
        }
    }

    private func startRecording() {
        guard !isRecording else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        do {
            recognizedText = ""
            messageText = ""
            try speechRecognizer.startRecording()
            isRecording = true
            isTextFieldFocused = false
        } catch {
            print("Ошибка начала записи: \(error)")
        }
    }

    private func stopRecordingAndSend() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        speechRecognizer.stopRecording()
        isRecording = false
        messageText = recognizedText
        
        if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sendMessage()
        }
    }

    private func toggleRecording() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if isRecording {
            stopRecordingAndSend()
        } else {
            startRecording()
        }
    }
    
    private func sendWithHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        sendMessage()
    }
}
