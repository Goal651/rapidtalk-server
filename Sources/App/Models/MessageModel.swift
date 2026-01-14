import Fluent
import Vapor
import Foundation

final class Message: Model, @unchecked Sendable, Content {
    static let schema = "messages"

    @ID(custom: .id, generatedBy: .database)
    var id: Int?

    @Field(key: "content")
    var content: String?

    @Field(key: "type")
    var type: MessageType?

    @Parent(key: "sender_id")
    var sender: User

    @Parent(key: "receiver_id")
    var receiver: User

    @Timestamp(key: "timestamp", on: .create)
    var timestamp: Date?

    @Field(key: "file_name")
    var fileName: String?

    @Field(key: "edited")
    var edited: Bool?

    @Field(key: "reactions")
    var reactions: [Reaction]?

    @OptionalParent(key: "reply_to_id")
    var replyTo: Message?

    init() {}

    init(id: Int? = nil,
         content: String?,
         type: MessageType?,
         senderId: Int,
         receiverId: Int,
         timestamp: Date? = nil,
         fileName: String? = nil,
         edited: Bool? = false,
         reactions: [Reaction]? = [],
         replyToId: Int? = nil) {
        self.id = id
        self.content = content
        self.type = type
        self.$sender.id = senderId
        self.$receiver.id = receiverId
        self.timestamp = timestamp
        self.fileName = fileName
        self.edited = edited
        self.reactions = reactions
        self.$replyTo.id = replyToId
    }
}
