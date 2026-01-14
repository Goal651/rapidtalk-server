import Vapor

enum MessageType: String, Codable, CaseIterable {
    case text = "TEXT"
    case image = "IMAGE"
    case audio = "AUDIO"
    case video = "VIDEO"
    case file = "FILE"
}

enum UserRole: String, Codable, CaseIterable {
    case user = "USER"
    case admin = "ADMIN"
}
