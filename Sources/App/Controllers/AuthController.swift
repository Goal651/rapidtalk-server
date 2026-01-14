import Vapor
import Fluent
import JWT
import PostgresKit

struct AuthController {
    
    @Sendable
    func signup(req: Request) async throws -> APIResponse<AuthResponse> {
        let signup = try req.content.decode(SignupRequest.self)
        
        // Hash password
        let hashedPassword = try req.password.hash(signup.password)
        
        let user = User(
            name: signup.name,
            email: signup.email,
            password: hashedPassword,
            online: true
        )
        
        do {
            try await user.save(on: req.db)
            let token = try generateToken(for: user, req: req)
            let response = AuthResponse(user: user, accessToken: token)
            return APIResponse(success: true, data: response, message: "User registered successfully")
        } catch {
            req.logger.error("Signup failed: \(error)")
            
            // Check for specific Postgres unique constraint violation
            if let psqlError = error as? PSQLError, psqlError.serverInfo?[.sqlState] == "23505" {
                throw Abort(.conflict, reason: "Email already exists")
            }
            
            throw Abort(.internalServerError, reason: "Database error: \(error.localizedDescription)")
        }
    }
    
    @Sendable
    func login(req: Request) async throws -> APIResponse<AuthResponse> {
        let login = try req.content.decode(LoginRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == login.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }
        
        guard try req.password.verify(login.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }
        
        user.online = true
        user.lastActive = Date()
        
        try await user.save(on: req.db)
        
        let token = try generateToken(for: user, req: req)
        let response = AuthResponse(user: user, accessToken: token)
        return APIResponse(success: true, data: response, message: "Login successful")
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
