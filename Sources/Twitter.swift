import OAuthSwift
import Foundation

internal struct Twitter {
    static func update(status: String, mediaId: String? = nil, credential: OAuthCredential, callback: @escaping (() throws -> (String, String)) -> ()) {
        let client = OAuthSwiftClient(credential: credential)
        client.sessionFactory.queue = { .current }
        
        var parameters = [
            "status": status
        ]
        if let mediaId = mediaId {
            parameters["media_ids"] = mediaId
        }
        
        _ = client.post(
            "https://api.twitter.com/1.1/statuses/update.json",
            parameters: parameters,
            callback: callback
        ) { response in
            let json = try! JSONSerialization.jsonObject(with: response.data) as! [String: Any] // `!` never fails
            return (json["id_str"] as! String, (json["user"] as! [String: Any])["screen_name"] as! String) // `!` never fails
        }
    }
    
    static func upload(media: Data, credential: OAuthCredential, callback: @escaping (() throws -> String) -> ()) {
        let client = OAuthSwiftClient(credential: credential)
        client.sessionFactory.queue = { .current }

        _ = client.post(
            "https://upload.twitter.com/1.1/media/upload.json",
            parameters: [
                "media_data": media.base64EncodedString()
            ],
            callback: callback
        ) { response in
            let json = try! JSONSerialization.jsonObject(with: response.data, options: []) as! [String: Any]
            return json["media_id_string"] as! String // `!` never fails
        }
    }
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
    
    fileprivate func post<T>(_ url: String, parameters: OAuthSwift.Parameters, callback: @escaping (() throws -> T) -> (), completion: @escaping (OAuthSwiftResponse) throws -> (T)) -> OAuthSwiftRequestHandle? {
        return post(
            url,
            parameters: parameters,
            success: { response in
                guard response.response.statusCode == 200 else {
                    let httpResponse = response.response
                    callback {
                        let json = try! JSONSerialization.jsonObject(with: response.data, options: []) // `!` never fails
                        throw APIError(response: httpResponse, json: json)
                    }
                    return
                }
                
                callback {
                    try completion(response)
                }
            },
            failure: { error in
                callback {
                    throw error
                }
            }
        )

    }
}
