//
//  configure.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor
import Fluent
import FluentPostgresDriver
import JWT

public func configure(_ app: Application) throws {

    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

    // Configure JWT
    app.jwt.signers.use(.hs256(key: Environment.get("JWT_SECRET") ?? "your-secret-key"))

    app.databases.use(
        .postgres(
            hostname: Environment.get("DB_HOST") ?? "localhost",
            port: Environment.get("DB_PORT").flatMap(Int.init) ?? 5432,
            username: Environment.get("DB_USER") ?? "postgres",
            password: Environment.get("DB_PASS") ?? "password",
            database: Environment.get("DB_NAME") ?? "rapidtalk"
        ),
        as: .psql
    )

    app.migrations.add(CreateUser())
    app.migrations.add(CreateMessage())
    app.migrations.add(CreateReaction())

    try app.autoMigrate()
    try routes(app)
}
