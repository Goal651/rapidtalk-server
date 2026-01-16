//
//  routes.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

func routes(_ app: Application) throws {
    app.get("ping") { _ in "pong" }
    let authController = AuthController()
    
    // Auth Routes
    app.group("auth") { auth in
        auth.post("signup", use: authController.signup)
        auth.post("login", use: authController.login)
    }
    
    app.post("users", "seed", use: UserController.seed)
    
    // Protected Routes
    let protected = app.grouped(
        SessionPayload.authenticator(), 
        SessionPayload.guardMiddleware(),
        SessionPayload.UserSuspensionMiddleware()
    )
    
    // User Routes
    protected.group("users") { users in
        users.get(use: UserController.all)
        users.get("me", use: UserController.me)
        users.get("search", use: UserController.search)
        users.get(":userID", use: UserController.getById)
        users.patch(":userID", "status", use: UserController.updateStatus)
        users.post("avatar", use: UserController.uploadAvatar)
    }
    
    protected.get("user") { req async throws -> APIResponse<User> in
        let payload = try req.auth.require(SessionPayload.self)
        guard let user = try await User.find(payload.userId, on: req.db) else {
            throw Abort(.notFound)
        }
        return APIResponse(success: true, data: user, message: "User found")
    }

    // Message Routes
    protected.group("messages") { messages in
        messages.post(use: MessageController.create)
        messages.post("upload", use: MessageController.uploadAttachment)
        messages.get(use: MessageController.all)
        messages.get("conversation", ":user1ID", ":user2ID", use: MessageController.getConversation)
    }

    // Admin Routes
    protected.grouped(SessionPayload.AdminGuardMiddleware()).group("admin") { admin in
        admin.get("dashboard", use: AdminController.getDashboardStats)
        admin.get("users", use: AdminController.getUsers)
        admin.get("users", ":userID", use: AdminController.getUserDetails)
        admin.put("users", ":userID", "suspend", use: AdminController.suspendUser)
    }

    MainSocket.register(on: app)
}
