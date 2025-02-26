import XCTest
@testable import SwiftAPICore

final class SwiftAPICoreTests: XCTestCase {
    func testRouterRegistersAndRoutesRequests() {
        // Setup
        var router = Router()
        let request = Request(method: .get, path: "/test")
        
        // Test route registration
        router.register(Route(method: .get, path: "/test", handler: { _ in
            Response(body: ["success": true])
        }))
        
        // Test routing
        let response = router.route(request)
        
        // Assertions
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.body["success"] as? Bool, true)
    }
    
    func testRouterReturns404ForUnknownRoute() {
        // Setup
        let router = Router()
        let request = Request(method: .get, path: "/nonexistent")
        
        // Test routing
        let response = router.route(request)
        
        // Assertions
        XCTAssertEqual(response.statusCode, 404)
        XCTAssertEqual(response.body["error"] as? String, "Not found")
    }
    
    func testMiddlewareProcessesRequests() {
        // Define a test middleware
        struct TestMiddleware: Middleware {
            func process(request: Request, next: @escaping (Request) -> Response) -> Response {
                var response = next(request)
                var body = response.body
                body["middleware"] = "processed"
                return Response(statusCode: response.statusCode, headers: response.headers, body: body)
            }
        }
        
        // Setup
        let testHandler: Handler = { _ in
            return Response(body: ["original": true])
        }
        
        let middleware = TestMiddleware()
        let provider = MiddlewareRequestHandler(
            handler: RouterRequestHandler(router: Router()),
            middlewares: [middleware]
        )
        
        // Apply middleware
        let response = provider.apply(request: Request(method: .get, path: "/"), handler: testHandler)
        
        // Assertions
        XCTAssertEqual(response.body["original"] as? Bool, true)
        XCTAssertEqual(response.body["middleware"] as? String, "processed")
    }
}
