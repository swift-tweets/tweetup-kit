import XCTest
@testable import SwiftTweetsKit

class ParserTests: XCTestCase {
    func testTweets() {
        do {
            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are!\n\n---\n\nUp above the world so high,\nLike a diamond in the sky.\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n![](path/to/image.png)"
            let tweets = try! Tweet.tweets(with: string)
            XCTAssertEqual(tweets.count, 3)
            
            do {
                let tweet = tweets[0]
                XCTAssertEqual(tweet.body, "Twinkle, twinkle, little star,\nHow I wonder what you are!")
                XCTAssertTrue(tweet.attachment == nil)
            }
            
            do {
                let tweet = tweets[1]
                XCTAssertEqual(tweet.body, "Up above the world so high,\nLike a diamond in the sky.")
                switch tweet.attachment {
                case let .some(.code(code)):
                    XCTAssertEqual(code.language, .swift)
                    XCTAssertEqual(code.fileName, "hello.swift")
                    XCTAssertEqual(code.body, "let name = \"Swift\"\nprint(\"Hello \\(name)!\")\n")
                default:
                    XCTFail()
                }
            }
            
            do {
                let tweet = tweets[2]
                XCTAssertEqual(tweet.body, "Twinkle, twinkle, little star,\nHow I wonder what you are!")
                switch tweet.attachment {
                case let .some(.image(image)):
                    XCTAssertEqual(image.alternativeText, "")
                    XCTAssertEqual(image.path, "path/to/image.png")
                default:
                    XCTFail()
                }
            }
        }
        
        do { // without blank lines
            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are!\n---\nUp above the world so high,\nLike a diamond in the sky.\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n---\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n![](path/to/image.png)"
            let tweets = try! Tweet.tweets(with: string)
            XCTAssertEqual(tweets.count, 3)
            
            do {
                let tweet = tweets[0]
                XCTAssertEqual(tweet.body, "Twinkle, twinkle, little star,\nHow I wonder what you are!")
                XCTAssertTrue(tweet.attachment == nil)
            }
            
            do {
                let tweet = tweets[1]
                XCTAssertEqual(tweet.body, "Up above the world so high,\nLike a diamond in the sky.")
                switch tweet.attachment {
                case let .some(.code(code)):
                    XCTAssertEqual(code.language, .swift)
                    XCTAssertEqual(code.fileName, "hello.swift")
                    XCTAssertEqual(code.body, "let name = \"Swift\"\nprint(\"Hello \\(name)!\")\n")
                default:
                    XCTFail()
                }
            }
            
            do {
                let tweet = tweets[2]
                XCTAssertEqual(tweet.body, "Twinkle, twinkle, little star,\nHow I wonder what you are!")
                switch tweet.attachment {
                case let .some(.image(image)):
                    XCTAssertEqual(image.alternativeText, "")
                    XCTAssertEqual(image.path, "path/to/image.png")
                default:
                    XCTFail()
                }
            }
        }
        
        do { // `TweetInitializationError`
            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are!\n\n---\n\nUp above the world so high,\nLike a diamond in the sky.\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n![](path/to/image.png)\n---"
            do {
                _ = try Tweet.tweets(with: string)
                XCTFail()
            } catch TweetInitializationError.emptyTweet {
            } catch _ {
                XCTFail()
            }
        }
        
        do { // `TweetParseError`
            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are!\n\n---\n\nUp above the world so high,\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\nLike a diamond in the sky.\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n![](path/to/image.png)"
            do {
                _ = try Tweet.tweets(with: string)
                XCTFail()
            } catch let TweetParseError.nonTailAttachment(rawString, attachment) {
                XCTAssertEqual(rawString, "Up above the world so high,\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\nLike a diamond in the sky.")
                switch attachment {
                case let .code(code):
                    XCTAssertEqual(code.language, .swift)
                    XCTAssertEqual(code.fileName, "hello.swift")
                    XCTAssertEqual(code.body, "let name = \"Swift\"\nprint(\"Hello \\(name)!\")\n")
                default:
                    XCTFail()
                }
            } catch _ {
                XCTFail()
            }
        }
        
        do {
            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are!\n\n---\n\nUp above the world so high,\nLike a diamond in the sky.\n\n```unknown\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n![](path/to/image.png)"
            do {
                _ = try Tweet.tweets(with: string)
                XCTFail()
            } catch let TweetParseError.codeWithoutFileName(rawString) {
                XCTAssertEqual(rawString, "Up above the world so high,\nLike a diamond in the sky.\n\n```unknown\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```")
            } catch _ {
                XCTFail()
            }
        }
    }
    
    func testInit() {
        do {
            let string = "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky."
            let tweet = try! Tweet(rawString: string)
            XCTAssertEqual(tweet.body, string)
            XCTAssertTrue(tweet.attachment == nil)
        }
        
        do { // with `.code`
            let string = "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.\n```swift:hello.swift\nprint(\"Hello world!\")\n```"
            let tweet = try! Tweet(rawString: string)
            XCTAssertEqual(tweet.body, "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.")
            switch tweet.attachment {
            case let .some(.code(code)):
                XCTAssertEqual(code.language, .swift)
                XCTAssertEqual(code.fileName, "hello.swift")
                XCTAssertEqual(code.body, "print(\"Hello world!\")\n")
            default:
                XCTFail()
            }
        }
        
        do { // with non-tail `.code`
            let string = "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.\n```swift:hello.swift\nprint(\"Hello world!\")\n```\nTwinkle, twinkle, little star, How I wonder what you are!"
            do {
                _ = try Tweet(rawString: string)
                XCTFail()
            } catch let TweetParseError.nonTailAttachment(rawString, .code(code)) {
                XCTAssertEqual(rawString, string)
                XCTAssertEqual(code.language, .swift)
                XCTAssertEqual(code.fileName, "hello.swift")
                XCTAssertEqual(code.body, "print(\"Hello world!\")\n")
            } catch _ {
                XCTFail()
            }
        }
        
        do { // with `.image`
            let string = "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.\n![alternative text](path/to/image.png)"
            let tweet = try! Tweet(rawString: string)
            XCTAssertEqual(tweet.body, "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.")
            switch tweet.attachment {
            case let .some(.image(image)):
                XCTAssertEqual(image.alternativeText, "alternative text")
                XCTAssertEqual(image.path, "path/to/image.png")
            default:
                XCTFail()
            }
        }
        
        do { // with non-tail `.image`
            let string = "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.\n![alternative text](path/to/image.png)\nTwinkle, twinkle, little star, How I wonder what you are!"
            do {
                _ = try Tweet(rawString: string)
                XCTFail()
            } catch let TweetParseError.nonTailAttachment(rawString, .image(image)) {
                XCTAssertEqual(rawString, string)
                XCTAssertEqual(image.alternativeText, "alternative text")
                XCTAssertEqual(image.path, "path/to/image.png")
            } catch _ {
                XCTFail()
            }
        }
        
        do { // with `.image`
            let string = "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.\n![alternative text](path/to/image.png)\n```swift:hello.swift\nprint(\"Hello world!\")\n```"
            do {
                _ = try Tweet(rawString: string)
                XCTFail()
            } catch let TweetParseError.multipleAttachments(rawString, attachments) {
                XCTAssertEqual(rawString, string)
                switch attachments[0] {
                case let .code(code):
                    XCTAssertEqual(code.language, .swift)
                    XCTAssertEqual(code.fileName, "hello.swift")
                    XCTAssertEqual(code.body, "print(\"Hello world!\")\n")
                default:
                    XCTFail()
                }
                
                switch attachments[1] {
                case let .image(image):
                    XCTAssertEqual(image.alternativeText, "alternative text")
                    XCTAssertEqual(image.path, "path/to/image.png")
                default:
                    XCTFail()
                }
            } catch _ {
                XCTFail()
            }
        }
    }
    
    func testCodePattern() {
        do {
            let string = "```swift:hello.swift\nprint(\"Hello world!\")\n```"
            
            let results = Tweet.codePattern.matches(in: string)
            XCTAssertEqual(results.count, 1)
            
            let result = results[0]
            XCTAssertEqual(result.numberOfRanges, 6)
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(0)), "```swift:hello.swift\nprint(\"Hello world!\")\n```")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(1)), "swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), ":hello.swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(3)), "hello.swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(4)), "print(\"Hello world!\")\n")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(5)), "print(\"Hello world!\")\n")
        }
        
        do {
            let string = "```swift:hello.swift\nlet s = \"Hello world!\"\nprint(s)\n```"
            
            let results = Tweet.codePattern.matches(in: string)
            XCTAssertEqual(results.count, 1)
            
            let result = results[0]
            XCTAssertEqual(result.numberOfRanges, 6)
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(0)), "```swift:hello.swift\nlet s = \"Hello world!\"\nprint(s)\n```")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(1)), "swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), ":hello.swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(3)), "hello.swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(4)), "let s = \"Hello world!\"\nprint(s)\n")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(5)), "print(s)\n")
        }
        
        do {
            let string = "foo bar\n```swift:hello.swift\nprint(\"Hello world!\")\n```\nqux"
            
            let results = Tweet.codePattern.matches(in: string)
            XCTAssertEqual(results.count, 1)
            
            let result = results[0]
            XCTAssertEqual(result.numberOfRanges, 6)
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(0)), "```swift:hello.swift\nprint(\"Hello world!\")\n```")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(1)), "swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), ":hello.swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(3)), "hello.swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(4)), "print(\"Hello world!\")\n")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(5)), "print(\"Hello world!\")\n")
        }
        
        do {
            let string = "Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.\n```swift:hello.swift\nprint(\"Hello world!\")\n```"
            
            let results = Tweet.codePattern.matches(in: string)
            XCTAssertEqual(results.count, 1)
            
            let result = results[0]
            XCTAssertEqual(result.numberOfRanges, 6)
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(0)), "```swift:hello.swift\nprint(\"Hello world!\")\n```")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(1)), "swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), ":hello.swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(3)), "hello.swift")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(4)), "print(\"Hello world!\")\n")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(5)), "print(\"Hello world!\")\n")
        }
    }
    
    func testImagePattern() {
        do {
            let string = "![](path/to/image.png)"
            
            let results = Tweet.imagePattern.matches(in: string)
            XCTAssertEqual(results.count, 1)
            
            let result = results[0]
            XCTAssertEqual(result.numberOfRanges, 3)
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(0)), "![](path/to/image.png)")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(1)), "")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), "path/to/image.png")
        }
        
        do {
            let string = "![alternative text](path/to/image.png)"
            
            let results = Tweet.imagePattern.matches(in: string)
            XCTAssertEqual(results.count, 1)
            
            let result = results[0]
            XCTAssertEqual(result.numberOfRanges, 3)
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(0)), "![alternative text](path/to/image.png)")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(1)), "alternative text")
            XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), "path/to/image.png")
        }
        
        do {
            let string = "foo bar ![alternative text 1](path/to/image1.png)\nbaz\n\n![alternative text 2](path/to/image2.png)\nqux"
            
            let results = Tweet.imagePattern.matches(in: string)
            XCTAssertEqual(results.count, 2)

            do {
                let result = results[0]
                XCTAssertEqual(result.numberOfRanges, 3)
                XCTAssertEqual((string as NSString).substring(with: result.rangeAt(0)), "![alternative text 1](path/to/image1.png)")
                XCTAssertEqual((string as NSString).substring(with: result.rangeAt(1)), "alternative text 1")
                XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), "path/to/image1.png")
            }
            
            do {
                let result = results[1]
                XCTAssertEqual(result.numberOfRanges, 3)
                XCTAssertEqual((string as NSString).substring(with: result.rangeAt(0)), "![alternative text 2](path/to/image2.png)")
                XCTAssertEqual((string as NSString).substring(with: result.rangeAt(1)), "alternative text 2")
                XCTAssertEqual((string as NSString).substring(with: result.rangeAt(2)), "path/to/image2.png")
            }
        }
        
        do {
            let string = "abcdefg"
            
            let results = Tweet.imagePattern.matches(in: string)
            XCTAssertEqual(results.count, 0)
        }
    }
}

extension NSRegularExpression {
    fileprivate func matches(in string: String) -> [NSTextCheckingResult] {
        return matches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
    }
}
