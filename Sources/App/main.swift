import Vapor

let app = Application()
defer { app.shutdown() }

app.get { req in
    "Hello from Vapor 🚀"
}

app.webSocket("ws") { req, ws in
    ws.onText { ws, text in
        ws.send("Echo: \(text)")
    }
    
}

try app.run()
