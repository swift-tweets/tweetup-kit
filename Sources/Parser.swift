import Foundation

extension Tweet {
    internal static let imagePattern = try! NSRegularExpression(pattern: "!\\[([^\\]]*)\\]\\(([^\\)]*)\\)")
    internal static let codePattern = try! NSRegularExpression(pattern: "```([a-z]*)(:(.*))?\\n((.*\\n)*)```")
    
    public static func tweets(with string: String) throws -> [Tweet] {
        return try string.lines
            .separated(by: "---")
            .map { lines in lines.trimmingElements(in: [""]).joined(separator: "\n") }
            .map(Tweet.init)
    }
    
    public init(rawString: String) throws {
        let attachment = try Tweet.matchedAttachment(in: rawString)
        let replacedString = attachment.map { attachment -> String in
            (rawString as NSString).replacingCharacters(in: attachment.0, with: "")
        }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? rawString
        try self.init(body: replacedString, attachment: attachment?.1)
    }
    
    internal static func matchedAttachment(in string: String) throws -> (NSRange, Attachment)? {
        let codeMatchingResults = matchingAttachments(in: string, pattern: codePattern, initializer: Code.init)
        let imageMatchingResults = matchingAttachments(in: string, pattern: imagePattern, initializer: Image.init)
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
    
    internal static func matchingAttachments<T>(in string: String, pattern: NSRegularExpression ,initializer: (String, NSTextCheckingResult) -> T) -> [(NSRange, T)] {
        return pattern.matches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
            .map { ($0.rangeAt(0), initializer(string, $0)) }
    }
}

extension Code {
    fileprivate init(string: String, matchingResult: NSTextCheckingResult) {
        let string = string as NSString
        self.init(
            languageName: string.substring(with: matchingResult.rangeAt(1)),
            fileName: string.substring(with: matchingResult.rangeAt(3)),
            body: string.substring(with: matchingResult.rangeAt(4))
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
}
