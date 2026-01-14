import Vapor
import Fluent

enum MessageController {

    @Sendable
    static func create(req: Request) async throws -> APIResponse<Message> {
        let payload = try req.auth.require(SessionPayload.self)
        let messagePayload = try req.content.decode(ChatMessagePayload.self)
        
        let message = Message(
            content: messagePayload.content,
            type: messagePayload.messageType,
            senderId: payload.userId,
            receiverId: messagePayload.receiverId,
            fileName: messagePayload.fileName
        )
        
        try await message.save(on: req.db)
        try await message.$sender.load(on: req.db)
        try await message.$receiver.load(on: req.db)
        
        return APIResponse(success: true, data: message, message: "Message sent successfully")
    }

    @Sendable
    static func getConversation(req: Request) async throws -> APIResponse<[Message]> {
        guard let user1 = req.parameters.get("user1ID", as: UUID.self),
              let user2 = req.parameters.get("user2ID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let messages = try await Message.query(on: req.db)
            .group(.or) { group in
                group.group(.and) { and in
                    and.filter(\.$sender.$id == user1)
                    and.filter(\.$receiver.$id == user2)
                }
                group.group(.and) { and in
                    and.filter(\.$sender.$id == user2)
                    and.filter(\.$receiver.$id == user1)
                }
            }
            .sort(\.$timestamp, .ascending)
            .with(\.$sender)
            .with(\.$receiver)
            .with(\.$reactions)
            .all()
            
        return APIResponse(success: true, data: messages, message: "Messages retrieved successfully")
    }

    @Sendable
    static func all(req: Request) async throws -> APIResponse<[Message]> {
        let messages = try await Message.query(on: req.db)
            .with(\.$sender)
            .with(\.$receiver)
            .all()
        return APIResponse(success: true, data: messages, message: "All messages retrieved")
    }
}
