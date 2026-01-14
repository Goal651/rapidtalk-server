import Vapor

struct APIResponse<T: Content>: Content {
    let success: Bool
    let data: T?
    let message: String
}

struct WsResponse<T: Content>: Content {
    let success: Bool
    let data: T?
    let message: String?
}

struct ChatMessagePayload: Content {
    let receiverId: UUID
    let content: String
    let messageType: MessageType
    let fileName: String?
}

struct ReactionDTO: Content {
    let emoji: String
    let userId: UUID
}
