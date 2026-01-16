//
//  MainSocket.swift
//  App
//

import Vapor
import Fluent
import JWT

actor ConnectionManager {
    private var connections: [UUID: WebSocket] = [:]

    func addConnection(_ ws: WebSocket, for userId: UUID) {
        connections[userId] = ws
        print("User \(userId) connected. Online users: \(connections.keys)")
        broadcastOnlineUsers()
    }

    func removeConnection(for userId: UUID) {
        connections.removeValue(forKey: userId)
        print("User \(userId) disconnected. Online users: \(connections.keys)")
        broadcastOnlineUsers()
    }

    func send<T: Content>(_ message: T, to userId: UUID, type: String) {
        let response = WsResponse(success: true, data: message, message: type)
        guard let connection = connections[userId] else { return }
        
        if let data = try? JSONEncoder().encode(response),
           let text = String(data: data, encoding: .utf8) {
            connection.send(text)
        }
    }

    private func broadcastOnlineUsers() {
        let onlineUserIds = Array(connections.keys)
        let response = WsResponse(success: true, data: OnlineUsersResponse(userIds: onlineUserIds), message: "online_users")
        
        if let data = try? JSONEncoder().encode(response),
           let text = String(data: data, encoding: .utf8) {
            for connection in connections.values {
                connection.send(text)
            }
        }
    }

    func broadcastStatus(userId: UUID, online: Bool, lastActive: Date) {
        let event = UserStatusEvent(userId: userId, online: online, lastActive: lastActive)
        let response = WsResponse(success: true, data: event, message: "user_status")
        
        if let data = try? JSONEncoder().encode(response),
           let text = String(data: data, encoding: .utf8) {
            for connection in connections.values {
                connection.send(text)
            }
        }
    }

    func broadcastToAll<T: Content>(_ message: T, type: String) {
        let response = WsResponse(success: true, data: message, message: type)
        if let data = try? JSONEncoder().encode(response),
           let text = String(data: data, encoding: .utf8) {
            for connection in connections.values {
                connection.send(text)
            }
        }
    }
}

actor AdminConnectionManager {
    private var adminConnections: [UUID: WebSocket] = [:]

    func addConnection(_ ws: WebSocket, for adminId: UUID) {
        adminConnections[adminId] = ws
        print("Admin \(adminId) connected.")
    }

    func removeConnection(for adminId: UUID) {
        adminConnections.removeValue(forKey: adminId)
        print("Admin \(adminId) disconnected.")
    }

    func broadcastToAdmins<T: Content>(_ event: T, type: String) {
        let response = WsResponse(success: true, data: event, message: type)
        guard let data = try? JSONEncoder().encode(response),
              let text = String(data: data, encoding: .utf8) else { return }
        
        for ws in adminConnections.values {
            ws.send(text)
        }
    }
}

enum MainSocket {
    static let manager = ConnectionManager()
    static let adminManager = AdminConnectionManager()

    static func register(on app: Application) {
        app.webSocket("ws") { req, ws in
            guard let token = req.query[String.self, at: "token"],
                  let payload = try? req.jwt.verify(token, as: SessionPayload.self) else {
                ws.close(promise: nil)
                return
            }

            let userId = payload.userId
            
            Task {
                await manager.addConnection(ws, for: userId)
                
                // Update database: user is online
                if let user = try? await User.find(userId, on: app.db).get() {
                    user.online = true
                    user.lastActive = Date()
                    _ = try? await user.save(on: app.db).get()
                    
                    // Broadcast the status update
                    await manager.broadcastStatus(userId: userId, online: true, lastActive: user.lastActive ?? Date())
                    
                    // Broadcast to admins
                    await adminManager.broadcastToAdmins(UserStatusEvent(
                        userId: userId,
                        online: true,
                        lastActive: user.lastActive ?? Date()
                    ), type: "admin_user_status")
                }
            }

            ws.onText { ws, text in
                handleIncomingMessage(text, from: userId, on: app)
            }

            ws.onClose.whenComplete { _ in
                Task {
                    await manager.removeConnection(for: userId)
                    
                    // Update database: user is offline
                    if let user = try? await User.find(userId, on: app.db).get() {
                        user.online = false
                        user.lastActive = Date()
                        _ = try? await user.save(on: app.db).get()
                        
                        // Broadcast the status update (lastActive is now set)
                        await manager.broadcastStatus(userId: userId, online: false, lastActive: user.lastActive ?? Date())
                        
                        // Broadcast to admins
                        await adminManager.broadcastToAdmins(UserStatusEvent(
                            userId: userId,
                            online: false,
                            lastActive: user.lastActive ?? Date()
                        ), type: "admin_user_status")
                    }
                }
            }
        }

        app.webSocket("ws", "admin") { req, ws in
            guard let token = req.query[String.self, at: "token"],
                  let payload = try? req.jwt.verify(token, as: SessionPayload.self),
                  payload.role == .admin else {
                ws.close(promise: nil)
                return
            }

            let adminId = payload.userId
            
            Task {
                await adminManager.addConnection(ws, for: adminId)
            }

            ws.onClose.whenComplete { _ in
                Task {
                    await adminManager.removeConnection(for: adminId)
                }
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
                Task {
                    await manager.send(payload, to: payload.receiverId, type: "typing")
                }
            }
        case "message_read":
            if let payload = try? JSONDecoder().decode(ReadPayload.self, from: data) {
                Task {
                    await manager.send(payload, to: payload.senderId, type: "message_read")
                }
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
            reaction.$user.load(on: app.db).flatMap {
                Message.find(payload.messageId, on: app.db).map { message in
                    guard let message = message else { return }
        
                    Task {
                        await manager.send(reaction, to: message.$sender.id, type: "reaction")
                        await manager.send(reaction, to: message.$receiver.id, type: "reaction")
                    }
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
            fileName: payload.fileName,
            duration: payload.duration,
            replyToId: payload.replyToId
        )

        message.save(on: app.db).flatMap {
            User.find(senderId, on: app.db).flatMap { sender in
                if let sender = sender {
                    sender.messageCount += 1
                    return sender.save(on: app.db)
                }
                return app.db.eventLoop.makeSucceededVoidFuture()
            }
        }.flatMap {
            message.$sender.load(on: app.db)
        }.flatMap {
            message.$receiver.load(on: app.db)
        }.flatMap {
            message.$replyTo.load(on: app.db)
        }.flatMap {
            if let reply = message.replyTo {
                return reply.$sender.load(on: app.db)
            }
            return app.db.eventLoop.makeSucceededVoidFuture()
        }.map {
            Task {
                await manager.send(message, to: payload.receiverId, type: "chat_message")
                await manager.send(message, to: senderId, type: "chat_message")
                
                // Broadcast to admins
                await adminManager.broadcastToAdmins(AdminMessageSentEvent(
                    userId: senderId,
                    messageCount: 1
                ), type: "admin_message_sent")
            }
        }.whenComplete { _ in }
    }
}

struct OnlineUsersResponse: Content {
    let userIds: [UUID]
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
    let senderId: UUID 
    let readerId: UUID 
}

struct ReactionWsPayload: Content {
    let emoji: String
    let messageId: UUID
}

struct AdminMessageSentEvent: Content {
    let userId: UUID
    let messageCount: Int
}

struct AdminNewUserEvent: Content {
    let userId: UUID
    let name: String
    let email: String
    let createdAt: Date
}

struct AdminUserSuspendedEvent: Content {
    let userId: UUID
    let suspended: Bool
    let suspendedBy: UUID
}
