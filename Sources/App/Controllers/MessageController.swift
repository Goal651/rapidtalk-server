import Vapor
import Fluent

enum MessageController {

    static func create(req: Request) throws -> EventLoopFuture<APIResponse<Message>> {
        let payload = try req.content.decode(ChatMessagePayload.self)
        let message = Message(
            content: payload.content,
            type: payload.type,
            senderId: payload.senderId,
            receiverId: payload.receiverId,
            fileName: payload.fileName
        )
        return message.save(on: req.db).map {
            APIResponse(success: true, data: message, message: "Message sent")
        }
    }

    static func getConversation(req: Request) throws -> EventLoopFuture<APIResponse<[Message]>> {
        guard let user1 = req.parameters.get("user1ID", as: Int.self),
              let user2 = req.parameters.get("user2ID", as: Int.self) else {
            throw Abort(.badRequest)
        }

        return Message.query(on: req.db)
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
            .all()
            .map { messages in
                APIResponse(success: true, data: messages, message: "Conversation retrieved")
            }
    }

    static func all(req: Request) -> EventLoopFuture<APIResponse<[Message]>> {
        Message.query(on: req.db)
            .with(\.$sender)
            .with(\.$receiver)
            .all()
            .map { messages in
                APIResponse(success: true, data: messages, message: "All messages retrieved")
            }
    }
}
