import XCTest
@testable import TweetupKit

class TweetTests: XCTestCase {
    func testInit() {
        do {
            let result = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!")
            XCTAssertEqual(result.body, "Twinkle, twinkle, little star,\nHow I wonder what you are!")
        }
        
        do { // empty (0)
            _ = try Tweet(body: "")
            XCTFail()
        } catch TweetInitializationError.empty {
        } catch {
            XCTFail()
        }
        
        do { // 1
            let result = try! Tweet(body: "A")
            XCTAssertEqual(result.body, "A")
        }
        
        do { // 140
            let result = try! Tweet(body: "0123456789112345678921234567893123456789412345678951234567896123456789712345678981234567899123456789A123456789B123456789C123456789D123456789")
            XCTAssertEqual(result.body, "0123456789112345678921234567893123456789412345678951234567896123456789712345678981234567899123456789A123456789B123456789C123456789D123456789")
        }
        
        do { // too long (141)
            _ = try Tweet(body: "0123456789112345678921234567893123456789412345678951234567896123456789712345678981234567899123456789A123456789B123456789C123456789D123456789X")
            XCTFail()
        } catch let TweetInitializationError.tooLong(body, attachment, length) {
            XCTAssertEqual(body, "0123456789112345678921234567893123456789412345678951234567896123456789712345678981234567899123456789A123456789B123456789C123456789D123456789X")
            XCTAssertNil(attachment)
            XCTAssertEqual(length, 141)
        } catch {
            XCTFail()
        }
        
        do { // too long with a `.code`
            _ = try Tweet(body: "0123456789112345678921234567893123456789412345678951234567896123456789712345678981234567899123456789A123456789B1234X", attachment: .code(Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")")))
            XCTFail()
        } catch let TweetInitializationError.tooLong(body, attachment, length) {
            XCTAssertEqual(body, "0123456789112345678921234567893123456789412345678951234567896123456789712345678981234567899123456789A123456789B1234X")
            guard let attachment = attachment else { XCTFail(); return }
            switch attachment {
            case let .code(code):
                XCTAssertEqual(code.language, .swift)
                XCTAssertEqual(code.fileName, "hello.swift")
                XCTAssertEqual(code.body, "let name = \"Swift\"\nprint(\"Hello \\(name)!\")")
            case .image(_):
                XCTFail()
            }
            XCTAssertEqual(length, 141)
        } catch {
            XCTFail()
        }
        
        do { // Swift.org as a URL
            _ = try Tweet(body: "まず Swift.org の Compiler and Standard Library を見てみました。\n> Semantic analysis includes type inference ...\nhttps://swift.org/compiler-stdlib/#compiler-architecture (6/10) #swtws")
            XCTFail()
        } catch let TweetInitializationError.tooLong(body, attachment, length) {
            XCTAssertEqual(body, "まず Swift.org の Compiler and Standard Library を見てみました。\n> Semantic analysis includes type inference ...\nhttps://swift.org/compiler-stdlib/#compiler-architecture (6/10) #swtws")
            XCTAssertNil(attachment)
            XCTAssertEqual(length, 153)
        } catch {
            XCTFail()
        }
    }
    
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
            let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!", attachment: .image(Image(alternativeText: "", source: .local("path/to/image.png"))))
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
            let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!", attachment: .image(Image(alternativeText: "", source: .local("path/to/image.png"))))
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
                XCTAssertEqual((string as NSString).substring(with: result.range(at: 2)), "http://qaleido.space")
            }

            do {
                let result = results[1]
                XCTAssertEqual((string as NSString).substring(with: result.range(at: 2)), "https://swift-tweets.github.io/?foo=bar&baz=qux#tweeters")
            }
        }
        
        do {
            let string = "まず Swift.org の Compiler and Standard Library を見てみました。\n> Semantic analysis includes type inference ...\nhttps://swift.org/compiler-stdlib/#compiler-architecture (6/10) #swtws"
            
            let results = Tweet.urlPattern.matches(in: string)
            XCTAssertEqual(results.count, 2)
            
            do {
                let result = results[0]
                XCTAssertEqual((string as NSString).substring(with: result.range(at: 2)), "Swift.org")
            }
            
            do {
                let result = results[1]
                XCTAssertEqual((string as NSString).substring(with: result.range(at: 2)), "https://swift.org/compiler-stdlib/#compiler-architecture")
            }
        }
    }
}
