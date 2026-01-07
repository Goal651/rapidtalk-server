import Vapor

let app = Application()

// Configure server to listen on 0.0.0.0
app.http.server.configuration.hostname = "0.0.0.0"
defer { app.shutdown() }

app.get { req in
    "Hello from Vapor"
}

app.webSocket("ws") { req, ws in
    ws.onText { ws, text in
        ws.send("Echo: \(text)")
    }
    
}

try app.run()
