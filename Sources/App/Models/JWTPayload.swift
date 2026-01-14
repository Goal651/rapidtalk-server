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
}
