import XCTest
@testable import TweetupKit

import Foundation

class TwitterTests: XCTestCase {
    var credential: OAuthCredential?

    override func setUp() {
        super.setUp()
        
        do {
            credential = try loadTwitterCredential()
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    override func tearDown() {
        credential = nil
        super.tearDown()
    }
    
    func testUpdateStatus() {
        guard let credential = credential else { return }
        
        do {
            let expectation = self.expectation(description: "")
            
            Twitter.update(status: "TweetupKitTest: testUpdateStatus at \(Date.timeIntervalSinceReferenceDate)", credential: credential) { getId in
                defer {
                    expectation.fulfill()
                }
                do {
                    let (id, _) = try getId()
                    XCTAssertTrue(try! NSRegularExpression(pattern: "^[0-9]+$").matches(in: id).count == 1)
                } catch let error {
                    XCTFail("\(error)")
                }
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)
        }
        
        do {
            let expectation = self.expectation(description: "")
            
            let data = try! Data(contentsOf: URL(fileURLWithPath: imagePath))
            Twitter.upload(media: data, credential: credential) { getMediaId in
                do {
                    let mediaId = try getMediaId()
                    Twitter.update(status: "TweetupKitTest: testUpdateStatus at \(Date.timeIntervalSinceReferenceDate)", mediaId: mediaId, credential: credential) { getId in
                        defer {
                            expectation.fulfill()
                        }
                        do {
                            let (id, _) = try getId()
                            XCTAssertTrue(try! NSRegularExpression(pattern: "^[0-9]+$").matches(in: id).count == 1)
                        } catch let error {
                            XCTFail("\(error)")
                        }
                    }
                } catch let error {
                    XCTFail("\(error)")
                }
            }
            
            waitForExpectations(timeout: 40.0, handler: nil)
        }
    }
    
    func testUploadMedia() {
        guard let credential = credential else { return }
        
        let expectation = self.expectation(description: "")
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: imagePath))
        Twitter.upload(media: data, credential: credential) { getId in
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
        
        waitForExpectations(timeout: 30.0, handler: nil)
    }
}

func loadTwitterCredential() throws -> OAuthCredential {
    let path = #file.deletingLastPathComponent.deletingLastPathComponent.appendingPathComponent("twitter.json")
    let data: Data
    do {
        data = try Data(contentsOf: URL(fileURLWithPath: path))
    } catch {
        throw GeneralError(message: "Put a file at \(path), which contains tokens of Twitter for the tests in the format same as twitter-template.json in the same directory.")
    }
    
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    
    guard let consumerKey = json["consumerKey"] as? String else {
        throw GeneralError(message: "Lack of `consumerKey` in \(path).")
    }
    guard let consumerSecret = json["consumerSecret"] as? String else {
        throw GeneralError(message: "Lack of `consumerSecret` in \(path).")
    }
    guard let oauthToken = json["oauthToken"] as? String else {
        throw GeneralError(message: "Lack of `oauthToken` in \(path).")
    }
    guard let oauthTokenSecret = json["oauthTokenSecret"] as? String else {
        throw GeneralError(message: "Lack of `oauthTokenSecret` in \(path).")
    }
    
    return OAuthCredential(
        consumerKey: consumerKey,
        consumerSecret: consumerSecret,
        oauthToken: oauthToken,
        oauthTokenSecret: oauthTokenSecret
    )
}

let imageDirectoryPath = #file.deletingLastPathComponent.deletingLastPathComponent
let imagePath = imageDirectoryPath.appendingPathComponent("image.png")
