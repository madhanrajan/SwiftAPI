//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

// Application Protocol
public protocol ApplicationProtocol {
    mutating func get(_ path: String, handler: @escaping Handler)
    mutating func post(_ path: String, handler: @escaping Handler)
    mutating func put(_ path: String, handler: @escaping Handler)
    mutating func delete(_ path: String, handler: @escaping Handler)
    mutating func run(host: String, port: Int)  // Changed to mutating
}

// App Implementation
public struct App: ApplicationProtocol {
    private var routes: [Route] = []
    private var router: RouterProtocol
    private let serverFactory: (RequestHandlerType) -> ServerType
    
    public init(
        router: RouterProtocol = Router(),
        serverFactory: @escaping (RequestHandlerType) -> ServerType = { Server(requestHandler: $0) }
    ) {
        self.router = router
        self.serverFactory = serverFactory
    }
    
    public mutating func get(_ path: String, handler: @escaping Handler) {
        registerRoute(method: .get, path: path, handler: handler)
    }
    
    public mutating func post(_ path: String, handler: @escaping Handler) {
        registerRoute(method: .post, path: path, handler: handler)
    }
    
    public mutating func put(_ path: String, handler: @escaping Handler) {
        registerRoute(method: .put, path: path, handler: handler)
    }
    
    public mutating func delete(_ path: String, handler: @escaping Handler) {
        registerRoute(method: .delete, path: path, handler: handler)
    }
    
    public mutating func run(host: String = "localhost", port: Int = 8000) {
        print("Starting server at http://\(host):\(port)")
        
        let requestHandler = RouterRequestHandler(router: router)
        let server = serverFactory(requestHandler)
        
        server.start(host: host, port: port)
        
        RunLoop.main.run()
    }
    
    private mutating func registerRoute(method: HTTPMethod, path: String, handler: @escaping Handler) {
        let route = Route(method: method, path: path, handler: handler)
        routes.append(route)
        router.register(route)
    }
}
