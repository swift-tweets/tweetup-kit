import Foundation

extension Tweet {
    internal static let imagePattern = try! NSRegularExpression(pattern: "!\\[([^\\]]*)\\]\\(((twitter:([0-9]+))|(gist:([0-9a-f]+))|([^\\)]*))\\)")
    internal static let codePattern = try! NSRegularExpression(pattern: "```([a-z]*)(:(.*))?\\n((.*\\n)*)```")
    private static let hashTagPatternString = "#\\w+"
    internal static let hashTagPattern = try! NSRegularExpression(pattern: "^\(hashTagPatternString)$")
    internal static let hashTagInTweetPattern = try! NSRegularExpression(pattern: "(^|\\s)(\(hashTagPatternString))($|\\s)")
    
    public static func tweets(from string: String, hashTag: String? = nil) throws -> [Tweet] {
        return try string.lines
            .separated(by: "---")
            .map { lines in lines.trimmingElements(in: [""]).joined(separator: "\n") }
            .map { try Tweet(rawString: $0, hashTag: hashTag) }
    }
    
    public init(rawString: String, hashTag: String? = nil) throws {
        let attachment = try Tweet.matchedAttachment(in: rawString)
        let originalBody = attachment.map { attachment -> String in
            (rawString as NSString).replacingCharacters(in: attachment.0, with: "")
        }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? rawString
        let body = try Tweet.bodyWithHashTag(body: originalBody, hashTag: hashTag)
        try self.init(body: body, attachment: attachment?.1)
    }
    
    internal static func bodyWithHashTag(body: String, hashTag: String?) throws -> String {
        guard let hashTag = hashTag else { return body }
        guard Tweet.hashTagPattern.matches(in: hashTag).count == 1 else {
            throw TweetParseError.illegalHashTag(hashTag)
        }
        guard !Tweet.containsHashTag(body: body, hashTag: hashTag) else {
            return body
        }
        return body + " " + hashTag
    }
    
    internal static func containsHashTag(body: String, hashTag: String) -> Bool {
        return Tweet.hashTagInTweetPattern.matches(in: body).map {
            (body as NSString).substring(with: $0.rangeAt(2))
        }.contains(hashTag)
    }
    
    internal static func matchedAttachment(in string: String) throws -> (NSRange, Attachment)? {
        let codeMatchingResults = try matchingAttachments(in: string, pattern: codePattern, initializer: Code.init)
        let imageMatchingResults = try matchingAttachments(in: string, pattern: imagePattern, initializer: Image.init)
        let attachments: [(NSRange, Attachment)] = codeMatchingResults.map { ($0.0, .code($0.1)) }
            + imageMatchingResults.map { ($0.0, .image($0.1)) }
        guard attachments.count <= 1 else {
            throw TweetParseError.multipleAttachments(string, attachments.map { $0.1 })
        }
        let attachment = attachments.first
        if let attachment = attachment {
            guard attachment.0.location + attachment.0.length == (string as NSString).length else {
                throw TweetParseError.nonTailAttachment(string, attachment.1)
            }
        }
        return attachment
    }
    
    internal static func matchingAttachments<T>(in string: String, pattern: NSRegularExpression ,initializer: (String, NSTextCheckingResult) throws -> T) throws -> [(NSRange, T)] {
        return try pattern.matches(in: string).map { ($0.rangeAt(0), try initializer(string, $0)) }
    }
}

extension Code {
    fileprivate init(string: String, matchingResult: NSTextCheckingResult) throws {
        let nsString = string as NSString
        let language = Language(identifier: nsString.substring(with: matchingResult.rangeAt(1)))
        let fileName: String
        do {
            let range = matchingResult.rangeAt(3)
            if (range.location == NSNotFound) {
                guard let filenameExtension = language.filenameExtension else {
                    throw TweetParseError.codeWithoutFileName(string)
                }
                fileName = "code.\(filenameExtension)"
            } else {
                fileName = nsString.substring(with: range)
            }
        }
        self.init(
            language: language,
            fileName: fileName,
            body: nsString.substring(with: matchingResult.rangeAt(4))
        )
    }
}

extension Image {
    fileprivate init(string: String, matchingResult: NSTextCheckingResult) {
        let string = string as NSString
        self.init(
            alternativeText: string.substring(with: matchingResult.rangeAt(1)),
            path: string.substring(with: matchingResult.rangeAt(2))
        )
    }
}

public enum TweetParseError: Error {
    case multipleAttachments(String, [Tweet.Attachment])
    case nonTailAttachment(String, Tweet.Attachment)
    case codeWithoutFileName(String)
    case illegalHashTag(String)
}
