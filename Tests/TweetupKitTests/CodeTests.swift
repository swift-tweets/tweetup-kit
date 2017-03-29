import XCTest
@testable import TweetupKit

class CodeTests: XCTestCase {
    func testDescription() {
        do {
            let code = Code(language: .swift, fileName: "foo.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)\")")
            let result = code.description
            XCTAssertEqual(result, "```swift:foo.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)\")\n```")
        }
        
        do {
            let code = Code(language: .other("foo"), fileName: "bar.foo", body: "let name = \"Swift\"\nprint(\"Hello \\(name)\")")
            let result = code.description
            XCTAssertEqual(result, "```foo:bar.foo\nlet name = \"Swift\"\nprint(\"Hello \\(name)\")\n```")
        }
    }
}
