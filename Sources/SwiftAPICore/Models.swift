//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

/**
 * Enumeration of HTTP methods supported by the framework.
 * Each case represents a standard HTTP method with its raw string value.
 */
public enum HTTPMethod: String {
    /// HTTP GET method for retrieving resources
    case get = "GET"
    
    /// HTTP POST method for creating resources
    case post = "POST"
    
    /// HTTP PUT method for updating resources
    case put = "PUT"
    
    /// HTTP DELETE method for removing resources
    case delete = "DELETE"
    
    /// HTTP OPTIONS method for describing communication options
    case options = "OPTIONS"
}

/**
 * Protocol defining the structure of an HTTP request.
 * This protocol establishes the core properties that any request must have.
 */
public protocol RequestProtocol {
    /// The HTTP method of the request (GET, POST, etc.)
    var method: HTTPMethod { get }
    
    /// The URL path of the request
    var path: String { get }
    
    /// The HTTP headers of the request
    var headers: [String: String] { get }
    
    /// The query parameters of the request
    var query: [String: String] { get }
    
    /// The body of the request as a dictionary
    var body: [String: Any] { get }
}

/**
 * Extension to RequestProtocol that provides convenience methods for accessing headers and query parameters.
 */
public extension RequestProtocol {
    /**
     * Gets the value of a specific header.
     * - Parameter name: The name of the header
     * - Returns: The value of the header, or nil if the header doesn't exist
     */
    func header(_ name: String) -> String? {
        return headers[name]
    }
    
    /**
     * Gets the value of a specific query parameter.
     * - Parameter name: The name of the query parameter
     * - Returns: The value of the query parameter, or nil if the parameter doesn't exist
     */
    func queryParam(_ name: String) -> String? {
        return query[name]
    }
}

/**
 * Concrete implementation of the RequestProtocol.
 * This struct represents an HTTP request with all its components.
 */
public struct Request: RequestProtocol {
    /// The HTTP method of the request (GET, POST, etc.)
    public let method: HTTPMethod
    
    /// The URL path of the request
    public let path: String
    
    /// The HTTP headers of the request
    public let headers: [String: String]
    
    /// The query parameters of the request
    public let query: [String: String]
    
    /// The body of the request as a dictionary
    public let body: [String: Any]
    
    /**
     * Initializes a new Request with the specified components.
     * - Parameters:
     *   - method: The HTTP method of the request
     *   - path: The URL path of the request
     *   - headers: The HTTP headers of the request (defaults to empty)
     *   - query: The query parameters of the request (defaults to empty)
     *   - body: The body of the request (defaults to empty)
     */
    public init(method: HTTPMethod, path: String, headers: [String: String] = [:], query: [String: String] = [:], body: [String: Any] = [:]) {
        self.method = method
        self.path = path
        self.headers = headers
        self.query = query
        self.body = body
    }
}

/**
 * Protocol defining the structure of an HTTP response.
 * This protocol establishes the core properties that any response must have.
 */
public protocol ResponseProtocol {
    /// The HTTP status code of the response
    var statusCode: Int { get }
    
    /// The HTTP headers of the response
    var headers: [String: String] { get }
    
    /// The body of the response as a dictionary
    var body: [String: Any] { get }
    
    /// The body of the response serialized as JSON data
    var json: Data? { get }
}

/**
 * Concrete implementation of the ResponseProtocol.
 * This struct represents an HTTP response with all its components.
 */
public struct Response: ResponseProtocol {
    /// The HTTP status code of the response
    public let statusCode: Int
    
    /// The HTTP headers of the response
    public let headers: [String: String]
    
    /// The body of the response as a dictionary
    public let body: [String: Any]
    
    /**
     * Initializes a new Response with the specified components.
     * - Parameters:
     *   - statusCode: The HTTP status code of the response (defaults to 200 OK)
     *   - headers: The HTTP headers of the response (defaults to empty)
     *   - body: The body of the response (defaults to empty)
     */
    public init(statusCode: Int = 200, headers: [String: String] = [:], body: [String: Any] = [:]) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
    
    /**
     * Gets the body of the response serialized as JSON data.
     * - Returns: The body as JSON data, or nil if serialization fails
     */
    public var json: Data? {
        try? JSONSerialization.data(withJSONObject: body, options: [])
    }
}

/**
 * Type alias for a function that handles an HTTP request and returns a response.
 * This is the core function type used for route handlers.
 */
public typealias Handler = (Request) -> Response

/**
 * Structure representing a route in the application.
 * A route combines an HTTP method, a path, and a handler function.
 */
public struct Route {
    /// The HTTP method of the route (GET, POST, etc.)
    public let method: HTTPMethod
    
    /// The URL path of the route
    public let path: String
    
    /// The function that handles requests to this route
    public let handler: Handler
    
    /**
     * Initializes a new Route with the specified components.
     * - Parameters:
     *   - method: The HTTP method of the route
     *   - path: The URL path of the route
     *   - handler: The function that handles requests to this route
     */
    public init(method: HTTPMethod, path: String, handler: @escaping Handler) {
        self.method = method
        self.path = path
        self.handler = handler
    }
}
