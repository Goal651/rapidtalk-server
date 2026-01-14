//
//  MainSocket.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor
import Fluent
import JWT

enum MainSocket {
    nonisolated(unsafe) static var connections: [UUID: WebSocket] = [:]

    static func register(on app: Application) {
        app.webSocket("ws") { req, ws in
            guard let token = req.query[String.self, at: "token"],
                  let payload = try? req.jwt.verify(token, as: SessionPayload.self) else {
                ws.close(promise: nil)
                return
            }

            let userId = payload.userId
            connections[userId] = ws

            // Broadcast online status
            broadcastStatus(userId: userId, online: true, on: app)

            ws.onText { ws, text in
                handleIncomingMessage(text, from: userId, on: app)
            }

            ws.onClose.whenComplete { _ in
                connections.removeValue(forKey: userId)
                broadcastStatus(userId: userId, online: false, on: app)
            }
        }
    }

    private static func handleIncomingMessage(_ text: String, from userId: UUID, on app: Application) {
        guard let data = text.data(using: .utf8),
              let wsEvent = try? JSONDecoder().decode(WsEvent.self, from: data) else { return }

        switch wsEvent.type {
        case "chat_message":
            if let payload = try? JSONDecoder().decode(ChatMessagePayload.self, from: data) {
                saveAndBroadcastMessage(payload, from: userId, on: app)
            }
        case "typing":
            if let payload = try? JSONDecoder().decode(TypingPayload.self, from: data) {
                broadcastEvent(type: "typing", data: payload, to: payload.receiverId)
            }
        case "message_read":
            if let payload = try? JSONDecoder().decode(ReadPayload.self, from: data) {
                broadcastEvent(type: "message_read", data: payload, to: payload.senderId)
            }
        case "reaction":
            if let payload = try? JSONDecoder().decode(ReactionWsPayload.self, from: data) {
                saveAndBroadcastReaction(payload, from: userId, on: app)
            }
        default:
            break
        }
    }

    private static func saveAndBroadcastReaction(_ payload: ReactionWsPayload, from userId: UUID, on app: Application) {
        let reaction = Reaction(
            emoji: payload.emoji,
            userId: userId,
            messageId: payload.messageId
        )

        reaction.save(on: app.db).flatMap {
            // Find who needs to know about this reaction (the recipient of the original message OR the sender)
            // For simplicity, we can broadcast to the original recipient. 
            // Better: find the message to get both parties.
            Message.find(payload.messageId, on: app.db).map { message in
                guard let message = message else { return }
                
                let response = WsResponse(success: true, data: reaction, message: "reaction")
                if let responseData = try? JSONEncoder().encode(response),
                   let responseString = String(data: responseData, encoding: .utf8) {
                    
                    // Send to both parties involved in the conversation
                    connections[message.$sender.id]?.send(responseString)
                    connections[message.$receiver.id]?.send(responseString)
                }
            }
        }.whenComplete { _ in }
    }

    private static func saveAndBroadcastMessage(_ payload: ChatMessagePayload, from senderId: UUID, on app: Application) {
        let message = Message(
            content: payload.content,
            type: payload.messageType,
            senderId: senderId,
            receiverId: payload.receiverId,
            fileName: payload.fileName
        )

        message.save(on: app.db).flatMap {
            message.$sender.load(on: app.db).flatMap {
                message.$receiver.load(on: app.db).map {
                    let response = WsResponse(success: true, data: message, message: "chat_message")
                    if let responseData = try? JSONEncoder().encode(response),
                       let responseString = String(data: responseData, encoding: .utf8) {
                        
                        // Send to receiver
                        connections[payload.receiverId]?.send(responseString)
                        
                        // Acknowledge sender
                        connections[senderId]?.send(responseString)
                    }
                }
            }
        }.whenComplete { _ in }
    }

    private static func broadcastEvent<T: Content>(type: String, data: T, to recipientId: UUID) {
        let response = WsResponse(success: true, data: data, message: type)
        if let responseData = try? JSONEncoder().encode(response),
           let responseString = String(data: responseData, encoding: .utf8) {
            connections[recipientId]?.send(responseString)
        }
    }

    private static func broadcastStatus(userId: UUID, online: Bool, on app: Application) {
        let event = UserStatusEvent(userId: userId, online: online, lastActive: Date())
        if let data = try? JSONEncoder().encode(WsResponse(success: true, data: event, message: "user_status")),
           let text = String(data: data, encoding: .utf8) {
            connections.values.forEach { $0.send(text) }
        }
    }
}

struct WsEvent: Content {
    let type: String
}

struct UserStatusEvent: Content {
    let userId: UUID
    let online: Bool
    let lastActive: Date
}

struct TypingPayload: Content {
    let userId: UUID
    let receiverId: UUID
    let isTyping: Bool
}

struct ReadPayload: Content {
    let messageId: UUID
    let senderId: UUID // The person who sent the message that is now read
    let readerId: UUID // The person who read it
}

struct ReactionWsPayload: Content {
    let emoji: String
    let messageId: UUID
}
