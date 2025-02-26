//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

// Request handler protocols
public protocol RequestHandlerType {
    func handle(request: Request) -> Response
}

// Router adapter that conforms to RequestHandlerType
public struct RouterRequestHandler: RequestHandlerType {
    private let router: RouterProtocol
    
    public init(router: RouterProtocol) {
        self.router = router
    }
    
    public func handle(request: Request) -> Response {
        return router.route(request)
    }
}

// Middleware handler implementation
public struct MiddlewareRequestHandler: RequestHandlerType, MiddlewareProvider {
    public let handler: RequestHandlerType
    public let middlewares: [Middleware]
    
    public init(handler: RequestHandlerType, middlewares: [Middleware] = []) {
        self.handler = handler
        self.middlewares = middlewares
    }
    
    public func handle(request: Request) -> Response {
        return apply(request: request) { req in
            handler.handle(request: req)
        }
    }
}

