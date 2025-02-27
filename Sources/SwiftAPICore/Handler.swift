//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

/**
 * Protocol defining the core request handling functionality.
 * This is the fundamental interface for any component that processes HTTP requests
 * and produces responses.
 */
public protocol RequestHandlerType {
    /**
     * Processes an HTTP request and returns a response.
     * - Parameter request: The HTTP request to handle
     * - Returns: The HTTP response to send back to the client
     */
    func handle(request: Request) -> Response
}

/**
 * An adapter that makes a Router conform to the RequestHandlerType protocol.
 * This allows a router to be used in the request handling pipeline.
 */
public struct RouterRequestHandler: RequestHandlerType {
    /// The router that will handle the routing of requests
    private let router: RouterProtocol
    
    /**
     * Initializes a new RouterRequestHandler with the specified router.
     * - Parameter router: The router to use for handling requests
     */
    public init(router: RouterProtocol) {
        self.router = router
    }
    
    /**
     * Handles an HTTP request by delegating to the router.
     * - Parameter request: The HTTP request to handle
     * - Returns: The HTTP response from the matched route handler
     */
    public func handle(request: Request) -> Response {
        return router.route(request)
    }
}

/**
 * A request handler that applies middleware to requests before delegating to another handler.
 * This implements both RequestHandlerType and MiddlewareProvider to process requests
 * through a middleware pipeline.
 */
public struct MiddlewareRequestHandler: RequestHandlerType, MiddlewareProvider {
    /// The underlying request handler that will process the request after middleware
    public let handler: RequestHandlerType
    
    /// The collection of middleware to apply to requests
    public let middlewares: [Middleware]
    
    /**
     * Initializes a new MiddlewareRequestHandler with the specified handler and middleware.
     * - Parameters:
     *   - handler: The request handler to delegate to after applying middleware
     *   - middlewares: The middleware to apply to requests (defaults to an empty array)
     */
    public init(handler: RequestHandlerType, middlewares: [Middleware] = []) {
        self.handler = handler
        self.middlewares = middlewares
    }
    
    /**
     * Handles an HTTP request by applying all middleware and then delegating to the underlying handler.
     * - Parameter request: The HTTP request to handle
     * - Returns: The HTTP response after processing through middleware and the handler
     */
    public func handle(request: Request) -> Response {
        return apply(request: request) { req in
            handler.handle(request: req)
        }
    }
}
