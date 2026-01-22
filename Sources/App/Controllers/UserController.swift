import Vapor
import Fluent

enum UserController {

    @Sendable
    static func all(req: Request) async throws -> APIResponse<[User]> {
        let payload = try? req.auth.require(SessionPayload.self)
        let users = try await User.query(on: req.db)
            .filter(\.$id != payload?.userId ?? UUID())
            .all()
        return APIResponse(success: true, data: users, message: "Users retrieved successfully")
    }

    @Sendable
    static func me(req: Request) async throws -> APIResponse<User> {
        let payload = try req.auth.require(SessionPayload.self)
        guard let user = try await User.find(payload.userId, on: req.db) else {
            throw Abort(.notFound)
        }
        return APIResponse(success: true, data: user, message: "User found")
    }

    @Sendable
    static func getById(req: Request) async throws -> APIResponse<User> {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        return APIResponse(success: true, data: user, message: "User found")
    }

    @Sendable
    static func updateStatus(req: Request) async throws -> APIResponse<User> {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let statusUpdate = try req.content.decode(UserStatusUpdate.self)
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        user.status = statusUpdate.status
        user.online = statusUpdate.online ?? user.online
        user.lastActive = Date()
        try await user.save(on: req.db)
        
        return APIResponse(success: true, data: user, message: "Status updated")
    }

    @Sendable
    static func search(req: Request) async throws -> APIResponse<[User]> {
        let searchTerm = req.query[String.self, at: "query"] ?? ""
        let users = try await User.query(on: req.db)
            .filter(\.$name ~~ searchTerm)
            .all()
        return APIResponse(success: true, data: users, message: "Search completed")
    }

    @Sendable
    static func seed(req: Request) async throws -> APIResponse<[User]> {
        let users = [
            User(name: "Alice", email: "alice@example.com", password: try req.password.hash("password123"), bio: "Testing Alice", online: false),
            User(name: "Bob", email: "bob@example.com", password: try req.password.hash("password123"), bio: "Testing Bob", online: false),
            User(name: "Charlie", email: "charlie@example.com", password: try req.password.hash("password123"), bio: "Testing Charlie", online: false)
        ]
        
        try await users.create(on: req.db)
        let allUsers = try await User.query(on: req.db).all()
        return APIResponse(success: true, data: allUsers, message: "Seeded 3 test users")
    }

    @Sendable
    static func uploadAvatar(req: Request) async throws -> APIResponse<User> {
        let payload = try req.auth.require(SessionPayload.self)
        let upload = try req.content.decode(AvatarUpload.self)
        
        // Create directory if it doesn't exist
        let avatarDir = req.application.directory.publicDirectory + "avatars/"
        if !FileManager.default.fileExists(atPath: avatarDir) {
            try FileManager.default.createDirectory(atPath: avatarDir, withIntermediateDirectories: true)
        }
        
        let filename = "\(payload.userId.uuidString)-\(UUID().uuidString).jpg"
        let path = avatarDir + filename
        
        try await req.fileio.writeFile(upload.avatar.data, at: path)
        
        guard let user = try await User.find(payload.userId, on: req.db) else {
            return APIResponse(success: false, data: nil, message: "Account Doesn't Exist.")
        }
        
        let avatarUrl = "/avatars/\(filename)"
        user.avatar = avatarUrl
        try await user.save(on: req.db)
        
        return APIResponse(success: true, data: user, message: "Avatar uploaded successfully")
    }
}

struct AvatarUpload: Content {
    let avatar: File
}

struct UserStatusUpdate: Content {
    let status: String?
    let online: Bool?
}
