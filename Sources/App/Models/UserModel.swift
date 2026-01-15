//
//  UserModel.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Fluent
import Vapor

final class User: Model, @unchecked Sendable, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password")
    var password: String

    @OptionalField(key: "avatar")
    var avatar: String?

    @Enum(key: "user_role")
    var userRole: UserRole

    @OptionalField(key: "status")
    var status: String?

    @OptionalField(key: "bio")
    var bio: String?

    @Timestamp(key: "last_active", on: .none)
    var lastActive: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "online")
    var online: Bool

    @Field(key: "message_count")
    var messageCount: Int

    @OptionalField(key: "suspended_at")
    var suspendedAt: Date?

    init() {}

    init(id: UUID? = nil, 
         name: String, 
         email: String,
         password: String,
         avatar: String? = nil, 
         userRole: UserRole = .user, 
         status: String? = nil, 
         bio: String? = nil, 
         lastActive: Date? = nil, 
         online: Bool = false,
         messageCount: Int = 0,
         suspendedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.avatar = avatar
        self.userRole = userRole
        self.status = status
        self.bio = bio
        self.lastActive = lastActive
        self.online = online
        self.messageCount = messageCount
        self.suspendedAt = suspendedAt
    }
}
