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
    static var connections: [UUID: WebSocket] = [:]

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
            // Forward typing indicator
            break
        default:
            break
        }
    }

    private static func saveAndBroadcastMessage(_ payload: ChatMessagePayload, from senderId: UUID, on app: Application) {
        let message = Message(
            content: payload.content,
            type: payload.type,
            senderId: senderId,
            receiverId: payload.receiverId,
            fileName: payload.fileName
        )

        message.save(on: app.db).flatMap {
            message.$sender.load(on: app.db).flatMap {
                message.$receiver.load(on: app.db).map {
                    if let receiverWs = connections[payload.receiverId],
                       let responseData = try? JSONEncoder().encode(WsResponse(success: true, data: message, message: "chat_message")),
                       let responseString = String(data: responseData, encoding: .utf8) {
                        receiverWs.send(responseString)
                    }
                }
            }
        }.whenComplete { _ in }
    }

    private static func broadcastStatus(userId: UUID, online: Bool, on app: Application) {
        let event = UserStatusEvent(userId: userId, online: online, lastActive: Date())
        if let data = try? JSONEncoder().encode(WsResponse(success: true, data: event, message: "user_status")),
           let text = String(data: data, encoding: .utf8) {
            connections.values.forEach { $0.send(text) }
        }
    }
}

struct WsEvent: Codable {
    let type: String
}

struct UserStatusEvent: Codable {
    let userId: UUID
    let online: Bool
    let lastActive: Date
}
