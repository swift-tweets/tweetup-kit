import OAuthSwift
import Foundation
import PromiseK

internal struct Twitter {
    static func update(status: String, mediaId: String? = nil, credential: OAuthCredential) -> Promise<() throws -> (String, String)> {
        let client = OAuthSwiftClient(credential: credential)
        client.sessionFactory.queue = { .current }
        
        var parameters = [
            "status": status
        ]
        if let mediaId = mediaId {
            parameters["media_ids"] = mediaId
        }

        return Promise<() throws -> (String, String)> { (fulfill: @escaping (@escaping () throws -> (String, String)) -> ()) in
            _ = client.post(
                "https://api.twitter.com/1.1/statuses/update.json",
                parameters: parameters,
                callback: { value in fulfill(value) }
            ) { response in
                let json = try! JSONSerialization.jsonObject(with: response.data) as! [String: Any] // `!` never fails
                return (json["id_str"] as! String, (json["user"] as! [String: Any])["screen_name"] as! String) // `!` never fails
            }
        }
    }
    
    static func upload(media: Data, credential: OAuthCredential) -> Promise<() throws -> String> {
        let client = OAuthSwiftClient(credential: credential)
        client.sessionFactory.queue = { .current }

        return Promise<() throws -> String> { (fulfill: @escaping (@escaping () throws -> String) -> ()) in
            _ = client.post(
                "https://upload.twitter.com/1.1/media/upload.json",
                parameters: [
                    "media_data": media.base64EncodedString()
                ],
                callback: fulfill
            ) { response in
                let json = try! JSONSerialization.jsonObject(with: response.data, options: []) as! [String: Any]
                return json["media_id_string"] as! String // `!` never fails
            }
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
    
    fileprivate func post<T>(_ url: String, parameters: OAuthSwift.Parameters, callback: @escaping (@escaping () throws -> T) -> (), completion: @escaping (OAuthSwiftResponse) throws -> (T)) -> OAuthSwiftRequestHandle? {
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
