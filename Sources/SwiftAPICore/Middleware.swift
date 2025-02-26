//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

public protocol Middleware {
    func process(request: Request, next: @escaping (Request) -> Response) -> Response
}

public protocol MiddlewareProvider {
    var middlewares: [Middleware] { get }
    func apply(request: Request, handler: @escaping Handler) -> Response
}

public extension MiddlewareProvider {
    func apply(request: Request, handler: @escaping Handler) -> Response {
        let composedHandler = middlewares.reversed().reduce(handler) { nextHandler, middleware in
            return { request in
                return middleware.process(request: request, next: nextHandler)
            }
        }
        return composedHandler(request)
    }
}

public struct LoggingMiddleware: Middleware {
    public init() {}
    
    public func process(request: Request, next: @escaping (Request) -> Response) -> Response {
        print("[\(Date())] \(request.method.rawValue) \(request.path)")
        let response = next(request)
        print("[\(Date())] Responded with \(response.statusCode)")
        return response
    }
}

public struct CORSMiddleware: Middleware {
    private let allowedOrigins: [String]
    
    public init(allowedOrigins: [String] = ["*"]) {
        self.allowedOrigins = allowedOrigins
    }
    
    public func process(request: Request, next: @escaping (Request) -> Response) -> Response {
        var response = next(request)
        var headers = response.headers
        headers["Access-Control-Allow-Origin"] = allowedOrigins.joined(separator: ", ")
        headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        return Response(statusCode: response.statusCode, headers: headers, body: response.body)
    }
}

public struct ErrorHandlingMiddleware: Middleware {
    public init() {}
    
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

