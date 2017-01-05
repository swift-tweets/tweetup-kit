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
    
    func testUrlPattern() {
        do {
            let string = "Twinkle, twinkle, little star, http://qaleido.space How I wonder what you are! https://swift-tweets.github.io/?foo=bar&baz=qux#tweeters"
            
            let results = Tweet.urlPattern.matches(in: string)
            XCTAssertEqual(results.count, 2)
            
            do {
                let result = results[0]
                XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), "http://qaleido.space")
            }

            do {
                let result = results[1]
                XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), "https://swift-tweets.github.io/?foo=bar&baz=qux#tweeters")
            }
        }
    }
}
