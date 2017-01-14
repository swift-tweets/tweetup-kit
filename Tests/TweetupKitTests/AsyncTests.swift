import XCTest
@testable import TweetupKit

import Foundation

class AsyncTests: XCTestCase {
    func testRepeated() {
        do {
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
        
        do {
            let expectation = self.expectation(description: "")
            
            let start = Date.timeIntervalSinceReferenceDate
            
            repeated(operation: asyncTime, interval: 2.0)([(), (), (), (), ()]) { getValues in
                defer {
                    expectation.fulfill()
                }
                
                do {
                    let values = try getValues()
                    XCTAssertEqual(values.count, 5)
                    let allowableError: TimeInterval = 0.1
                    XCTAssertLessThan(abs(values[0] - start), allowableError)
                    XCTAssertLessThan(abs(values[1] - (values[0] + 2.0)), allowableError)
                    XCTAssertLessThan(abs(values[2] - (values[1] + 2.0)), allowableError)
                    XCTAssertLessThan(abs(values[3] - (values[2] + 2.0)), allowableError)
                    XCTAssertLessThan(abs(values[4] - (values[3] + 2.0)), allowableError)
                } catch let error {
                    XCTFail("\(error)")
                }
            }
            
            waitForExpectations(timeout: 8.5, handler: nil)
            
            let end = Date.timeIntervalSinceReferenceDate
            
            XCTAssertGreaterThan(end - start, 8.0)
        }
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
    DispatchQueue.main.async {
        completion {
            value + 1
        }
    }
}


private func asyncTime(_ value: (), completion: @escaping (() throws -> TimeInterval) -> ()) {
    DispatchQueue.main.async {
        completion {
            Date.timeIntervalSinceReferenceDate
        }
    }
}
