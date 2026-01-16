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

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.routes.defaultMaxBodySize = "10mb"

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)

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

    app.migrations.add(CreateUserRoleEnum())
    app.migrations.add(CreateMessageTypeEnum())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateMessage())
    app.migrations.add(CreateReaction())
    app.migrations.add(AddDurationToMessages())
    app.migrations.add(AddAdminFieldsToUser())

    try app.autoMigrate()
    
    // Seed Admin User if not exists
    Task {
        do {
            let adminEmail = "admin@admin.com"
            if try await User.query(on: app.db).filter(\.$email == adminEmail).first() == nil {
                let hashedPassword = try app.password.hash("admin12")
                let admin = User(
                    name: "Admin",
                    email: adminEmail,
                    password: hashedPassword,
                    userRole: .admin,
                    online: false
                )
                try await admin.save(on: app.db)
                app.logger.info("Default admin user created.")
            }
        } catch {
            app.logger.error("Failed to seed admin user: \(error)")
        }
    }

    try routes(app)
}
