//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

// Router.swift
import Foundation

public protocol RouterProtocol {
    mutating func register(_ route: Route)
    func route(_ request: Request) -> Response
}

public struct Router: RouterProtocol {
    private var routes: [String: [HTTPMethod: Route]] = [:]
    
    public init() {}
    
    public mutating func register(_ route: Route) {
        if routes[route.path] == nil {
            routes[route.path] = [:]
        }
        routes[route.path]?[route.method] = route
    }
    
    public func route(_ request: Request) -> Response {
        guard let pathRoutes = routes[request.path],
              let route = pathRoutes[request.method] else {
            return Response(statusCode: 404, body: ["error": "Not found"])
        }
        
        return route.handler(request)
    }
}
