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
            let speaker = Speaker(twitterCredential: twitterCredential, githubToken: githubToken, outputDirectoryPath: imageDirectoryPath)
            
            let start = Date.timeIntervalSinceReferenceDate
            
            let expectation = self.expectation(description: "")

            let string = """
                Twinkle, twinkle, little star,
                How I wonder what you are! \(start)

                ---

                Up above the world so high,
                Like a diamond in the sky. \(start)

                ```swift:hello.swift
                let name = "Swift"
                print("Hello \\(name)!")
                ```

                ---

                Twinkle, twinkle, little star,
                How I wonder what you are! \(start)

                ![](\(imagePath))
                """ // includes `start` to avoid duplicate tweets
            let tweets = try! Tweet.tweets(from: string)
            speaker.post(tweets: tweets, interval: 10.0).get { getIds in
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

            waitForExpectations(timeout: 29.0, handler: nil)
            
            let end = Date.timeIntervalSinceReferenceDate
            
            XCTAssertGreaterThan(end - start, 20.0)
        }
        
        do { // error duraing posting tweets
            let speaker = Speaker(twitterCredential: twitterCredential, githubToken: githubToken)
            
            let start = Date.timeIntervalSinceReferenceDate
            
            let expectation = self.expectation(description: "")
            
            let string = """
                Twinkle, twinkle, little star,
                How I wonder what you are! \(start)

                ---

                Up above the world so high,
                Like a diamond in the sky. \(start)

                ![](illegal/path/to/image.png)

                ---

                Twinkle, twinkle, little star,
                How I wonder what you are! \(start)

                ```swift:hello.swift
                let name = "Swift"
                print("Hello \\(name)!")
                ```
                """ // includes `start` to avoid duplicate tweets
            let tweets = try! Tweet.tweets(from: string)
            speaker.post(tweets: tweets, interval: 10.0).get { getIds in
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
            
            let string = """
                Twinkle, twinkle, little star,
                How I wonder what you are!

                ---

                Up above the world so high,
                Like a diamond in the sky.

                ```swift:hello.swift
                let name = "Swift"
                print("Hello \\(name)!")
                ```

                ---

                Twinkle, twinkle, little star,
                How I wonder what you are!

                ![](\(imagePath))

                ---

                When the blazing sun is gone,
                When he nothing shines upon,

                ![alternative text 1](\(imagePath))

                ---

                Then you show your little light,
                Twinkle, twinkle, all the night.

                ![alternative text 2](\(imagePath))

                ---

                Twinkle, twinkle, little star,
                How I wonder what you are!

                ![alternative text 3](\(imagePath))


                """
            let tweets = try! Tweet.tweets(from: string)
            speaker.resolveImages(of: tweets).get { getTweets in
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
                        XCTAssertEqual(result, try! Tweet(body: """
                            Twinkle, twinkle, little star,
                            How I wonder what you are!
                            """, attachment: .image(Image(alternativeText: "", source: .twitter(id)))))
                    }
                    
                    do {
                        let result = results[3]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: """
                            When the blazing sun is gone,
                            When he nothing shines upon,
                            """, attachment: .image(Image(alternativeText: "alternative text 1", source: .twitter(id)))))
                    }
                    
                    do {
                        let result = results[4]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: """
                            Then you show your little light,
                            Twinkle, twinkle, all the night.
                            """, attachment: .image(Image(alternativeText: "alternative text 2", source: .twitter(id)))))
                    }
                    
                    do {
                        let result = results[5]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: """
                            Twinkle, twinkle, little star,
                            How I wonder what you are!
                            """, attachment: .image(Image(alternativeText: "alternative text 3", source: .twitter(id)))))
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
                
                let tweet = try! Tweet(body: """
                    Twinkle, twinkle, little star,
                    How I wonder what you are!
                    """)
                speaker.resolveImage(of: tweet).get { getTweet in
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
                
                let tweet = try! Tweet(body: """
                    Up above the world so high,
                    Like a diamond in the sky.
                    """, attachment: .image(Image(alternativeText: "alternative text", source: .local(imagePath))))
                speaker.resolveImage(of: tweet).get { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: """
                            Up above the world so high,
                            Like a diamond in the sky.
                            """, attachment: .image(Image(alternativeText: "alternative text", source: .twitter(id)))))
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
                
                let tweet = try! Tweet(body: """
                    Twinkle, twinkle, little star,
                    How I wonder what you are!
                    """)
                speaker.resolveImage(of: tweet).get { getTweet in
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
                
                let tweet = try! Tweet(body: """
                    Up above the world so high,
                    Like a diamond in the sky.
                    """, attachment: .image(Image(alternativeText: "alternative text", source: .local(imagePath))))
                speaker.resolveImage(of: tweet).get { getTweet in
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
            let speaker = Speaker(twitterCredential: twitterCredential, baseDirectoryPath: imageDirectoryPath)
            
            do {
                let expectation = self.expectation(description: "")
                
                let tweet = try! Tweet(body: """
                    Up above the world so high,
                    Like a diamond in the sky.
                    """, attachment: .image(Image(alternativeText: "alternative text", source: .local("image.png"))))
                speaker.resolveImage(of: tweet).get { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        guard case let .some(.image(image)) = result.attachment, case let .twitter(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: """
                            Up above the world so high,
                            Like a diamond in the sky.
                            """, attachment: .image(Image(alternativeText: "alternative text", source: .twitter(id)))))
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
            
            let string = """
                    Twinkle, twinkle, little star,
                    How I wonder what you are!

                    ---

                    Up above the world so high,
                    Like a diamond in the sky.

                    ```swift:hello.swift
                    let name = "Swift"
                    print("Hello \\(name)!")
                    ```

                    ---

                    Twinkle, twinkle, little star,
                    How I wonder what you are!

                    ![](path/to/image.png)

                    ---

                    When the blazing sun is gone,
                    When he nothing shines upon,

                    ```swift:hello1.swift
                    let name = "Swift"
                    print(\"Hello \\(name)!\")
                    ```

                    ---

                    Then you show your little light,
                    Twinkle, twinkle, all the night.

                    ```swift:hello2.swift
                    let name = "Swift"
                    print("Hello \\(name)!")
                    ```

                    ---

                    Twinkle, twinkle, little star,
                    How I wonder what you are!

                    ```swift:hello3.swift
                    let name = "Swift"
                    print("Hello \\(name)!")
                    ```


                    """
            let tweets = try! Tweet.tweets(from: string)
            speaker.resolveCodes(of: tweets).get { getTweets in
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
                        XCTAssertEqual(result, try! Tweet(body: """
                            Up above the world so high,
                            Like a diamond in the sky.

                            https://gist.github.com/\(id)
                            """, attachment: .image(Image(alternativeText: "", source: .gist(id)))))
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
                        XCTAssertEqual(result, try! Tweet(body: """
                            When the blazing sun is gone,
                            When he nothing shines upon,

                            https://gist.github.com/\(id)
                            """, attachment: .image(Image(alternativeText: "", source: .gist(id)))))
                    }
                    
                    do {
                        let result = results[4]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .gist(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: """
                            Then you show your little light,
                            Twinkle, twinkle, all the night.

                            https://gist.github.com/\(id)
                            """, attachment: .image(Image(alternativeText: "", source: .gist(id)))))
                    }
                    
                    do {
                        let result = results[5]
                        
                        guard case let .some(.image(image)) = result.attachment, case let .gist(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: """
                            Twinkle, twinkle, little star,
                            How I wonder what you are!

                            https://gist.github.com/\(id)
                            """, attachment: .image(Image(alternativeText: "", source: .gist(id)))))
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
                
                let tweet = try! Tweet(body: """
                    Twinkle, twinkle, little star,
                    How I wonder what you are!
                    """)
                speaker.resolveCode(of: tweet).get { getTweet in
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
                
                let tweet = try! Tweet(body: """
                    Up above the world so high,
                    Like a diamond in the sky.
                    """, attachment: .code(Code(language: .swift, fileName: "hello.swift", body: """
                    let name = "Swift"
                    print("Hello \\(name)!")
                    """)))
                speaker.resolveCode(of: tweet).get { getTweet in
                    defer {
                        expectation.fulfill()
                    }
                    do {
                        let result = try getTweet()
                        guard case let .some(.image(image)) = result.attachment, case let .gist(id) = image.source else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(result, try! Tweet(body: """
                            Up above the world so high,
                            Like a diamond in the sky.

                            https://gist.github.com/\(id)
                            """, attachment: .image(Image(alternativeText: "", source: .gist(id)))))
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
                
                let tweet = try! Tweet(body: """
                    Twinkle, twinkle, little star,
                    How I wonder what you are!
                    """)
                speaker.resolveCode(of: tweet).get { getTweet in
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
                
                let tweet = try! Tweet(body: """
                    Up above the world so high,
                    Like a diamond in the sky.
                    """, attachment: .code(Code(language: .swift, fileName: "hello.swift", body: """
                    let name = "Swift"
                    print("Hello \\(name)!")
                    """)))
                speaker.resolveCode(of: tweet).get { getTweet in
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
