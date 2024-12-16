import SwiftUI

struct MessageView: View {
    let message: Message
    let isFromUser: Bool
    
    var body: some View {
        HStack {
            if isFromUser {
                Spacer()
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                Text(isFromUser ? "Пользователь" : "Jarvis")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(message.content)
                    .padding(10)
                    .background(isFromUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
            
            if !isFromUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
} 