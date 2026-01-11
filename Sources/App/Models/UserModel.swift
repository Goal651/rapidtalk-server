//
//  UserModel.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Fluent
import Vapor

final class User: Model,@unchecked Sendable, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
