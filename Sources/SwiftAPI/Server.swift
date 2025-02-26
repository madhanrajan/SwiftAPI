//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

// Server.swift
import Foundation
import NIO
import NIOHTTP1

// Protocols
public protocol ServerType {
    func start(host: String, port: Int)
    func stop()
}

public protocol RequestHandlerType {
    func handle(request: Request) -> Response
}

public protocol RequestBuilderProtocol {
    mutating func setHead(header: HTTPRequestHead)
    mutating func appendBody(buffer: ByteBuffer)
    func build() -> Request?
    mutating func reset()
}

public protocol HTTPServerHandlerType: ChannelInboundHandler where InboundIn == HTTPServerRequestPart, OutboundOut == HTTPServerResponsePart {
    var requestHandler: RequestHandlerType { get }
}

// Note: Server needs to remain a class since it manages stateful resources (NIO EventLoopGroup)
public final class Server: ServerType {
    private let requestHandler: RequestHandlerType
    private let group: EventLoopGroup
    private var channel: Channel?
    
    public init(requestHandler: RequestHandlerType, eventLoopGroupProvider: NIOEventLoopGroupProvider = .createNew) {
        self.requestHandler = requestHandler
        
        switch eventLoopGroupProvider {
        case .createNew:
            self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        case .shared(let group):
            self.group = group
        }
    }
    
    public func start(host: String, port: Int) {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPServerHandler(requestHandler: self.requestHandler))
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

        do {
            let serverChannel = try bootstrap.bind(host: host, port: port).wait()
            self.channel = serverChannel
            print("Server started and listening on \(serverChannel.localAddress!)")
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    public func stop() {
        do {
            try channel?.close().wait()
            try group.syncShutdownGracefully()
            print("Server stopped")
        } catch {
            print("Error stopping server: \(error)")
        }
    }
    
    deinit {
        do {
            try group.syncShutdownGracefully()
        } catch {
            print("Error shutting down event loop group: \(error)")
        }
    }
}

// Event loop group provider options
public enum NIOEventLoopGroupProvider {
    case createNew
    case shared(EventLoopGroup)
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

// Note: HTTPServerHandler must remain a class since it inherits from ChannelInboundHandler
public final class HTTPServerHandler: ChannelInboundHandler, HTTPServerHandlerType {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    public let requestHandler: RequestHandlerType
    private var requestBuilder: RequestBuilderProtocol = RequestBuilder()
    
    public init(requestHandler: RequestHandlerType) {
        self.requestHandler = requestHandler
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let header):
            requestBuilder.setHead(header: header)
            
        case .body(let buffer):
            requestBuilder.appendBody(buffer: buffer)
            
        case .end:
            if let request = requestBuilder.build() {
                let response = requestHandler.handle(request: request)
                sendResponse(context: context, response: response)
            } else {
                sendErrorResponse(context: context)
            }
            
            requestBuilder.reset()
        }
    }
    
    private func sendResponse(context: ChannelHandlerContext, response: Response) {
        var httpHeaders = HTTPHeaders()
        
        // Add Content-Type if not specified
        if response.headers["Content-Type"] == nil {
            httpHeaders.add(name: "Content-Type", value: "application/json")
        }
        
        // Add all response headers
        for (name, value) in response.headers {
            httpHeaders.add(name: name, value: value)
        }
        
        let responseHead = HTTPResponseHead(
            version: .init(major: 1, minor: 1),
            status: HTTPResponseStatus(statusCode: response.statusCode),
            headers: httpHeaders
        )
        
        context.write(self.wrapOutboundOut(.head(responseHead))).whenFailure { error in
            print("Error writing response head: \(error)")
        }
        
        if let jsonData = response.json {
            var buffer = context.channel.allocator.buffer(capacity: jsonData.count)
            buffer.writeBytes(jsonData)
            context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer)))).whenFailure { error in
                print("Error writing response body: \(error)")
            }
        }
        
        context.writeAndFlush(self.wrapOutboundOut(.end(nil))).whenComplete { result in
            if case .failure(let error) = result {
                print("Error writing response end: \(error)")
            }
        }
    }
    
    private func sendErrorResponse(context: ChannelHandlerContext) {
        let errorResponse = Response(
            statusCode: 400,
            body: ["error": "Invalid request"]
        )
        sendResponse(context: context, response: errorResponse)
    }
}

// RequestBuilder to construct the request from HTTP parts
public struct RequestBuilder: RequestBuilderProtocol {
    private var method: HTTPMethod?
    private var path: String?
    private var queryParams: [String: String] = [:]
    private var headers: [String: String] = [:]
    private var bodyData = Data()
    
    public init() {}
    
    public mutating func setHead(header: HTTPRequestHead) {
        method = HTTPMethod(rawValue: header.method.rawValue) ?? .get
        
        // Parse the URI to extract path and query parameters
        let uriComponents = header.uri.split(separator: "?", maxSplits: 1)
        path = String(uriComponents[0])
        
        if uriComponents.count > 1 {
            let queryString = uriComponents[1]
            let pairs = queryString.split(separator: "&")
            for pair in pairs {
                let keyValue = pair.split(separator: "=", maxSplits: 1)
                if keyValue.count == 2,
                   let key = keyValue[0].removingPercentEncoding,
                   let value = keyValue[1].removingPercentEncoding {
                    queryParams[key] = value
                }
            }
        }
        
        // Extract headers
        for (name, value) in header.headers {
            headers[name] = value
        }
    }
    
    public mutating func appendBody(buffer: ByteBuffer) {
        let bytes = buffer.getBytes(at: 0, length: buffer.readableBytes) ?? []
        bodyData.append(contentsOf: bytes)
    }
    
    public func build() -> Request? {
        guard let method = method, let path = path else {
            return nil
        }
        
        var body: [String: Any] = [:]
        
        // Try to parse body data as JSON if present
        if !bodyData.isEmpty {
            do {
                if let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any] {
                    body = json
                }
            } catch {
                print("Failed to parse request body as JSON: \(error)")
            }
        }
        
        return Request(
            method: method,
            path: path,
            headers: headers,
            query: queryParams,
            body: body
        )
    }
    
    public mutating func reset() {
        method = nil
        path = nil
        queryParams = [:]
        headers = [:]
        bodyData = Data()
    }
}
