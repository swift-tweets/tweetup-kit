import Foundation

public struct Speaker {
    public let twitterCredential: OAuthCredential?
    public let githubToken: String?
    public let qiitaToken: String?

    public init(twitterCredential: OAuthCredential? = nil, githubToken: String? = nil, qiitaToken: String? = nil) {
        self.twitterCredential = twitterCredential
        self.githubToken = githubToken
        self.qiitaToken = qiitaToken
    }
    
    public func talk(title: String, tweets: [Tweet], callback: @escaping (() throws -> URL) -> ()) {
        post(tweets: tweets) { getIds in
            do {
                let ids = try getIds()
                assert(ids.count == tweets.count)
                for (id, tweet) in zip(ids, tweets) {
                    // TODO
                    fatalError("Unimplemented.")
                }
            } catch let error {
                callback {
                    throw error
                }
            }
        }
    }
    
    public func post(tweets: [Tweet], callback: @escaping (() throws -> ([String])) -> ()) {
        repeated(operation: post)(tweets, callback)
    }
    
    public func post(tweet: Tweet, callback: @escaping (() throws -> String) -> ()) {
        guard let twitterCredential = twitterCredential else {
            callback {
                throw SpeakerError.noTwitterCredential
            }
            return
        }
        
        let resolve = flatten(flatten(resolveCode, resolveGist), resolveImage)
        resolve(tweet) { getTweet in
            do {
                let tweet = try getTweet()
                let status = tweet.body
                if let attachment = tweet.attachment {
                    switch attachment {
                    case let .image(image):
                        switch image.source {
                        case let .twitter(id):
                            // TODO
                            fatalError("Unimplemented.")
                        case _:
                            fatalError("Never reaches here.")
                        }
                    case _:
                        fatalError("Never reaches here.")
                    }
                } else {
                    Twitter.update(status: status, credential: twitterCredential) { getId in
                        callback {
                            try getId()
                        }
                    }
                }
            } catch let error {
                callback { throw error }
            }
        }
    }
    
    public func resolveImages(of tweets: [Tweet], callback: @escaping (() throws -> [Tweet]) -> ()) {
        repeated(operation: resolveImage)(tweets, callback)
    }
    
    public func resolveImage(of tweet: Tweet, callback: @escaping (() throws -> Tweet) -> ()) {
        guard case let .some(.image(image)) = tweet.attachment, case let .local(path) = image.source else {
            callback {
                tweet
            }
            return
        }
        guard let twitterCredential = twitterCredential else {
            callback {
                throw SpeakerError.noTwitterCredential
            }
            return
        }
        
        do {
            Twitter.upload(media: try Data(contentsOf: URL(fileURLWithPath: path)), credential: twitterCredential) { getId in
                callback {
                    let id = try getId()
                    return try Tweet(body: "\(tweet.body)", attachment: .image(Image(alternativeText: image.alternativeText, source: .twitter(id))))
                }
            }
        } catch let error {
            callback {
                throw error
            }
        }
    }
    
    public func resolveCodes(of tweets: [Tweet], callback: @escaping (() throws -> [Tweet]) -> ()) {
        repeated(operation: resolveCode)(tweets, callback)
    }
    
    public func resolveCode(of tweet: Tweet, callback: @escaping (() throws -> Tweet) -> ()) {
        guard case let .some(.code(code)) = tweet.attachment else {
            callback {
                tweet
            }
            return
        }
        guard let githubToken = githubToken else {
            callback {
                throw SpeakerError.noGithubToken
            }
            return
        }
        
        Gist.createGist(description: tweet.body, code: code, accessToken: githubToken) { getId in
            callback {
                let id = try getId()
                return try Tweet(body: "\(tweet.body)\n\nhttps://gist.github.com/\(id)", attachment: .image(Image(alternativeText: "", source: .gist(id))))
            }
        }
    }
    
    public func resolveGists(of tweets: [Tweet], callback: @escaping (() throws -> [Tweet]) -> ()) {
        repeated(operation: resolveGist)(tweets, callback)
    }
    
    public func resolveGist(of tweet: Tweet, callback: @escaping (() throws -> Tweet) -> ()) {
        // TODO
        fatalError("Unimplemented.")
    }
}

public enum SpeakerError: Error {
    case noTwitterCredential
    case noGithubToken
}
