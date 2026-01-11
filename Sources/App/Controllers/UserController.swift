//
//  UserController.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

enum UserController {

    static func create(req: Request) throws -> EventLoopFuture<User> {
        let user = try req.content.decode(User.self)
        return user.save(on: req.db).map { user }
    }

    static func all(req: Request) -> EventLoopFuture<[User]> {
        User.query(on: req.db).all()
    }
}
