//
//  MainSocket.swift
//  App
//
//  Created by wigothehacker on 1/11/26.
//

import Vapor

enum MainSocket {
    static func register(on app: Application) {
        app.webSocket("ws") { _, ws in
            ws.onText { ws, text in
                ws.send("Echo: \(text)")
            }
        }
    }
}
