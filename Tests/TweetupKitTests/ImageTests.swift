import XCTest
@testable import TweetupKit

class ImageTests: XCTestCase {
    func testDescription() {
        do {
            let image = Image(alternativeText: "", path: "path/to/image.png")
            let result = image.description
            XCTAssertEqual(result, "![](path/to/image.png)")
        }
        
        do {
            let image = Image(alternativeText: "alternative text", path: "path/to/image.png")
            let result = image.description
            XCTAssertEqual(result, "![alternative text](path/to/image.png)")
        }
    }
}
