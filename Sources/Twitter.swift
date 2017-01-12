import OAuthSwift
import Foundation

internal struct Twitter {
    static func update(status: String, credential: OAuthCredential, callback: @escaping (() throws -> String) -> ()) {
        OAuthSwiftHTTPRequest.executionContext = OAuth.executionContext
        
        let client = OAuthSwiftClient(credential: credential)
        client.sessionFactory.queue = Async.sessionQueue
        
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
    
    static func upload(media: Data, credential: OAuthCredential, callback: @escaping (() throws -> String) -> ()) {
        OAuthSwiftHTTPRequest.executionContext = OAuth.executionContext
        
        let client = OAuthSwiftClient(credential: credential)
        client.sessionFactory.queue = Async.sessionQueue

        _ = client.post(
            "https://upload.twitter.com/1.1/media/upload.json",
            parameters: [
                "media_data": media.base64EncodedString()
            ], success: { response in
                callback {
                    let json = try! JSONSerialization.jsonObject(with: response.data, options: []) as! [String: Any]
                    return json["media_id_string"] as! String // `!` never fails
                }
            }, failure: { error in
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

extension OAuthSwiftClient {
    fileprivate convenience init(credential: OAuthCredential) {
        self.init(
            consumerKey: credential.consumerKey,
            consumerSecret: credential.consumerSecret,
            oauthToken: credential.oauthToken,
            oauthTokenSecret: credential.oauthTokenSecret,
            version: .oauth1
        )
    }
}
