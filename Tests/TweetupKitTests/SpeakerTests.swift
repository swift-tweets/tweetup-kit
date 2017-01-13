import XCTest
@testable import TweetupKit

import Foundation

class SpeakerTests: XCTestCase {
    var twitterCredential: OAuthCredential?
    var githubToken: String?
    
    override func setUp() {
        super.setUp()
        
        do {
            twitterCredential = try loadTwitterCredential()
            githubToken = try loadGithubToken()
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    override func tearDown() {
        twitterCredential = nil
        githubToken = nil
        super.tearDown()
    }
    
    func testPostTweets() {
        do {
            let speaker = Speaker(twitterCredential: twitterCredential, githubToken: githubToken)
            
            let start = Date.timeIntervalSinceReferenceDate
            
            let expectation = self.expectation(description: "")

            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are! \(start)\n\n---\n\nUp above the world so high,\nLike a diamond in the sky. \(start)\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are! \(start)\n\n![](\(imagePath))" // includes `start` to avoid duplicate tweets
            let tweets = try! Tweet.tweets(from: string)
            speaker.post(tweets: tweets, with: 30.0) { getIds in
                defer {
                    expectation.fulfill()
                }
                do {
                    let ids = try getIds()
                    XCTAssertEqual(ids.count, 3)
                    let idPattern = try! NSRegularExpression(pattern: "^[0-9]+$")
                    XCTAssertTrue(idPattern.matches(in: ids[0].0).count == 1)
                    XCTAssertTrue(idPattern.matches(in: ids[1].0).count == 1)
                    XCTAssertTrue(idPattern.matches(in: ids[2].0).count == 1)
                } catch let error {
                    XCTFail("\(error)")
                }
            }

            waitForExpectations(timeout: 89.0, handler: nil)
            
            let end = Date.timeIntervalSinceReferenceDate
            
            XCTAssertGreaterThan(end - start, 60.0)
        }
        
        do { // error duraing posting tweets
            let speaker = Speaker(twitterCredential: twitterCredential, githubToken: githubToken)
            
            let start = Date.timeIntervalSinceReferenceDate
            
            let expectation = self.expectation(description: "")
            
            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are! \(start)\n\n---\n\nUp above the world so high,\nLike a diamond in the sky. \(start)\n\n![](illegal/path/to/image.png)\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are! \(start)\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```" // includes `start` to avoid duplicate tweets
            let tweets = try! Tweet.tweets(from: string)
            speaker.post(tweets: tweets, with: 10.0) { getIds in
                defer {
                    expectation.fulfill()
                }
                do {
                    _ = try getIds()
                    XCTFail()
                } catch let error {
                    print(error)
                }
            }
            
            waitForExpectations(timeout: 15.0, handler: nil)
            
            let end = Date.timeIntervalSinceReferenceDate
            
            XCTAssertGreaterThan(end - start, 10.0)
        }
    }
    
    func testResolveImages() {
        do {
            let speaker = Speaker(twitterCredential: twitterCredential)
            
            let expectation = self.expectation(description: "")
            
            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are!\n\n---\n\nUp above the world so high,\nLike a diamond in the sky.\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n![](\(imagePath))\n\n---\n\nWhen the blazing sun is gone,\nWhen he nothing shines upon,\n\n![alternative text 1](\(imagePath))\n\n---\n\nThen you show your little light,\nTwinkle, twinkle, all the night.\n\n![alternative text 2](\(imagePath))\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n![alternative text 3](\(imagePath))\n\n"
            let tweets = try! Tweet.tweets(from: string)
            speaker.resolveImages(of: tweets) { getTweets in
                defer {
                    expectation.fulfill()
                }
                do {
                    let results = try getTweets()
                    
                    XCTAssertEqual(results.count, 6)
                    
                    do {
                        let result = results[0]
                        XCTAssertEqual(result, tweets[0])
                    }
                    
                    do {
                        let result = results[1]
                        XCTAssertEqual(result, tweets[1])
                    }
                    
                    do {
                        let result = results[2]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!", attachment: .image(Image(alternativeText: "", source: .twitter(id)))))
                    }
                    
                    do {
                        let result = results[3]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "When the blazing sun is gone,\nWhen he nothing shines upon,", attachment: .image(Image(alternativeText: "alternative text 1", source: .twitter(id)))))
                    }
                    
                    do {
                        let result = results[4]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Then you show your little light,\nTwinkle, twinkle, all the night.", attachment: .image(Image(alternativeText: "alternative text 2", source: .twitter(id)))))
                    }
                    
                    do {
                        let result = results[5]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!", attachment: .image(Image(alternativeText: "alternative text 3", source: .twitter(id)))))
                    }
                    
                } catch let error {
                    XCTFail("\(error)")
                }
            }
            
            waitForExpectations(timeout: 90.0, handler: nil)
        }
    }
    
    func testResolveImage() {
        guard let twitterCredential = twitterCredential else { return }
        
        do {
            let speaker = Speaker(twitterCredential: twitterCredential)
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!")
                speaker.resolveImage(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        XCTAssertEqual(result, tweet)
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .image(Image(alternativeText: "alternative text", source: .local(imagePath))))
                speaker.resolveImage(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .image(Image(alternativeText: "alternative text", source: .twitter(id)))))
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
        }
        
        do { // no token
            let speaker = Speaker()
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!")
                speaker.resolveImage(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        XCTAssertEqual(result, tweet)
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .image(Image(alternativeText: "alternative text", source: .local(imagePath))))
                speaker.resolveImage(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        _ = try getTweet()
                        XCTFail()
                    } catch SpeakerError.noTwitterCredential {
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
        }
        
        do { // base directory
            let speaker = Speaker(twitterCredential: twitterCredential, baseDirectoryPath: (imagePath as NSString).deletingLastPathComponent)
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .image(Image(alternativeText: "alternative text", source: .local("image.png"))))
                speaker.resolveImage(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .image(Image(alternativeText: "alternative text", source: .twitter(id)))))
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
        }
    }
    
    func testResolveCodes() {
        guard let githubToken = githubToken else { return }
        
        do {
            let speaker = Speaker(githubToken: githubToken)
            
            let expectation = self.expectation(description: "")
            
            let string = "Twinkle, twinkle, little star,\nHow I wonder what you are!\n\n---\n\nUp above the world so high,\nLike a diamond in the sky.\n\n```swift:hello.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n![](path/to/image.png)\n\n---\n\nWhen the blazing sun is gone,\nWhen he nothing shines upon,\n\n```swift:hello1.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n---\n\nThen you show your little light,\nTwinkle, twinkle, all the night.\n\n```swift:hello2.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n---\n\nTwinkle, twinkle, little star,\nHow I wonder what you are!\n\n```swift:hello3.swift\nlet name = \"Swift\"\nprint(\"Hello \\(name)!\")\n```\n\n"
            let tweets = try! Tweet.tweets(from: string)
            speaker.resolveCodes(of: tweets) { getTweets in
                defer {
                    expectation.fulfill()
                }
                do {
                    let results = try getTweets()
                    
                    XCTAssertEqual(results.count, 6)
                    
                    do {
                        let result = results[0]
                        XCTAssertEqual(result, tweets[0])
                    }
                    
                    do {
                        let result = results[1]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .gist(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.\n\nhttps://gist.github.com/\(id)", attachment: .image(Image(alternativeText: "", source: .gist(id)))))
                    }
                    
                    do {
                        let result = results[2]
                        XCTAssertEqual(result, tweets[2])
                    }
                    
                    do {
                        let result = results[3]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .gist(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "When the blazing sun is gone,\nWhen he nothing shines upon,\n\nhttps://gist.github.com/\(id)", attachment: .image(Image(alternativeText: "", source: .gist(id)))))
                    }
                    
                    do {
                        let result = results[4]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .gist(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Then you show your little light,\nTwinkle, twinkle, all the night.\n\nhttps://gist.github.com/\(id)", attachment: .image(Image(alternativeText: "", source: .gist(id)))))
                    }
                    
                    do {
                        let result = results[5]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .gist(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!\n\nhttps://gist.github.com/\(id)", attachment: .image(Image(alternativeText: "", source: .gist(id)))))
                    }
                    
                } catch let error {
                    XCTFail("\(error)")
                }
            }
            
            waitForExpectations(timeout: 30.0, handler: nil)
        }
    }
    
    func testResolveCode() {
        guard let githubToken = githubToken else { return }

        do {
            let speaker = Speaker(githubToken: githubToken)
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!")
                speaker.resolveCode(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        XCTAssertEqual(result, tweet)
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .code(Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")")))
                speaker.resolveCode(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        guard case let .some(.image(image)) = result.attachment, case let .gist(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.\n\nhttps://gist.github.com/\(id)", attachment: .image(Image(alternativeText: "", source: .gist(id)))))
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
        }
        
        do { // no token
            let speaker = Speaker()
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Twinkle, twinkle, little star,\nHow I wonder what you are!")
                speaker.resolveCode(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        XCTAssertEqual(result, tweet)
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: "Up above the world so high,\nLike a diamond in the sky.", attachment: .code(Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")")))
                speaker.resolveCode(of: tweet) { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        _ = try getTweet()
                        XCTFail()
                    } catch SpeakerError.noGithubToken {
                    } catch let error {
                        XCTFail("\(error)")
                    }
                }
                
                waitForExpectations(timeout: 10.0, handler: nil)
            }
        }
    }
    
    func testImagePath() {
        do {
            let path = "path/to/image"
            let from = "base/dir"
            let result = Speaker.imagePath(path, from: from)
            XCTAssertEqual(result, "base/dir/path/to/image")
        }
        
        do {
            let path = "path/to/image"
            let from = "/base/dir"
            let result = Speaker.imagePath(path, from: from)
            XCTAssertEqual(result, "/base/dir/path/to/image")
        }
        
        do {
            let path = "/path/to/image"
            let from = "base/dir"
            let result = Speaker.imagePath(path, from: from)
            XCTAssertEqual(result, "/path/to/image")
        }
        
        do {
            let path = "path/to/image"
            let from: String? = nil
            let result = Speaker.imagePath(path, from: from)
            XCTAssertEqual(result, "path/to/image")
        }
    }
}
