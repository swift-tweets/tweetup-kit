import Foundation

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

extension OAuthCredential: Equatable {
    public static func ==(lhs: OAuthCredential, rhs: OAuthCredential) -> Bool {
        return lhs.consumerKey == rhs.consumerKey
            && lhs.consumerSecret == rhs.consumerSecret
            && lhs.oauthToken == rhs.oauthToken
            && lhs.oauthTokenSecret == rhs.oauthTokenSecret
    }
}
