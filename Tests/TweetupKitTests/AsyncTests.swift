import XCTest
@testable import TweetupKit

import Foundation
import PromiseK

class AsyncTests: XCTestCase {
    func testRepeated() {
        do {
            let expectation = self.expectation(description: "")
            
            let start = Date.timeIntervalSinceReferenceDate
            
            repeated(operation: asyncIncrement, interval: 2.0)(Array(1...5)).get { getValues in
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
            
            repeated(operation: asyncTime, interval: 2.0)([(), (), (), (), ()]).get { getValues in
                defer {
                    expectation.fulfill()
                }
                
                do {
                    let values = try getValues()
                    XCTAssertEqual(values.count, 5)
                    let allowableError: TimeInterval = 0.1
                    print(values[0] - start)
                    XCTAssertLessThan(abs(values[0] - start), allowableError)
                    print(values[1] - (values[0] + 2.0))
                    XCTAssertLessThan(abs(values[1] - (values[0] + 2.0)), allowableError)
                    print(values[2] - (values[1] + 2.0))
                    XCTAssertLessThan(abs(values[2] - (values[1] + 2.0)), allowableError)
                    print(values[3] - (values[2] + 2.0))
                    XCTAssertLessThan(abs(values[3] - (values[2] + 2.0)), allowableError)
                    print(values[4] - (values[3] + 2.0))
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
    
    func testWait() {
        let expectation = self.expectation(description: "")
        
        let start = Date.timeIntervalSinceReferenceDate
        
        let promise = TweetupKit.wait(asyncIncrement(value: 42), for: 2.0)
        promise.get { getValue in
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

private func asyncIncrement(value: Int) -> Promise<() throws -> Int> {
    return Promise { fulfill in
        DispatchQueue.main.async {
            fulfill { value + 1 }
        }
    }
}

private func asyncTime(_ value: ()) -> Promise<() throws -> TimeInterval> {
    return Promise { fulfill in
        DispatchQueue.main.async {
            fulfill { Date.timeIntervalSinceReferenceDate }
        }
    }
}
