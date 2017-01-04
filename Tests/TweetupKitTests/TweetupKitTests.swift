import XCTest
@testable import TweetupKit

import Foundation

class TweetupKitTests: XCTestCase {
    func testSample() {
        let string = try! String(contentsOf: URL(string: "https://gist.githubusercontent.com/koher/6707cd98ea3a2c29f58c0fdecbe4825c/raw/428dc616a87a39baf1681c910984a3f53c91378b/sample.tw")!, encoding: .utf8)
        let tweets = try! Tweet.tweets(with: string)
        XCTAssertEqual(tweets.count, 9)
        
        do {
            let tweet = tweets[5]
            switch tweet.attachment {
            case let .some(.image(image)):
                XCTAssertEqual(image.path, "path/to/image/file.png")
            default:
                XCTFail()
            }
        }
        
        do {
            let tweet = tweets[6]
            switch tweet.attachment {
            case let .some(.code(code)):
                XCTAssertEqual(code.language, .swift)
                XCTAssertEqual(code.fileName, "hello.swift")
                XCTAssertEqual(code.body, "print(\"Hello swift!\")\n")
            default:
                XCTFail()
            }
        }
    }

    static var allTests : [(String, (TweetupKitTests) -> () throws -> Void)] {
        return [
            ("testSample", testSample),
        ]
    }
}
