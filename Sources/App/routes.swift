//
//  routes.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

func routes(_ app: Application) throws {
    app.get { _ in
        ["message": "Hello from Vapor"]
    }

    app.get("wigo", use: HealthController.wigo)

    MainSocket.register(on: app)
}
