//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

/**
 * Protocol defining middleware functionality.
 * Middleware intercepts requests before they reach their handlers,
 * allowing for cross-cutting concerns like logging, authentication,
 * and error handling to be separated from business logic.
 */
public protocol Middleware {
    /**
     * Processes a request and optionally modifies it before passing it to the next handler.
     * - Parameters:
     *   - request: The HTTP request to process
     *   - next: The next handler in the middleware chain
     * - Returns: The HTTP response after processing
     */
    func process(request: Request, next: @escaping (Request) -> Response) -> Response
}

/**
 * Protocol for components that provide middleware functionality.
 * This protocol defines the interface for components that can apply
 * a collection of middleware to requests.
 */
public protocol MiddlewareProvider {
    /// The collection of middleware to apply to requests
    var middlewares: [Middleware] { get }
    
    /**
     * Applies all middleware to a request before passing it to the final handler.
     * - Parameters:
     *   - request: The HTTP request to process
     *   - handler: The final handler to call after all middleware has been applied
     * - Returns: The HTTP response after processing through middleware and the handler
     */
    func apply(request: Request, handler: @escaping Handler) -> Response
}

/**
 * Default implementation of the apply method for MiddlewareProvider.
 * This extension provides a standard way to compose middleware into a chain
 * that processes requests in the correct order.
 */
public extension MiddlewareProvider {
    /**
     * Applies all middleware to a request before passing it to the final handler.
     * This implementation composes the middleware chain in reverse order to ensure
     * that middleware is applied in the order it was added.
     * - Parameters:
     *   - request: The HTTP request to process
     *   - handler: The final handler to call after all middleware has been applied
     * - Returns: The HTTP response after processing through middleware and the handler
     */
    func apply(request: Request, handler: @escaping Handler) -> Response {
        let composedHandler = middlewares.reversed().reduce(handler) { nextHandler, middleware in
            return { request in
                return middleware.process(request: request, next: nextHandler)
            }
        }
        return composedHandler(request)
    }
}

/**
 * Middleware that logs information about requests and responses.
 * This middleware prints the request method, path, and timestamp when a request is received,
 * and the response status code when a response is sent.
 */
public struct LoggingMiddleware: Middleware {
    /**
     * Initializes a new LoggingMiddleware.
     */
    public init() {}
    
    /**
     * Processes a request by logging information about it, then passes it to the next handler.
     * - Parameters:
     *   - request: The HTTP request to process
     *   - next: The next handler in the middleware chain
     * - Returns: The HTTP response after processing
     */
    public func process(request: Request, next: @escaping (Request) -> Response) -> Response {
        print("[\(Date())] \(request.method.rawValue) \(request.path)")
        let response = next(request)
        print("[\(Date())] Responded with \(response.statusCode)")
        return response
    }
}

/**
 * Middleware that adds Cross-Origin Resource Sharing (CORS) headers to responses.
 * This middleware allows web applications running at different origins to make requests
 * to the API by adding the appropriate CORS headers to responses.
 */
public struct CORSMiddleware: Middleware {
    /// The origins that are allowed to access the API
    private let allowedOrigins: [String]
    
    /**
     * Initializes a new CORSMiddleware with the specified allowed origins.
     * - Parameter allowedOrigins: The origins that are allowed to access the API (defaults to ["*"], which allows all origins)
     */
    public init(allowedOrigins: [String] = ["*"]) {
        self.allowedOrigins = allowedOrigins
    }
    
    /**
     * Processes a request by passing it to the next handler, then adds CORS headers to the response.
     * - Parameters:
     *   - request: The HTTP request to process
     *   - next: The next handler in the middleware chain
     * - Returns: The HTTP response with CORS headers added
     */
    public func process(request: Request, next: @escaping (Request) -> Response) -> Response {
        var response = next(request)
        var headers = response.headers
        headers["Access-Control-Allow-Origin"] = allowedOrigins.joined(separator: ", ")
        headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        return Response(statusCode: response.statusCode, headers: headers, body: response.body)
    }
}

/**
 * Middleware that catches and handles errors thrown by request handlers.
 * This middleware ensures that errors don't crash the server by catching them
 * and converting them into appropriate error responses.
 */
public struct ErrorHandlingMiddleware: Middleware {
    /**
     * Initializes a new ErrorHandlingMiddleware.
     */
    public init() {}
    
    /**
     * Processes a request by passing it to the next handler inside a try-catch block.
     * If an error is thrown, it returns a 500 Internal Server Error response.
     * - Parameters:
     *   - request: The HTTP request to process
     *   - next: The next handler in the middleware chain
     * - Returns: The HTTP response from the next handler, or an error response if an error was thrown
     */
    public func process(request: Request, next: @escaping (Request) -> Response) -> Response {
        do {
            return next(request)
        } catch {
            return Response(
                statusCode: 500,
                body: ["error": "Internal server error", "message": error.localizedDescription]
            )
        }
    }
}
