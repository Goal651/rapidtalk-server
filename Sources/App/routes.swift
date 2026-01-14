//
//  routes.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

func routes(_ app: Application) throws {
    // User Routes
    app.post("users", use: UserController.create)
    app.get("users", use: UserController.all)
    app.get("users", "search", use: UserController.search)
    app.get("users", ":userID", use: UserController.getById)
    app.patch("users", ":userID", "status", use: UserController.updateStatus)

    // Message Routes
    app.post("messages", use: MessageController.create)
    app.get("messages", use: MessageController.all)
    app.get("messages", "conversation", ":user1ID", ":user2ID", use: MessageController.getConversation)

    MainSocket.register(on: app)
}
