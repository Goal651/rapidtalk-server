import Fluent
import Vapor
import Foundation

final class Message: Model, @unchecked Sendable, Content {
    static let schema = "messages"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "content")
    var content: String

    @Enum(key: "type")
    var type: MessageType

    @Parent(key: "sender_id")
    var sender: User

    @Parent(key: "receiver_id")
    var receiver: User

    @Timestamp(key: "timestamp", on: .create)
    var timestamp: Date?

    @OptionalField(key: "file_name")
    var fileName: String?

    @Field(key: "edited")
    var edited: Bool

    @Children(for: \.$message)
    var reactions: [Reaction]

    @OptionalParent(key: "reply_to_id")
    var replyTo: Message?

    init() {}

    init(id: UUID? = nil,
         content: String,
         type: MessageType,
         senderId: User.IDValue,
         receiverId: User.IDValue,
         fileName: String? = nil,
         edited: Bool = false,
         replyToId: Message.IDValue? = nil) {
        self.id = id
        self.content = content
        self.type = type
        self.$sender.id = senderId
        self.$receiver.id = receiverId
        self.fileName = fileName
        self.edited = edited
        self.$replyTo.id = replyToId
    }
}
