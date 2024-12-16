import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    
    @State private var serverHost: String = ""
    @State private var serverPort: String = ""
    
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
        } else {
            // Создаем настройки по умолчанию, если их нет
            let defaultSettings = Settings()
            modelContext.insert(defaultSettings)
            serverHost = defaultSettings.serverHost
            serverPort = defaultSettings.serverPort
        }
    }
    
    private func saveSettings() {
        if let currentSettings = settings.first {
            currentSettings.serverHost = serverHost
            currentSettings.serverPort = serverPort
        } else {
            let newSettings = Settings(serverHost: serverHost, serverPort: serverPort)
            modelContext.insert(newSettings)
        }
        
        try? modelContext.save()
    }
} 