import XCTest
@testable import TweetupKit

import Foundation

class TwitterTests: XCTestCase {
    var credential: OAuthCredential?

    override func setUp() {
        super.setUp()
        
        let path = #file.deletingLastPathComponent.deletingLastPathComponent.appendingPathComponent("twitter.json")
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            XCTFail("Put a file at \(path), which contains tokens of Twitter for the tests in the format same as twitter-template.json in the same directory.")
            return
        }
        
        let json: [String: Any]
        do {
            json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        } catch let error {
            XCTFail("\(error)")
            return
        }
        
        guard let consumerKey = json["consumerKey"] as? String else {
            XCTFail("Lack of `consumerKey` in \(path).")
            return
        }
        guard let consumerSecret = json["consumerSecret"] as? String else {
            XCTFail("Lack of `consumerSecret` in \(path).")
            return
        }
        guard let oauthToken = json["oauthToken"] as? String else {
            XCTFail("Lack of `oauthToken` in \(path).")
            return
        }
        guard let oauthTokenSecret = json["oauthTokenSecret"] as? String else {
            XCTFail("Lack of `oauthTokenSecret` in \(path).")
            return
        }
        
        credential = OAuthCredential(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            oauthToken: oauthToken,
            oauthTokenSecret: oauthTokenSecret
        )
    }
    
    override func tearDown() {
        credential = nil
        super.tearDown()
    }
    
    func testUpdateStatus() {
        guard let credential = credential else { return }
        
        let expectation = self.expectation(description: "")
        
        Twitter.update(status: "TweetupKitTest: testUpdateStatus at \(Date.timeIntervalSinceReferenceDate)", credential: credential) { getId in
            defer {
                expectation.fulfill()
            }
            do {
                let id = try getId()
                XCTAssertTrue(try! NSRegularExpression(pattern: "^[0-9]+$").matches(in: id).count == 1)
            } catch let error {
                XCTFail("\(error)")
            }
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
