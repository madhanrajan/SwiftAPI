//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation
import SwiftAPICore

/**
 * This is the main entry point for the SwiftAPI application.
 * It creates a web server with several example routes and demonstrates
 * how to use middleware, routing, and request/response handling.
 */

/**
 * Parses command line arguments and environment variables to determine the host and port.
 * Command line arguments take the form of --host [hostname] and --port [port].
 * Environment variables HOST and PORT can override command line arguments.
 * 
 * - Returns: A tuple containing the host and port to use for the server
 */
func parseArgs() -> (host: String, port: Int) {
    let args = CommandLine.arguments
    var host = "localhost"
    var port = 8000
    
    // Parse command line arguments
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

/**
 * Create a new instance of the App class.
 * The App class is the main entry point for creating a web application with SwiftAPI.
 */
var app = App()

/**
 * Add middleware to the application.
 * Middleware is executed in the order it is added, for each request.
 */
// Add logging middleware to log requests and responses
app.use(LoggingMiddleware())

// Add CORS middleware to handle Cross-Origin Resource Sharing
app.use(CORSMiddleware())

// Add error handling middleware to catch and handle errors
app.use(ErrorHandlingMiddleware())

/**
 * Define routes for the application.
 * Each route specifies an HTTP method, a path, and a handler function.
 */
/**
 * Root endpoint that returns a welcome message and version information.
 * Example: GET / -> {"message": "Welcome to SwiftAPI!", "version": "1.0.0"}
 */
app.get("/") { _ in
    Response(body: ["message": "Welcome to SwiftAPI!", "version": "1.0.0"])
}

/**
 * Hello endpoint that returns a greeting message with the name provided in the query parameters.
 * Example: GET /hello?name=John -> {"message": "Hello, John!"}
 * Example: GET /hello -> {"message": "Hello, World!"}
 */
app.get("/hello") { request in
    let name = request.query["name"] ?? "World"
    return Response(body: ["message": "Hello, \(name)!"])
}

/**
 * Echo endpoint that returns the request body as the response.
 * This is useful for testing and debugging.
 * Example: POST /echo {"foo": "bar"} -> {"received": {"foo": "bar"}}
 */
app.post("/echo") { request in
    return Response(body: ["received": request.body])
}

/**
 * Time endpoint that returns the current date and time.
 * Example: GET /time -> {"time": "2025-02-26 12:34:56 +0000"}
 */
app.get("/time") { _ in
    return Response(body: ["time": Date().description])
}

/**
 * Health check endpoint that returns the status of the server.
 * This is useful for monitoring and load balancing.
 * Example: GET /health -> {"status": "UP"}
 */
app.get("/health") { _ in
    return Response(body: ["status": "UP"])
}

/**
 * Users endpoint that returns a list of example users.
 * In a real application, this would typically fetch data from a database.
 * Example: GET /users -> {"users": [{"id": 1, "name": "John Doe", "email": "john@example.com"}, ...]}
 */
app.get("/users") { _ in
    let users: [[String: Any]] = [
        ["id": 1, "name": "John Doe", "email": "john@example.com"],
        ["id": 2, "name": "Jane Smith", "email": "jane@example.com"],
        ["id": 3, "name": "Bob Johnson", "email": "bob@example.com"]
    ]
    return Response(body: ["users": users])
}

/**
 * Parse command line arguments and environment variables to determine the host and port.
 */
let config = parseArgs()

/**
 * Start the server and begin listening for incoming requests.
 * This method will block the current thread and enter the main run loop.
 */
print("Starting SwiftAPI on http://\(config.host):\(config.port)")
app.run(host: config.host, port: config.port)
