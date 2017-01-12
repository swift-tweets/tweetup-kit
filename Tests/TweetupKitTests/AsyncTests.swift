import XCTest
@testable import TweetupKit

import Foundation

class AsyncTests: XCTestCase {
    func testRepeated() {
        let expectation = self.expectation(description: "")
        
        let start = Date.timeIntervalSinceReferenceDate
        
        repeated(operation: asyncIncrement, interval: 2.0)(Array(1...5)) { getValues in
            defer {
                expectation.fulfill()
            }
            
            do {
                let values = try getValues()
                XCTAssertEqual(values, [2, 3, 4 ,5, 6])
            } catch let error {
                XCTFail("\(error)")
            }
        }
        
        waitForExpectations(timeout: 8.5, handler: nil)
        
        let end = Date.timeIntervalSinceReferenceDate
        
        XCTAssertGreaterThan(end - start, 8.0)
    }
    
    func testWaiting() {
        let expectation = self.expectation(description: "")
        
        let start = Date.timeIntervalSinceReferenceDate
        
        waiting(operation: asyncIncrement, with: 2.0)(42) { getValue in
            defer {
                expectation.fulfill()
            }
            
            do {
                let value = try getValue()
                XCTAssertEqual(value, 43)
            } catch let error {
                XCTFail("\(error)")
            }
        }
        
        waitForExpectations(timeout: 2.5, handler: nil)
        
        let end = Date.timeIntervalSinceReferenceDate
        
        XCTAssertGreaterThan(end - start, 2.0)
    }
}

private func asyncIncrement(value: Int, completion: @escaping (() throws -> Int) -> ()) {
    Async.executionQueue.async {
        completion {
            value + 1
        }
    }
}
