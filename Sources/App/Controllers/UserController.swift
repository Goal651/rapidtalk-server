import Vapor
import Fluent

enum UserController {

    static func all(req: Request) -> EventLoopFuture<APIResponse<[User]>> {
        let payload = try? req.auth.require(SessionPayload.self)
        return User.query(on: req.db)
            .filter(\.$id != payload?.userId ?? UUID())
            .all()
            .map { users in
                APIResponse(success: true, data: users, message: "Users retrieved successfully")
            }
    }

    static func getById(req: Request) throws -> EventLoopFuture<APIResponse<User>> {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { user in
                APIResponse(success: true, data: user, message: "User found")
            }
    }

    static func updateStatus(req: Request) throws -> EventLoopFuture<APIResponse<User>> {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let statusUpdate = try req.content.decode(UserStatusUpdate.self)
        return User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.status = statusUpdate.status
                user.online = statusUpdate.online ?? user.online
                user.lastActive = Date()
                return user.save(on: req.db).map {
                    APIResponse(success: true, data: user, message: "Status updated")
                }
            }
    }

    static func search(req: Request) throws -> EventLoopFuture<APIResponse<[User]>> {
        let searchTerm = req.query[String.self, at: "query"] ?? ""
        return User.query(on: req.db)
            .filter(\.$name ~~ searchTerm)
            .all()
            .map { users in
                APIResponse(success: true, data: users, message: "Search completed")
            }
    }

    static func seed(req: Request) throws -> EventLoopFuture<APIResponse<[User]>> {
        let users = [
            User(name: "Alice", email: "alice@example.com", password: try req.password.hash("password123"), bio: "Testing Alice", online: false),
            User(name: "Bob", email: "bob@example.com", password: try req.password.hash("password123"), bio: "Testing Bob", online: false),
            User(name: "Charlie", email: "charlie@example.com", password: try req.password.hash("password123"), bio: "Testing Charlie", online: false)
        ]
        
        return users.create(on: req.db).flatMap {
            User.query(on: req.db).all().map { allUsers in
                APIResponse(success: true, data: allUsers, message: "Seeded 3 test users")
            }
        }
    }
}

struct UserStatusUpdate: Content {
    let status: String?
    let online: Bool?
}
