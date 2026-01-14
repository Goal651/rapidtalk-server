import Fluent
import Vapor

final class Reaction: Model, @unchecked Sendable, Content {
    static let schema = "reactions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "emoji")
    var emoji: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "message_id")
    var message: Message
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, emoji: String, userId: User.IDValue, messageId: Message.IDValue) {
        self.id = id
        self.emoji = emoji
        self.$user.id = userId
        self.$message.id = messageId
    }
}
