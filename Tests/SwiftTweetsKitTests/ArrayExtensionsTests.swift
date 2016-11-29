import XCTest
@testable import SwiftTweetsKit

class ArrayExtensionsTests: XCTestCase {
    func testTrimmingElements() {
        do {
            let lines = ["", "", "\t", "\n", "a", "", "", "\n", "b", "c", "", "d", "", "", "\r"]
            let trimmed = lines.trimmingElements(in: ["", "\t", "\n", "\r"])
            XCTAssertEqual(trimmed, ["a", "", "", "\n", "b", "c", "", "d"])
        }
        
        do {
            let lines = ["Twinkle, twinkle, little star,", "How I wonder what you are!", ""]
            let trimmed = lines.trimmingElements(in: [""])
            XCTAssertEqual(trimmed, ["Twinkle, twinkle, little star,", "How I wonder what you are!"])
        }
        
        do {
            let lines = ["", "Up above the world so high,", "Like a diamond in the sky.", "", "```swift:hello.swift", "let name = \"Swift\"", "print(\"Hello \\(name)!\")", "```", ""]
            let trimmed = lines.trimmingElements(in: [""])
            XCTAssertEqual(trimmed, ["Up above the world so high,", "Like a diamond in the sky.", "", "```swift:hello.swift", "let name = \"Swift\"", "print(\"Hello \\(name)!\")", "```"])
        }
    }
}
