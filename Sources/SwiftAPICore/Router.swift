//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

/**
 * Protocol defining router functionality.
 * A router is responsible for registering routes and matching incoming requests
 * to the appropriate handler based on the HTTP method and path.
 */
public protocol RouterProtocol {
    /**
     * Registers a route with the router.
     * - Parameter route: The route to register
     */
    mutating func register(_ route: Route)
    
    /**
     * Routes an incoming request to the appropriate handler.
     * - Parameter request: The request to route
     * - Returns: The response from the matched handler, or a 404 response if no match is found
     */
    func route(_ request: Request) -> Response
}

/**
 * Default implementation of the RouterProtocol.
 * This router uses a dictionary to store routes indexed by path and HTTP method,
 * allowing for efficient lookup when routing requests.
 */
public struct Router: RouterProtocol {
    /// Dictionary mapping paths to a dictionary of HTTP methods and their corresponding routes
    private var routes: [String: [HTTPMethod: Route]] = [:]
    
    /**
     * Initializes a new empty router.
     */
    public init() {}
    
    /**
     * Registers a route with the router.
     * If a route with the same path and method already exists, it will be overwritten.
     * - Parameter route: The route to register
     */
    public mutating func register(_ route: Route) {
        if routes[route.path] == nil {
            routes[route.path] = [:]
        }
        routes[route.path]?[route.method] = route
    }
    
    /**
     * Routes an incoming request to the appropriate handler.
     * Looks up the handler based on the request's path and method.
     * - Parameter request: The request to route
     * - Returns: The response from the matched handler, or a 404 response if no match is found
     */
    public func route(_ request: Request) -> Response {
        guard let pathRoutes = routes[request.path],
              let route = pathRoutes[request.method] else {
            return Response(statusCode: 404, body: ["error": "Not found"])
        }
        
        return route.handler(request)
    }
}
