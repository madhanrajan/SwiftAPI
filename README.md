# SwiftAPI

A lightweight, protocol-oriented web server framework written in Swift.

## Features

- 🏗️ **Protocol-Oriented Design**: Built with Swift's protocol-oriented programming paradigm
- 🔄 **Middleware Support**: Easy to create and compose middleware for request/response processing
- 🧩 **Composable Components**: All components are designed to be modular and composable
- 🔍 **Type Safety**: Leverages Swift's strong type system for safer code
- 📦 **Value Semantics**: Uses structs and value types wherever possible
- 🧪 **Testability**: Designed with testing in mind
- 🔌 **Extensibility**: Easy to extend and customize

## Installation

### Swift Package Manager

```bash
git clone https://github.com/yourusername/swiftapi.git
cd swiftapi
swift build
```

## Quick Start

```swift
import SwiftAPICore

var app = App()

// Add middleware
app.use(LoggingMiddleware())
app.use(CORSMiddleware())

// Define routes
app.get("/") { _ in
    Response(body: ["message": "Welcome to SwiftAPI!"])
}

app.get("/hello") { request in
    let name = request.query["name"] ?? "World"
    return Response(body: ["message": "Hello, \(name)!"])
}

app.post("/echo") { request in
    return Response(body: ["received": request.body])
}

// Start the server
app.run(host: "localhost", port: 8000)
```

## Core Components

### Request & Response

The framework uses a simple request/response model with JSON support:

```swift
// Request contains HTTP method, path, headers, query parameters, and body
let request = Request(method: .get, path: "/users")

// Response includes status code, headers, and body
let response = Response(statusCode: 200, body: ["message": "Success"])
```

### Middleware

Middleware processes requests before they reach the route handler:

```swift
struct TimingMiddleware: Middleware {
    func process(request: Request, next: @escaping (Request) -> Response) -> Response {
        let start = Date()
        let response = next(request)
        let elapsed = Date().timeIntervalSince(start)
        print("Request to \(request.path) took \(elapsed) seconds")
        return response
    }
}

app.use(TimingMiddleware())
```

### Routing

Define routes with HTTP method functions:

```swift
app.get("/users") { _ in Response(body: ["users": []]) }
app.post("/users") { req in Response(statusCode: 201) }
app.put("/users/:id") { req in Response(body: ["updated": true]) }
app.delete("/users/:id") { _ in Response(statusCode: 204) }
```

## Advanced Usage

### Custom Middleware

```swift
struct AuthMiddleware: Middleware {
    func process(request: Request, next: @escaping (Request) -> Response) -> Response {
        guard let token = request.headers["Authorization"] else {
            return Response(statusCode: 401, body: ["error": "Unauthorized"])
        }
        
        // Validate token logic here
        if !isValidToken(token) {
            return Response(statusCode: 403, body: ["error": "Forbidden"])
        }
        
        return next(request)
    }
    
    private func isValidToken(_ token: String) -> Bool {
        // Token validation logic
        return true
    }
}
```

### Environment Configuration

```swift
// Parse environment variables or command line arguments
let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8000") ?? 8000
let host = ProcessInfo.processInfo.environment["HOST"] ?? "localhost"

app.run(host: host, port: port)
```

### Testing Routes

The framework is designed to be easily testable:

```swift
func testUserRoute() {
    let router = Router()
    router.register(Route(method: .get, path: "/test", handler: { _ in 
        Response(body: ["success": true])
    }))
    
    let request = Request(method: .get, path: "/test")
    let response = router.route(request)
    
    XCTAssertEqual(response.statusCode, 200)
    XCTAssertEqual(response.body["success"] as? Bool, true)
}
```

## Command Line Arguments

Run SwiftAPI with custom host and port:

```bash
.build/debug/SwiftAPI --host 0.0.0.0 --port 3000
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
