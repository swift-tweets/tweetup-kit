import Foundation

public struct NetworkError: Error {
    public let response: HTTPURLResponse
    public let message: String?
    
    public init(response: HTTPURLResponse, message: String? = nil) {
        self.response = response
        self.message = message
    }
}
