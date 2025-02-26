import XCTest
@testable import SwiftAPI

final class SwiftAPITests: XCTestCase {
    func testAppInitialization() {
        // This is just a simple test to satisfy the package structure requirements
        let app = App()
        XCTAssertNotNil(app)
    }
    
    static var allTests = [
        ("testAppInitialization", testAppInitialization),
    ]
}