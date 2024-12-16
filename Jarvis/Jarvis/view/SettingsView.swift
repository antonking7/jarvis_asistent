import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    
    @State private var serverHost: String = ""
    @State private var serverPort: String = ""
    @State private var speakResponses: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Настройки сервера")) {
                    TextField("Адрес сервера", text: $serverHost)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Порт", text: $serverPort)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Голосовые настройки")) {
                    Toggle("Озвучивать ответы", isOn: $speakResponses)
                }
                
                Section {
                    Button("Сохранить") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarItems(trailing: Button("Закрыть") {
                dismiss()
            })
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private func loadSettings() {
        if let currentSettings = settings.first {
            serverHost = currentSettings.serverHost
            serverPort = currentSettings.serverPort
            speakResponses = currentSettings.speakResponses ?? false
        } else {
            let defaultSettings = Settings()
            modelContext.insert(defaultSettings)
            serverHost = defaultSettings.serverHost
            serverPort = defaultSettings.serverPort
            speakResponses = defaultSettings.speakResponses ?? false
        }
    }
    
    private func saveSettings() {
        print("Сохраняю настройки, озвучивание: \(speakResponses)")
        
        if let currentSettings = settings.first {
            currentSettings.serverHost = serverHost
            currentSettings.serverPort = serverPort
            currentSettings.speakResponses = speakResponses
            print("Обновлены существующие настройки")
        } else {
            let newSettings = Settings(
                serverHost: serverHost,
                serverPort: serverPort,
                speakResponses: speakResponses
            )
            modelContext.insert(newSettings)
            print("Созданы новые настройки")
        }
        
        do {
            try modelContext.save()
            print("Настройки успешно сохранены")
        } catch {
            print("Ошибка сохранения настроек: \(error)")
        }
    }
} 