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
