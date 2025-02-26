//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation
import SwiftAPICore

// Parse command line arguments
func parseArgs() -> (host: String, port: Int) {
    let args = CommandLine.arguments
    var host = "localhost"
    var port = 8000
    
    for i in 0..<args.count {
        if args[i] == "--host" && i+1 < args.count {
            host = args[i+1]
        }
        if args[i] == "--port" && i+1 < args.count {
            if let parsedPort = Int(args[i+1]) {
                port = parsedPort
            }
        }
    }
    
    // Environment variables can override command line args
    if let envPort = ProcessInfo.processInfo.environment["PORT"],
       let parsedPort = Int(envPort) {
        port = parsedPort
    }
    
    if let envHost = ProcessInfo.processInfo.environment["HOST"] {
        host = envHost
    }
    
    return (host, port)
}

// Create and configure the API
var app = App()

// Add middleware
app.use(LoggingMiddleware())
app.use(CORSMiddleware())
app.use(ErrorHandlingMiddleware())

// Define routes
app.get("/") { _ in
    Response(body: ["message": "Welcome to SwiftAPI!", "version": "1.0.0"])
}

app.get("/hello") { request in
    let name = request.query["name"] ?? "World"
    return Response(body: ["message": "Hello, \(name)!"])
}

app.post("/echo") { request in
    return Response(body: ["received": request.body])
}

app.get("/time") { _ in
    return Response(body: ["time": Date().description])
}

app.get("/health") { _ in
    return Response(body: ["status": "UP"])
}

// Example JSON data route
app.get("/users") { _ in
    let users: [[String: Any]] = [
        ["id": 1, "name": "John Doe", "email": "john@example.com"],
        ["id": 2, "name": "Jane Smith", "email": "jane@example.com"],
        ["id": 3, "name": "Bob Johnson", "email": "bob@example.com"]
    ]
    return Response(body: ["users": users])
}

// Start the server
let config = parseArgs()
print("Starting SwiftAPI on http://\(config.host):\(config.port)")
app.run(host: config.host, port: config.port)
