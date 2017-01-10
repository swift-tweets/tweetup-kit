import OAuthSwift
import Foundation

internal struct Twitter {
    static func update(status: String, credential: OAuthCredential, callback: @escaping (() throws -> String) -> ()) {
        OAuthSwiftHTTPRequest.executionContext = OAuth.executionContext
        
        let client = OAuthSwiftClient(
            consumerKey: credential.consumerKey,
            consumerSecret: credential.consumerSecret,
            oauthToken: credential.oauthToken,
            oauthTokenSecret: credential.oauthTokenSecret,
            version: .oauth1
        )
        client.sessionFactory.queue = OAuth.sessionQueue
        
        _ = client.post(
            "https://api.twitter.com/1.1/statuses/update.json",
            parameters: [
                "status": status
            ],
            success: { response in
                callback {
                    let json = try! JSONSerialization.jsonObject(with: response.data) as! [String: Any] // `!` never fails
                    return json["id_str"] as! String // `!` never fails
                }
            },
            failure: { error in
                callback {
                    throw TwitterError(message: "\(error)")
                }
            }
        )
    }
}

internal struct TwitterError: Error {
    let message: String
}
