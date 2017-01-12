import Foundation

internal struct OAuth {
    internal static let executionContext: (@escaping () -> Void) -> Void = { block in
        print("in executionContext before")
        defer {
            print("in executionContext after")
        }
        return Async.executionQueue.async(execute: block)
    }
}

public struct OAuthCredential {
    public let consumerKey: String
    public let consumerSecret: String
    public let oauthToken: String
    public let oauthTokenSecret: String
    
    public init(consumerKey: String, consumerSecret: String, oauthToken: String, oauthTokenSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.oauthToken = oauthToken
        self.oauthTokenSecret = oauthTokenSecret
    }
}
