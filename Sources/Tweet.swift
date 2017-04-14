import Foundation

public struct Tweet {
    internal static let urlPattern = try! NSRegularExpression(pattern: "(^|\\s)((http(s)?://)?[a-zA-Z0-9\\-]+(\\.[a-zA-Z0-9\\-]+)+(/[a-zA-Z0-9~!@#$%&*\\-_=+\\[\\]|:;',./?]*)?)($|\\s)")
    internal static let urlLength = 23
    internal static let maxLength = 140
    
    public let body: String
    public let attachment: Attachment?
    
    public init(body: String, attachment: Attachment? = nil) throws {
        guard !body.isEmpty || attachment != nil else { throw TweetInitializationError.empty }
        self.body = body
        self.attachment = attachment
        
        let length = self.length
        guard length <= Tweet.maxLength else { throw TweetInitializationError.tooLong(self.body, self.attachment, length) }
    }
    
    public var length: Int {
        let replaced = NSMutableString(string: body)
        let numberOfUrls = Tweet.urlPattern.replaceMatches(in: replaced, options: [], range: NSMakeRange(0, replaced.length), withTemplate: "$1$7")
        
        let normalized = replaced.precomposedStringWithCanonicalMapping as NSString
        
        var bodyLength = normalized.length + Tweet.urlLength * numberOfUrls
        do {
            let buffer = UnsafeMutablePointer<unichar>.allocate(capacity: normalized.length)
            defer {
                buffer.deallocate(capacity: normalized.length)
            }
            normalized.getCharacters(buffer)
            var skip = false
            let end = normalized.length - 1
            if end > 1 {
                for i in 0..<end { // lack of the last element for `i + 1`
                    guard !skip else {
                        skip = false
                        continue
                    }
                    if CFStringIsSurrogateHighCharacter(buffer[i])
                        && CFStringIsSurrogateLowCharacter(buffer[i + 1]) {
                        bodyLength -= 1
                        skip = true
                    }
                }
            }
        }
        
        guard let attachment = attachment else { return bodyLength }

        switch attachment {
        case .code:
            return bodyLength + 2 /* new lines */ + Tweet.urlLength
        case .image:
            return bodyLength
        }
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

extension Tweet: Equatable {
    public static func ==(lhs: Tweet, rhs: Tweet) -> Bool {
        return lhs.body == rhs.body && lhs.attachment == rhs.attachment
    }
}

extension Tweet.Attachment: Equatable {
    public static func ==(lhs: Tweet.Attachment, rhs: Tweet.Attachment) -> Bool {
        switch (lhs, rhs) {
        case let (.image(image1), .image(image2)):
            return image1 == image2
        case let (.code(code1), .code(code2)):
            return code1 == code2
        case (_, _):
            return false
        }
    }
}

public enum TweetInitializationError: Error {
    case empty
    case tooLong(String, Tweet.Attachment?, Int)
}
