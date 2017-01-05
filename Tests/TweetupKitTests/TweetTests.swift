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
    
    func testLength() {
        do {
            let tweet = try! Tweet(body: "A")
            let result = tweet.length
            XCTAssertEqual(result, 1)
        }
        
        do { // new lines
            let tweet = try! Tweet(body: "A\nB\nC")
            let result = tweet.length
            XCTAssertEqual(result, 5)
        }
        
        do { // Japanese
            let tweet = try! Tweet(body: "あいうえお山川空")
            let result = tweet.length
            XCTAssertEqual(result, 8)
        }
        
        do { // 16 for Twitter, 1 for Swift
            let tweet = try! Tweet(body: "🇬🇧🇨🇦🇫🇷🇩🇪🇮🇹🇯🇵🇷🇺🇺🇸")
            let result = tweet.length
            XCTAssertEqual(result, 16)
        }
        
        do { // http
            let tweet = try! Tweet(body: "http://qaleido.space")
            let result = tweet.length
            XCTAssertEqual(result, 23)
        }
        
        do { // https
            let tweet = try! Tweet(body: "https://swift-tweets.github.io")
            let result = tweet.length
            XCTAssertEqual(result, 23)
        }
        
        do { // mixed
            let tweet = try! Tweet(body: "Twinkle, twinkle, little star, http://qaleido.space How I wonder what you are! https://swift-tweets.github.io/?foo=bar&baz=qux#tweeters")
            let result = tweet.length
            XCTAssertEqual(result, 105)
        }
        
        do { // with a `.code`
            let tweet = try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .code(Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")")))
            let result = tweet.length
            XCTAssertEqual(result, 79)
        }
        
        do { // with a `.image`
            let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!", attachment: .image(Image(alternativeText: "", path: "path/to/image.png")))
            let result = tweet.length
            XCTAssertEqual(result, 57)
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
