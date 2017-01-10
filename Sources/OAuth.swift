import Foundation

internal struct OAuth {
    internal static let sessionQueue = OperationQueue()
    private static let executionQueue = DispatchQueue(label: "TweetupKit")
    internal static let executionContext: (@escaping () -> Void) -> Void = { block in
        print("in executionContext before")
        defer {
            print("in executionContext after")
        }
        return executionQueue.async(execute: block)
    }
}

public struct OAuthCredential {
    public let consumerKey: String
    public let consumerSecret: String
    public let oauthToken: String
    public let oauthTokenSecret: String
}
