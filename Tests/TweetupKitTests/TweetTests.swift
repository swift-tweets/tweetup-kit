import XCTest
@testable import TweetupKit

class TweetTests: XCTestCase {
    func testDescription() {
        do {
            let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!")
            let result = tweet.description
            XCTAssertEqual(result, "Twinkle, twinkle, little star,\nHow I wonder what you are!")
        }
        
        do {
            let tweet = try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .code(Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")")))
            let result = tweet.description
            XCTAssertEqual(result, "Up above the world so high,\nLike a diamond in the sky.\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```")
        }
        
        do {
            let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!", attachment: .image(Image(alternativeText: "", path: "path/to/image.png")))
            let result = tweet.description
            XCTAssertEqual(result, "Twinkle, twinkle, little star,\nHow I wonder what you are!\n\n![](path/to/image.png)")
        }
    }
}
