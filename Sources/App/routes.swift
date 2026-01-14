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
    
    // Protected Routes
    let protected = app.group(JWTPayloadMiddleware<SessionPayload>())
    
    // User Routes
    protected.group("users") { users in
        users.post("seed", use: UserController.seed)
        users.get(use: UserController.all)
        users.get("search", use: UserController.search)
        users.get(":userID", use: UserController.getById)
        users.patch(":userID", "status", use: UserController.updateStatus)
    }
    
    protected.get("user") { req -> User in
        try req.auth.require(SessionPayload.self)
        let payload = try req.auth.require(SessionPayload.self)
        return try User.find(payload.userId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .wait() // Note: In a real app, you should use flatMap, but this is a shorthand for now
    }

    // Message Routes
    protected.group("messages") { messages in
        messages.post(use: MessageController.create)
        messages.get(use: MessageController.all)
        messages.get("conversation", ":user1ID", ":user2ID", use: MessageController.getConversation)
    }

    MainSocket.register(on: app)
}
