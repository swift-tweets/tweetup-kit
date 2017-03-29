import XCTest
@testable import TweetupKit

class ImageTests: XCTestCase {
    func testDescription() {
        do {
            let image = Image(alternativeText: "", source: .local("path/to/image.png"))
            let result = image.description
            XCTAssertEqual(result, "![](path/to/image.png)")
        }
        
        do {
            let image = Image(alternativeText: "", source: .twitter("471592142565957632"))
            let result = image.description
            XCTAssertEqual(result, "![](twitter:471592142565957632)")
        }
        
        do {
            let image = Image(alternativeText: "", source: .gist("aa5a315d61ae9438b18d"))
            let result = image.description
            XCTAssertEqual(result, "![](gist:aa5a315d61ae9438b18d)")
        }
        
        do {
            let image = Image(alternativeText: "alternative text", source: .local("path/to/image.png"))
            let result = image.description
            XCTAssertEqual(result, "![alternative text](path/to/image.png)")
        }
    }
}
