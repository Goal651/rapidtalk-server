import Vapor
import Fluent

enum AdminController {

    @Sendable
    static func getDashboardStats(req: Request) async throws -> APIResponse<AdminDashboardStats> {
        let _ = try req.auth.require(SessionPayload.self)
        // Note: Guard for admin role should be in routes/middleware

        let totalUsers = try await User.query(on: req.db).count()
        let activeUsers = try await User.query(on: req.db).filter(\.$online == true).count()
        let totalMessages = try await Message.query(on: req.db).count()
        
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let newUsersToday = try await User.query(on: req.db)
            .filter(\.$createdAt >= startOfToday)
            .count()
            
        let last24h = Date().addingTimeInterval(-24 * 60 * 60)
        let messagesLast24h = try await Message.query(on: req.db)
            .filter(\.$timestamp >= last24h)
            .count()

        let stats = AdminDashboardStats(
            totalUsers: totalUsers,
            activeUsers: activeUsers,
            totalMessages: totalMessages,
            newUsersToday: newUsersToday,
            messagesLast24h: messagesLast24h
        )
        
        return APIResponse(success: true, data: stats, message: "Dashboard stats retrieved")
    }

    @Sendable
    static func getUsers(req: Request) async throws -> APIResponse<AdminUserListResponse> {
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 50
        let filter = req.query[String.self, at: "filter"] ?? "all"
        let sort = req.query[String.self, at: "sort"] ?? "lastActive"

        var query = User.query(on: req.db)

        switch filter {
        case "online": query = query.filter(\.$online == true)
        case "offline": query = query.filter(\.$online == false)
        case "suspended": query = query.filter(\.$suspendedAt != nil)
        default: break
        }

        switch sort {
        case "messageCount": query = query.sort(\.$messageCount, .descending)
        case "createdAt": query = query.sort(\.$createdAt, .descending)
        default: query = query.sort(\.$lastActive, .descending)
        }

        let totalUsers = try await query.count()
        let totalPages = Int(ceil(Double(totalUsers) / Double(limit)))
        
        let users = try await query
            .range((page - 1) * limit..<(page * limit))
            .all()
            .map { user in
                AdminUserDTO(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    avatar: user.avatar,
                    userRole: user.userRole,
                    status: user.suspendedAt != nil ? "suspended" : "active",
                    online: user.online,
                    lastActive: user.lastActive,
                    createdAt: user.createdAt,
                    messageCount: user.messageCount,
                    bio: user.bio,
                    suspendedAt: user.suspendedAt
                )
            }

        let response = AdminUserListResponse(
            users: users,
            pagination: AdminPaginationDTO(
                currentPage: page,
                totalPages: totalPages,
                totalUsers: totalUsers
            )
        )

        return APIResponse(success: true, data: response, message: "User list retrieved")
    }

    @Sendable
    static func getUserDetails(req: Request) async throws -> APIResponse<AdminUserDTO> {
        guard let userId = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        let dto = AdminUserDTO(
            id: user.id,
            name: user.name,
            email: user.email,
            avatar: user.avatar,
            userRole: user.userRole,
            status: user.suspendedAt != nil ? "suspended" : "active",
            online: user.online,
            lastActive: user.lastActive,
            createdAt: user.createdAt,
            messageCount: user.messageCount,
            bio: user.bio,
            suspendedAt: user.suspendedAt
        )

        return APIResponse(success: true, data: dto, message: "User details retrieved")
    }

    @Sendable
    static func suspendUser(req: Request) async throws -> APIResponse<AdminUserDTO> {
        guard let userId = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let suspendReq = try req.content.decode(SuspendRequest.self)
        
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        if suspendReq.suspended {
            user.suspendedAt = Date()
            user.status = "suspended" // Sync with status field if used
        } else {
            user.suspendedAt = nil
            user.status = "active"
        }

        try await user.save(on: req.db)
        
        // Broadcast to admins
        let adminPayload = try req.auth.require(SessionPayload.self)
        Task {
            await MainSocket.adminManager.broadcastToAdmins(AdminUserSuspendedEvent(
                userId: userId,
                suspended: suspendReq.suspended,
                suspendedBy: adminPayload.userId
            ), type: "admin_user_suspended")
            
            // Notify the user directly if they are online
            await MainSocket.manager.send(UserSuspendedEvent(
                userId: userId, 
                suspended: suspendReq.suspended
            ), to: userId, type: "user_suspended")
        }
        
        let dto = AdminUserDTO(
            id: user.id,
            name: user.name,
            email: user.email,
            avatar: user.avatar,
            userRole: user.userRole,
            status: user.suspendedAt != nil ? "suspended" : "active",
            online: user.online,
            lastActive: user.lastActive,
            createdAt: user.createdAt,
            messageCount: user.messageCount,
            bio: user.bio,
            suspendedAt: user.suspendedAt
        )

        return APIResponse(success: true, data: dto, message: "User status updated")
    }

    @Sendable
    static func getAnalytics(req: Request) async throws -> APIResponse<AdminAnalytics> {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        // 1. User Growth (Daily registrations)
        let users = try await User.query(on: req.db)
            .filter(\.$createdAt >= thirtyDaysAgo)
            .all()
        
        var userStats: [String: Int] = [:]
        for user in users {
            if let date = user.createdAt {
                let dateString = dateFormatter.string(from: date)
                userStats[dateString, default: 0] += 1
            }
        }
        
        let userGrowth = userStats.map { TimeSeriesPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }

        // 2. Message Activity (Daily counts)
        let messages = try await Message.query(on: req.db)
            .filter(\.$timestamp >= thirtyDaysAgo)
            .all()
            
        var msgStats: [String: Int] = [:]
        var typeStats: [MessageType: Int] = [:]
        
        for msg in messages {
            if let date = msg.timestamp {
                let dateString = dateFormatter.string(from: date)
                msgStats[dateString, default: 0] += 1
            }
            typeStats[msg.type, default: 0] += 1
        }
        
        let messageActivity = msgStats.map { TimeSeriesPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
            
        // 3. Message Type Distribution
        let distribution = MessageType.allCases.map { type in
            TypeDistributionPoint(type: type.rawValue, count: typeStats[type] ?? 0)
        }

        let analytics = AdminAnalytics(
            userGrowth: userGrowth,
            messageActivity: messageActivity,
            messageTypeDistribution: distribution
        )

        return APIResponse(success: true, data: analytics, message: "Analytics retrieved successfully")
    }
}
