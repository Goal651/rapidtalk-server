//
//  Health.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

enum HealthController {
    static func wigo(req: Request) -> APIResponse<String> {
        APIResponse(success: true, data: "wigo", message: "test succeeded")
    }
}
