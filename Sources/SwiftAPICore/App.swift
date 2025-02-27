//App.swift
import Foundation

/**
 * Protocol defining the core functionality of a web application.
 * This protocol establishes the contract for HTTP method handlers, middleware registration,
 * and server execution.
 */
public protocol ApplicationProtocol {
    /**
     * Registers a handler for HTTP GET requests at the specified path.
     * - Parameters:
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    mutating func get(_ path: String, handler: @escaping Handler)
    
    /**
     * Registers a handler for HTTP POST requests at the specified path.
     * - Parameters:
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    mutating func post(_ path: String, handler: @escaping Handler)
    
    /**
     * Registers a handler for HTTP PUT requests at the specified path.
     * - Parameters:
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    mutating func put(_ path: String, handler: @escaping Handler)
    
    /**
     * Registers a handler for HTTP DELETE requests at the specified path.
     * - Parameters:
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    mutating func delete(_ path: String, handler: @escaping Handler)
    
    /**
     * Adds a middleware to the application's middleware stack.
     * Middleware will be executed in the order they are added.
     * - Parameter middleware: The middleware to add to the application
     */
    mutating func use(_ middleware: Middleware)
    
    /**
     * Starts the web server on the specified host and port.
     * - Parameters:
     *   - host: The hostname or IP address to bind to
     *   - port: The port number to listen on
     */
    mutating func run(host: String, port: Int)
}

/**
 * The main application struct that implements the ApplicationProtocol.
 * This is the primary entry point for creating a web application with this framework.
 */
public struct App: ApplicationProtocol {
    /// Collection of all registered routes
    private var routes: [Route] = []
    
    /// The router responsible for matching requests to handlers
    private var router: RouterProtocol
    
    /// Collection of all registered middleware
    private var middlewares: [Middleware] = []
    
    /// Factory function for creating a server instance
    private let serverFactory: (RequestHandlerType) -> ServerType
    
    /**
     * Initializes a new App instance with the specified router and server factory.
     * - Parameters:
     *   - router: The router to use for routing requests (defaults to Router())
     *   - serverFactory: A factory function that creates a server instance (defaults to creating a standard Server)
     */
    public init(
        router: RouterProtocol = Router(),
        serverFactory: @escaping (RequestHandlerType) -> ServerType = { Server(requestHandler: $0) }
    ) {
        self.router = router
        self.serverFactory = serverFactory
    }
    
    /**
     * Registers a handler for HTTP GET requests at the specified path.
     * - Parameters:
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    public mutating func get(_ path: String, handler: @escaping Handler) {
        registerRoute(method: .get, path: path, handler: handler)
    }
    
    /**
     * Registers a handler for HTTP POST requests at the specified path.
     * - Parameters:
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    public mutating func post(_ path: String, handler: @escaping Handler) {
        registerRoute(method: .post, path: path, handler: handler)
    }
    
    /**
     * Registers a handler for HTTP PUT requests at the specified path.
     * - Parameters:
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    public mutating func put(_ path: String, handler: @escaping Handler) {
        registerRoute(method: .put, path: path, handler: handler)
    }
    
    /**
     * Registers a handler for HTTP DELETE requests at the specified path.
     * - Parameters:
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    public mutating func delete(_ path: String, handler: @escaping Handler) {
        registerRoute(method: .delete, path: path, handler: handler)
    }
    
    /**
     * Adds a middleware to the application's middleware stack.
     * Middleware will be executed in the order they are added.
     * - Parameter middleware: The middleware to add to the application
     */
    public mutating func use(_ middleware: Middleware) {
        middlewares.append(middleware)
    }
    
    /**
     * Starts the web server on the specified host and port.
     * This method configures the server with all registered routes and middleware,
     * starts listening for incoming connections, and enters the main run loop.
     * - Parameters:
     *   - host: The hostname or IP address to bind to (defaults to "localhost")
     *   - port: The port number to listen on (defaults to 8000)
     */
    public mutating func run(host: String = "localhost", port: Int = 8000) {
        print("Starting server at http://\(host):\(port)")
        
        // Create a middleware request handler that wraps the router handler
        let routerHandler = RouterRequestHandler(router: router)
        let middlewareHandler = MiddlewareRequestHandler(
            handler: routerHandler,
            middlewares: middlewares
        )
        
        let server = serverFactory(middlewareHandler)
        server.start(host: host, port: port)
        
        RunLoop.main.run()
    }
    
    /**
     * Helper method to register a route with the specified HTTP method, path, and handler.
     * This internal method is used by the public HTTP method functions (get, post, etc.)
     * to avoid code duplication.
     * - Parameters:
     *   - method: The HTTP method for this route
     *   - path: The URL path to match for this route
     *   - handler: The function to execute when this route is matched
     */
    private mutating func registerRoute(method: HTTPMethod, path: String, handler: @escaping Handler) {
        let route = Route(method: method, path: path, handler: handler)
        routes.append(route)
        router.register(route)
    }
}
