//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation
import NIO
import NIOHTTP1

/**
 * Protocol defining server functionality.
 * A server is responsible for listening for incoming HTTP connections,
 * processing requests, and sending responses.
 */
public protocol ServerType {
    /**
     * Starts the server on the specified host and port.
     * - Parameters:
     *   - host: The hostname or IP address to bind to
     *   - port: The port number to listen on
     */
    func start(host: String, port: Int)
    
    /**
     * Stops the server and releases any resources.
     */
    func stop()
}

/**
 * Protocol defining request builder functionality.
 * A request builder is responsible for constructing a Request object
 * from the raw HTTP components received from the network.
 */
public protocol RequestBuilderProtocol {
    /**
     * Sets the HTTP request head (method, URI, version, headers).
     * - Parameter header: The HTTP request head
     */
    mutating func setHead(header: HTTPRequestHead)
    
    /**
     * Appends data to the request body.
     * - Parameter buffer: The buffer containing body data
     */
    mutating func appendBody(buffer: ByteBuffer)
    
    /**
     * Builds a Request object from the accumulated components.
     * - Returns: A Request object, or nil if the request is invalid or incomplete
     */
    func build() -> Request?
    
    /**
     * Resets the builder to its initial state.
     */
    mutating func reset()
}

/**
 * Enumeration of options for providing an event loop group to the server.
 * This allows for flexibility in how the server's event loop is managed.
 */
public enum NIOEventLoopGroupProvider {
    /// Create a new event loop group for the server
    case createNew
    
    /// Use a shared event loop group
    case shared(EventLoopGroup)
}

/**
 * Implementation of the ServerType protocol using SwiftNIO.
 * This server uses SwiftNIO to handle low-level networking and HTTP parsing,
 * and delegates request handling to a RequestHandlerType.
 */
public final class Server: ServerType {
    /// The handler that will process HTTP requests
    private let requestHandler: RequestHandlerType
    
    /// The event loop group that will handle I/O events
    private let group: EventLoopGroup
    
    /// The channel that the server is listening on
    private var channel: Channel?
    
    /**
     * Initializes a new Server with the specified request handler and event loop group provider.
     * - Parameters:
     *   - requestHandler: The handler that will process HTTP requests
     *   - eventLoopGroupProvider: The provider for the event loop group (defaults to creating a new group)
     */
    public init(requestHandler: RequestHandlerType, eventLoopGroupProvider: NIOEventLoopGroupProvider = .createNew) {
        self.requestHandler = requestHandler
        
        switch eventLoopGroupProvider {
        case .createNew:
            self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        case .shared(let group):
            self.group = group
        }
    }
    
    /**
     * Starts the server on the specified host and port.
     * This method configures the server, binds it to the specified address,
     * and starts listening for incoming connections.
     * - Parameters:
     *   - host: The hostname or IP address to bind to
     *   - port: The port number to listen on
     */
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
    
    /**
     * Stops the server and releases any resources.
     * This method closes the server channel and shuts down the event loop group.
     */
    public func stop() {
        do {
            try channel?.close().wait()
            try group.syncShutdownGracefully()
            print("Server stopped")
        } catch {
            print("Error stopping server: \(error)")
        }
    }
    
    /**
     * Deinitializer that ensures the event loop group is shut down when the server is deallocated.
     */
    deinit {
        do {
            try group.syncShutdownGracefully()
        } catch {
            print("Error shutting down event loop group: \(error)")
        }
    }
}

/**
 * SwiftNIO channel handler that processes HTTP requests.
 * This handler receives HTTP request parts from the network,
 * builds a Request object, passes it to the request handler,
 * and sends the response back to the client.
 */
public final class HTTPServerHandler: ChannelInboundHandler {
    /// The type of inbound messages this handler expects
    public typealias InboundIn = HTTPServerRequestPart
    
    /// The type of outbound messages this handler produces
    public typealias OutboundOut = HTTPServerResponsePart
    
    /// The handler that will process HTTP requests
    public let requestHandler: RequestHandlerType
    
    /// The builder that will construct Request objects from HTTP parts
    private var requestBuilder: RequestBuilderProtocol = RequestBuilder()
    
    /**
     * Initializes a new HTTPServerHandler with the specified request handler.
     * - Parameter requestHandler: The handler that will process HTTP requests
     */
    public init(requestHandler: RequestHandlerType) {
        self.requestHandler = requestHandler
    }
    
    /**
     * Handles incoming channel data.
     * This method is called by SwiftNIO when data is received on the channel.
     * It processes HTTP request parts and builds a complete request.
     * - Parameters:
     *   - context: The context for the channel handler
     *   - data: The data received on the channel
     */
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
    
    /**
     * Sends an HTTP response to the client.
     * This method converts a Response object into HTTP response parts
     * and writes them to the channel.
     * - Parameters:
     *   - context: The context for the channel handler
     *   - response: The response to send
     */
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
    
    /**
     * Sends an error response to the client.
     * This method is called when the request builder fails to build a valid request.
     * - Parameter context: The context for the channel handler
     */
    private func sendErrorResponse(context: ChannelHandlerContext) {
        let errorResponse = Response(
            statusCode: 400,
            body: ["error": "Invalid request"]
        )
        sendResponse(context: context, response: errorResponse)
    }
}

/**
 * Implementation of the RequestBuilderProtocol.
 * This struct builds a Request object from HTTP request parts.
 */
public struct RequestBuilder: RequestBuilderProtocol {
    /// The HTTP method of the request
    private var method: HTTPMethod?
    
    /// The URL path of the request
    private var path: String?
    
    /// The query parameters of the request
    private var queryParams: [String: String] = [:]
    
    /// The HTTP headers of the request
    private var headers: [String: String] = [:]
    
    /// The accumulated body data of the request
    private var bodyData = Data()
    
    /**
     * Initializes a new empty RequestBuilder.
     */
    public init() {}
    
    /**
     * Sets the HTTP request head (method, URI, version, headers).
     * This method extracts the method, path, query parameters, and headers from the request head.
     * - Parameter header: The HTTP request head
     */
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
                   let key = String(keyValue[0]).removingPercentEncoding,
                   let value = String(keyValue[1]).removingPercentEncoding {
                    queryParams[key] = value
                }
            }
        }
        
        // Extract headers
        for (name, value) in header.headers {
            headers[name] = value
        }
    }
    
    /**
     * Appends data to the request body.
     * This method accumulates body data from multiple body parts.
     * - Parameter buffer: The buffer containing body data
     */
    public mutating func appendBody(buffer: ByteBuffer) {
        let bytes = buffer.getBytes(at: 0, length: buffer.readableBytes) ?? []
        bodyData.append(contentsOf: bytes)
    }
    
    /**
     * Builds a Request object from the accumulated components.
     * This method creates a Request object with the method, path, headers, query parameters,
     * and body that have been set. It attempts to parse the body as JSON if present.
     * - Returns: A Request object, or nil if the method or path is missing
     */
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
    
    /**
     * Resets the builder to its initial state.
     * This method clears all accumulated data to prepare for building a new request.
     */
    public mutating func reset() {
        method = nil
        path = nil
        queryParams = [:]
        headers = [:]
        bodyData = Data()
    }
}
