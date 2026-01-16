import Vapor
import JWT

struct SessionPayload: JWTPayload, Authenticatable {
    // Standard JWT claims
    var expiration: ExpirationClaim
    
    // Custom data
    var userId: UUID
    var email: String
    var role: UserRole
    
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }

    struct UserSuspensionMiddleware: AsyncMiddleware {
        func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
            let payload = try request.auth.require(SessionPayload.self)
            
            // Check suspension status in database
            guard let user = try await User.query(on: request.db)
                .filter(\.$id == payload.userId)
                .first() else {
                throw Abort(.unauthorized)
            }
            
            if user.suspendedAt != nil {
                throw Abort(.forbidden, reason: "Your account is suspended.")
            }
            
            return try await next.respond(to: request)
        }
    }

    struct AdminGuardMiddleware: Middleware {
        func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
            do {
                let payload = try request.auth.require(SessionPayload.self)
                guard payload.role == .admin else {
                    return request.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "Admin role required"))
                }
                return next.respond(to: request)
            } catch {
                return request.eventLoop.makeFailedFuture(error)
            }
        }
    }
}
