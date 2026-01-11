import Vapor

let app = try Application(.detect())
defer { app.shutdown() }

// Make app accessible externally
app.http.server.configuration.hostname = "0.0.0.0"
app.http.server.configuration.port = 8080

app.get { _ in
    "Hello from Vapor 🚀"
}

app.get("wigo"){ req in
    "Hello from Wigo 🚀"
}

app.webSocket("ws") { _, ws in
    ws.onText { ws, text in
        ws.send("Echo: \(text)")
    }
}

try app.run()
