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

    @ID(custom: .id, generatedBy: .database)
    var id: Int?

    @Field(key: "name")
    var name: String?

    @Field(key: "avatar")
    var avatar: String?

    @Field(key: "password")
    var password: String?

    @Field(key: "email")
    var email: String?

    @Field(key: "user_role")
    var userRole: UserRole?

    @Field(key: "status")
    var status: String?

    @Field(key: "bio")
    var bio: String?

    @Timestamp(key: "last_active", on: .none)
    var lastActive: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "online")
    var online: Bool?

    init() {}

    init(id: Int? = nil, 
         name: String? = nil, 
         avatar: String? = nil, 
         password: String? = nil, 
         email: String? = nil, 
         userRole: UserRole? = .user, 
         status: String? = nil, 
         bio: String? = nil, 
         lastActive: Date? = nil, 
         createdAt: Date? = nil, 
         online: Bool? = false) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.password = password
        self.email = email
        self.userRole = userRole
        self.status = status
        self.bio = bio
        self.lastActive = lastActive
        self.createdAt = createdAt
        self.online = online
    }
}
