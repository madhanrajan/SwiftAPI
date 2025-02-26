//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

// Base HTTP types
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case options = "OPTIONS"
}

// Request-related types
public protocol RequestProtocol {
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: [String: String] { get }
    var query: [String: String] { get }
    var body: [String: Any] { get }
}

public extension RequestProtocol {
    func header(_ name: String) -> String? {
        return headers[name]
    }
    
    func queryParam(_ name: String) -> String? {
        return query[name]
    }
}

public struct Request: RequestProtocol {
    public let method: HTTPMethod
    public let path: String
    public let headers: [String: String]
    public let query: [String: String]
    public let body: [String: Any]
    
    public init(method: HTTPMethod, path: String, headers: [String: String] = [:], query: [String: String] = [:], body: [String: Any] = [:]) {
        self.method = method
        self.path = path
        self.headers = headers
        self.query = query
        self.body = body
    }
}

// Response-related types
public protocol ResponseProtocol {
    var statusCode: Int { get }
    var headers: [String: String] { get }
    var body: [String: Any] { get }
    var json: Data? { get }
}

public struct Response: ResponseProtocol {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: [String: Any]
    
    public init(statusCode: Int = 200, headers: [String: String] = [:], body: [String: Any] = [:]) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
    
    public var json: Data? {
        try? JSONSerialization.data(withJSONObject: body, options: [])
    }
}

// Handler and Route definitions
public typealias Handler = (Request) -> Response

public struct Route {
    public let method: HTTPMethod
    public let path: String
    public let handler: Handler
    
    public init(method: HTTPMethod, path: String, handler: @escaping Handler) {
        self.method = method
        self.path = path
        self.handler = handler
    }
}

