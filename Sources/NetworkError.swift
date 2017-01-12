import Foundation

public struct NetworkError: Error {
    public let statusCode: Int
    public let response: HTTPURLResponse
    public let message: String?
    
    public init(statusCode: Int, response: HTTPURLResponse, message: String? = nil) {
        self.statusCode = statusCode
        self.response = response
        self.message = message
    }
}
