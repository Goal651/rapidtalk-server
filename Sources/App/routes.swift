//
//  routes.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

func routes(_ app: Application) throws {
    let authController = AuthController()
    
    // Auth Routes
    app.group("auth") { auth in
        auth.post("signup", use: authController.signup)
        auth.post("login", use: authController.login)
    }
    app.post("users","seed", use: UserController.seed)
    // Protected Routes
    let protected = app.grouped(SessionPayload.authenticator(), SessionPayload.guardMiddleware())
    
    // User Routes
    protected.group("users") { users in
      
        users.get(use: UserController.all)
        users.get("search", use: UserController.search)
        users.get(":userID", use: UserController.getById)
        users.patch(":userID", "status", use: UserController.updateStatus)
    }
    
    protected.get("user") { req -> EventLoopFuture<APIResponse<User>> in
        let payload = try req.auth.require(SessionPayload.self)
        return User.find(payload.userId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { user in
                APIResponse(success: true, data: user, message: "User found")
            }
    }

    // Message Routes
    protected.group("messages") { messages in
        messages.post(use: MessageController.create)
        messages.get(use: MessageController.all)
        messages.get("conversation", ":user1ID", ":user2ID", use: MessageController.getConversation)
    }

    MainSocket.register(on: app)
}
