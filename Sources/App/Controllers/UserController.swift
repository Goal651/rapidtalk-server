import Vapor
import Fluent

enum UserController {

    static func create(req: Request) throws -> EventLoopFuture<APIResponse<User>> {
        let user = try req.content.decode(User.self)
        return user.save(on: req.db).map { 
            APIResponse(success: true, data: user, message: "User created successfully")
        }
    }

    static func all(req: Request) -> EventLoopFuture<APIResponse<[User]>> {
        User.query(on: req.db).all().map { users in
            APIResponse(success: true, data: users, message: "Users retrieved successfully")
        }
    }

    static func getById(req: Request) -> EventLoopFuture<APIResponse<User>> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { user in
                APIResponse(success: true, data: user, message: "User found")
            }
    }

    static func updateStatus(req: Request) throws -> EventLoopFuture<APIResponse<User>> {
        let statusUpdate = try req.content.decode(UserStatusUpdate.self)
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.status = statusUpdate.status
                user.online = statusUpdate.online
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
}

struct UserStatusUpdate: Content {
    let status: String?
    let online: Bool?
}
