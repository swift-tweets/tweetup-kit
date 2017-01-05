import Foundation

public struct Tweet {
    internal static let urlPattern = try! NSRegularExpression(pattern: "(^|\\s)(http(s)?://[a-zA-Z0-9~!@#$%&*-_=+\\[\\]|:;',./?]*)($|\\s)")
    
    public let body: String
    public let attachment: Attachment?
    
    public init(body: String, attachment: Attachment? = nil) throws {
        guard !body.isEmpty || attachment != nil else { throw TweetInitializationError.emptyTweet }
        self.body = body
        self.attachment = attachment
    }
    
    public enum Attachment {
        case image(Image)
        case code(Code)
    }
}

extension Tweet: CustomStringConvertible {
    public var description: String {
        guard let attachment = attachment else { return body }
        
        switch attachment {
        case let .image(image):
            return "\(body)\n\n\(image)"
        case let .code(code):
            return "\(body)\n\n\(code)"
        }
    }
}

public enum TweetInitializationError: Error {
    case emptyTweet
}
