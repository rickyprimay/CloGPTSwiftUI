//
//  ContentView.swift
//  CloGpts
//
//  Created by Ricky Primayuda Putra on 02/12/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State var chatMessage: [ChatMessage] = []
    @State var messageText: String = ""
    @StateObject var vm = OpenAIViewModel()
    @State var cancellables: Set<AnyCancellable> = []
    
    var body: some View {
        VStack {
            ScrollView{
                LazyVStack {
                    ForEach(chatMessage, id: \.id) { message in
                        messageView(message: message)
                    }
                }
            }
            HStack {
                TextField("Enter a message", text: $messageText)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Button {
                    sendMessage()
                } label: {
                    Text("Send")
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    func messageView(message: ChatMessage) -> some View {
        HStack {
            if message.sender == .me { Spacer() }
            Text(message.content)
                .foregroundStyle(message.sender == .me ? .white : .black)
                .padding()
                .background(message.sender == .me ? .blue : .gray.opacity(0.1))
                .cornerRadius(10)
            if message.sender == .gpt { Spacer() }
        }
    }
    
    func sendMessage() {
        let myMessage = ChatMessage(id: UUID().uuidString, content: messageText, dateCreated: Date(), sender: .me)
        chatMessage.append(myMessage)
        
        vm.sendMessage(message: messageText)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Error sending message: \(error.localizedDescription)")
                case .finished:
                    break
                }
            } receiveValue: { response in
                if let textResponse = response.choices.first?.text {
                    let gptMessage = ChatMessage(id: response.id, content: textResponse.trimmingCharacters(in: .whitespacesAndNewlines), dateCreated: Date(), sender: .gpt)
                    chatMessage.append(gptMessage)
                }
            }
            .store(in: &cancellables)
        
        messageText = ""
    }
}

#Preview {
    ContentView()
}

struct ChatMessage {
    var id: String
    var content: String
    var dateCreated: Date
    var sender: MessageSender
}

enum MessageSender {
    case me
    case gpt
}
