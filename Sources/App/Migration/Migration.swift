//
//  Migration.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let userRole = database.enum("user_role")
            .read()
            .flatMap { _ in database.eventLoop.makeSucceededVoidFuture() }
            .flatMapError { _ in
                database.enum("user_role")
                    .case("USER")
                    .case("ADMIN")
                    .create()
                    .map { _ in }
            }

        return userRole.flatMap { _ in
            database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password", .string, .required)
                .field("avatar", .string)
                .field("user_role", .custom("user_role"), .required)
                .field("status", .string)
                .field("bio", .string)
                .field("last_active", .datetime)
                .field("created_at", .datetime)
                .field("online", .bool, .required, .custom("DEFAULT false"))
                .unique(on: "email")
                .create()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete().flatMap {
            database.enum("user_role").delete()
        }
    }
}

struct CreateMessage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let messageType = database.enum("message_type")
            .read()
            .flatMap { _ in database.eventLoop.makeSucceededVoidFuture() }
            .flatMapError { _ in
                database.enum("message_type")
                    .case("TEXT")
                    .case("IMAGE")
                    .case("AUDIO")
                    .case("VIDEO")
                    .case("FILE")
                    .create()
                    .map { _ in }
            }

        return messageType.flatMap { _ in
            database.schema("messages")
                .id()
                .field("content", .string, .required)
                .field("type", .custom("message_type"), .required)
                .field("sender_id", .uuid, .required, .references("users", "id"))
                .field("receiver_id", .uuid, .required, .references("users", "id"))
                .field("timestamp", .datetime)
                .field("file_name", .string)
                .field("edited", .bool, .required, .custom("DEFAULT false"))
                .field("reply_to_id", .uuid, .references("messages", "id"))
                .create()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("messages").delete().flatMap {
            database.enum("message_type").delete()
        }
    }
}

struct CreateReaction: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("reactions")
            .id()
            .field("emoji", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("message_id", .uuid, .required, .references("messages", "id"))
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("reactions").delete()
    }
}
