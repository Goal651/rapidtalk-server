//
//  Migration.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Fluent

struct CreateUserRoleEnum: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("user_role")
            .case("USER")
            .case("ADMIN")
            .create()
            .map { _ in }
            .flatMapError { _ in database.eventLoop.makeSucceededVoidFuture() }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.enum("user_role").delete()
    }
}

struct CreateMessageTypeEnum: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("message_type")
            .case("TEXT")
            .case("IMAGE")
            .case("AUDIO")
            .case("VIDEO")
            .case("FILE")
            .create()
            .map { _ in }
            .flatMapError { _ in database.eventLoop.makeSucceededVoidFuture() }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.enum("message_type").delete()
    }
}

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
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

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

struct CreateMessage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
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

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("messages").delete()
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

struct AddDurationToMessages: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("messages")
            .field("duration", .double)
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("messages")
            .deleteField("duration")
            .update()
    }
}

struct AddAdminFieldsToUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("message_count", .int, .required, .custom("DEFAULT 0"))
            .field("suspended_at", .datetime)
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .deleteField("message_count")
            .deleteField("suspended_at")
            .update()
    }
}
