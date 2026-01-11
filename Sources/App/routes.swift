//
//  routes.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

func routes(_ app: Application) throws {
    app.post("users", use: UserController.create)
    app.get("users", use: UserController.all)
    MainSocket.register(on: app)
}
