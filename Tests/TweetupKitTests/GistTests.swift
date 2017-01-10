import XCTest
@testable import TweetupKit

import Foundation

class GistTests: XCTestCase {
    var accessToken: String?
    
    override func setUp() {
        super.setUp()
        
        let path = #file.deletingLastPathComponent.deletingLastPathComponent.appendingPathComponent("github.json")
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            XCTFail("Put a file at \(path), which contains tokens of Github for the tests in the format same as github-template.json in the same directory.")
            return
        }
        
        let json: [String: Any]
        do {
            json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        } catch let error {
            XCTFail("\(error)")
            return
        }
        
        guard let accessToken = json["accessToken"] as? String else {
            XCTFail("Lack of `accessToken` in \(path).")
            return
        }

        self.accessToken = accessToken
    }
    
    override func tearDown() {
        accessToken = nil
        super.tearDown()
    }
    
    func testCreateGist() {
        guard let accessToken = accessToken else { return }

        do {
            let expectation = self.expectation(description: "")
            
            Gist.createGist(description: "", code: Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")"), accessToken: accessToken) { getUrl in
                defer {
                    expectation.fulfill()
                }
                do {
                    let url = try getUrl()
                    XCTAssertTrue(try! NSRegularExpression(pattern: "^https://gist.github.com/[0-9a-f]+$").matches(in: url.description).count == 1, url.description)
                } catch let error {
                    XCTFail("\(error)")
                }
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)
        }
        
        do { // illegal access token
            let expectation = self.expectation(description: "")
            
            Gist.createGist(description: "", code: Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")"), accessToken: "") { getUrl in
                defer {
                    expectation.fulfill()
                }
                do {
                    _ = try getUrl()
                    XCTFail()
                } catch let error as GistError {
                    guard let message = (error.json as? [String: Any])?["message"] as? String else {
                        XCTFail("\(error.json)")
                        return
                    }
                    XCTAssertEqual(message, "Bad credentials")
                } catch {
                    XCTFail()
                }
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)
        }
    }
}
