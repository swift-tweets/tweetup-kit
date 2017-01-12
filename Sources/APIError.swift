import Foundation

public struct APIError: Error {
    public let response: HTTPURLResponse
    public let json: Any
    
    public init(response: HTTPURLResponse, json: Any) {
        self.response = response
        self.json = json
    }
}
