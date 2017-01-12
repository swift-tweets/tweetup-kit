import XCTest
@testable import TweetupKit

import Foundation

class GistTests: XCTestCase {
    var accessToken: String?
    
    override func setUp() {
        super.setUp()
        
        do {
            self.accessToken = try loadGithubToken()
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    override func tearDown() {
        accessToken = nil
        super.tearDown()
    }
    
    func testCreateGist() {
        guard let accessToken = accessToken else { return }

        do {
            let expectation = self.expectation(description: "")
            
            Gist.createGist(description: "", code: Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")"), accessToken: accessToken) { getId in
                defer {
                    expectation.fulfill()
                }
                do {
                    let id = try getId()
                    XCTAssertTrue(try! NSRegularExpression(pattern: "^[0-9a-f]+$").matches(in: id.description).count == 1, id.description)
                } catch let error {
                    XCTFail("\(error)")
                }
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)
        }
        
        do { // illegal access token
            let expectation = self.expectation(description: "")
            
            Gist.createGist(description: "", code: Code(language: .swift, fileName: "hello.swift", body: "let name = \"Swift\"\nprint(\"Hello \\(name)!\")"), accessToken: "") { getId in
                defer {
                    expectation.fulfill()
                }
                do {
                    _ = try getId()
                    XCTFail()
                } catch let error as APIError {
                    guard let message = (error.json as? [String: Any])?["message"] as? String else {
                        XCTFail("\(error.json)")
                        return
                    }
                    XCTAssertEqual(message, "Bad credentials")
                } catch let error {
                    XCTFail("\(error)")
                }
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)
        }
    }
}

func loadGithubToken() throws -> String {
    let path = #file.deletingLastPathComponent.deletingLastPathComponent.appendingPathComponent("github.json")
    let data: Data
    do {
        data = try Data(contentsOf: URL(fileURLWithPath: path))
    } catch {
        throw GeneralError(message: "Put a file at \(path), which contains tokens of Github for the tests in the format same as github-template.json in the same directory.")
    }
    
    let json: [String: Any] = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    
    guard let accessToken = json["accessToken"] as? String else {
        throw GeneralError(message: "Lack of `accessToken` in \(path).")
    }
    
    return accessToken
}
