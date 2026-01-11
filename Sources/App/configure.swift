//
//  configure.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

public func configure(_ app: Application) throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

    try routes(app)
}
