//
//  Migration.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string)
            .field("avatar", .string)
            .field("password", .string)
            .field("email", .string)
            .field("user_role", .string)
            .field("status", .string)
            .field("bio", .string)
            .field("last_active", .datetime)
            .field("created_at", .datetime)
            .field("online", .bool)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

struct CreateMessage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("messages")
            .field("id", .int, .identifier(auto: true))
            .field("content", .string)
            .field("type", .string)
            .field("sender_id", .int, .required, .references("users", "id"))
            .field("receiver_id", .int, .required, .references("users", "id"))
            .field("timestamp", .datetime)
            .field("file_name", .string)
            .field("edited", .bool)
            .field("reactions", .json)
            .field("reply_to_id", .int, .references("messages", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("messages").delete()
    }
}
