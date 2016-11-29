public struct Tweet {
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

public enum TweetInitializationError: Error {
    case emptyTweet
}
