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
    let senderId: Int
    let receiverId: Int
    let content: String
    let type: MessageType
    let fileName: String?
}

struct Reaction: Content {
    let emoji: String
    let userId: Int
}
