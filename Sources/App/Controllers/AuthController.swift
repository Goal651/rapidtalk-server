import Vapor
import Fluent
import JWT

struct AuthController {
    
    func signup(req: Request) throws -> EventLoopFuture<APIResponse<AuthResponse>> {
        let signup = try req.content.decode(SignupRequest.self)
        
        // Hash password
        let hashedPassword = try req.password.hash(signup.password)
        
        let user = User(
            name: signup.name,
            email: signup.email,
            password: hashedPassword,
            online: true
        )
        
        return user.save(on: req.db).flatMap {
            do {
                let token = try generateToken(for: user, req: req)
                let response = AuthResponse(user: user, accessToken: token)
                return req.eventLoop.makeSucceededFuture(
                    APIResponse(success: true, data: response, message: "User registered successfully")
                )
            } catch {
                return req.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    func login(req: Request) throws -> EventLoopFuture<APIResponse<AuthResponse>> {
        let login = try req.content.decode(LoginRequest.self)
        
        return User.query(on: req.db)
            .filter(\.$email == login.email)
            .first()
            .unwrap(or: Abort(.unauthorized, reason: "Invalid email or password"))
            .flatMap { user in
                do {
                    guard try req.password.verify(login.password, created: user.password) else {
                        throw Abort(.unauthorized, reason: "Invalid email or password")
                    }
                    
                    user.online = true
                    user.lastActive = Date()
                    
                    return user.save(on: req.db).flatMap {
                        do {
                            let token = try generateToken(for: user, req: req)
                            let response = AuthResponse(user: user, accessToken: token)
                            return req.eventLoop.makeSucceededFuture(
                                APIResponse(success: true, data: response, message: "Login successful")
                            )
                        } catch {
                            return req.eventLoop.makeFailedFuture(error)
                        }
                    }
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }
    }
    
    private func generateToken(for user: User, req: Request) throws -> String {
        let payload = SessionPayload(
            expiration: .init(value: Date().addingTimeInterval(60 * 60 * 24 * 7)), // 7 days
            userId: try user.requireID(),
            email: user.email,
            role: user.userRole
        )
        return try req.jwt.sign(payload)
    }
}

struct SignupRequest: Content {
    let name: String
    let email: String
    let password: String
}

struct LoginRequest: Content {
    let email: String
    let password: String
}

struct AuthResponse: Content {
    let user: User
    let accessToken: String
}
