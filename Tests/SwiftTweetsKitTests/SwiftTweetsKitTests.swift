import XCTest
@testable import SwiftTweetsKit

class SwiftTweetsKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SwiftTweetsKit().text, "Hello, World!")
    }


    static var allTests : [(String, (SwiftTweetsKitTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
