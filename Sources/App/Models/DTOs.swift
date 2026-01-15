import Vapor

struct APIResponse<T: Content>: Content {
    let success: Bool
    let data: T?
    let message: String
}

struct WsResponse<T: Content>: Content {
    let success: Bool
    let data: T?
    let message: String?
}

struct ChatMessagePayload: Content {
    let receiverId: UUID
    let content: String
    let messageType: MessageType
    let fileName: String?
    let duration: Double?
    let replyToId: UUID?
}

struct ReactionDTO: Content {
    let emoji: String
    let userId: UUID
}

// Admin DTOs
struct AdminDashboardStats: Content {
    let totalUsers: Int
    let activeUsers: Int
    let totalMessages: Int
    let newUsersToday: Int
    let messagesLast24h: Int
}

struct AdminUserDTO: Content {
    let id: UUID?
    let name: String
    let email: String
    let avatar: String?
    let userRole: UserRole
    let status: String?
    let online: Bool
    let lastActive: Date?
    let createdAt: Date?
    let messageCount: Int
    let bio: String?
    let suspendedAt: Date?
}

struct AdminUserListResponse: Content {
    let users: [AdminUserDTO]
    let pagination: AdminPaginationDTO
}

struct AdminPaginationDTO: Content {
    let currentPage: Int
    let totalPages: Int
    let totalUsers: Int
}

struct SuspendRequest: Content {
    let suspended: Bool
    let reason: String?
}
