import Foundation
import PromiseK

public struct Speaker {
    public let twitterCredential: OAuthCredential?
    public let githubToken: String?
    public let qiitaToken: String?
    public var baseDirectoryPath: String?
    public var outputDirectoryPath: String?

    public init(twitterCredential: OAuthCredential? = nil, githubToken: String? = nil, qiitaToken: String? = nil, baseDirectoryPath: String? = nil, outputDirectoryPath: String? = nil) {
        self.twitterCredential = twitterCredential
        self.githubToken = githubToken
        self.qiitaToken = qiitaToken
        self.baseDirectoryPath = baseDirectoryPath
        self.outputDirectoryPath = outputDirectoryPath
    }
    
    public func talk(title: String, tweets: [Tweet], interval: TimeInterval?) -> Promise<() throws -> URL> {
        return post(tweets: tweets, with: interval).map { getIds in
            let ids = try getIds()
            assert(ids.count == tweets.count)
            fatalError("Unimplemented.")
//            for (idAndScreenName, tweet) in zip(ids, tweets) {
//                let (id, screenName) = idAndScreenName
//                // TODO
//                fatalError("Unimplemented.")
//            }
        }
    }
    
    public func post(tweets: [Tweet], with interval: TimeInterval?) -> Promise<() throws -> [(String, String)]> {
        return repeated(operation: post, interval: interval)(tweets)
    }
    
    public func post(tweet: Tweet) -> Promise<() throws -> (String, String)> {
        guard let twitterCredential = twitterCredential else {
            return Promise { throw SpeakerError.noTwitterCredential }
        }
  
        return resolveCode(of: tweet)
            .flatMap { self.resolveGist(of: try $0()) }
            .flatMap { self.resolveImage(of: try $0()) }
            .flatMap { (getTweet: () throws -> Tweet) in
                let tweet: Tweet = try getTweet()
                let status = tweet.body
                let mediaId: String?
                if let attachment = tweet.attachment {
                    switch attachment {
                    case let .image(image):
                        switch image.source {
                        case let .twitter(id):
                            mediaId = id
                        case .gist(_):
                            // TODO
                            mediaId = nil
                        case _:
                            fatalError("Never reaches here.")
                        }
                    case _:
                        fatalError("Never reaches here.")
                    }
                } else {
                    mediaId = nil
                }
                return Twitter.update(status: status, mediaId: mediaId, credential: twitterCredential)
            }.map { getId in
                try getId()
            }
    }
    
    public func resolveImages(of tweets: [Tweet]) -> Promise<() throws -> [Tweet]> {
        return repeated(operation: resolveImage)(tweets)
    }
    
    public func resolveImage(of tweet: Tweet) -> Promise<() throws -> Tweet> {
        guard case let .some(.image(image)) = tweet.attachment, case let .local(path) = image.source else {
            return Promise { tweet }
        }
        guard let twitterCredential = twitterCredential else {
            return Promise { throw SpeakerError.noTwitterCredential }
        }
        
        do {
            let imagePath = Speaker.imagePath(path, from: baseDirectoryPath)
            return Twitter.upload(media: try Data(contentsOf: URL(fileURLWithPath: imagePath)), credential: twitterCredential).map { getId in
                let id = try getId()
                return try Tweet(body: "\(tweet.body)", attachment: .image(Image(alternativeText: image.alternativeText, source: .twitter(id))))
            }
        } catch let error {
            return Promise { throw error }
        }
    }
    
    internal static func imagePath(_ path: String, from: String?) -> String {
        if let from = from, !path.hasPrefix("/") {
            return from.appendingPathComponent(path)
        } else {
            return path
        }
    }
    
    public func resolveCodes(of tweets: [Tweet]) -> Promise<() throws -> [Tweet]> {
        return repeated(operation: resolveCode)(tweets)
    }
    
    public func resolveCode(of tweet: Tweet) -> Promise<() throws -> Tweet> {
        guard case let .some(.code(code)) = tweet.attachment else {
            return Promise { tweet }
        }
        guard let githubToken = githubToken else {
            return Promise { throw SpeakerError.noGithubToken }
        }
        
        return Gist.createGist(description: tweet.body, code: code, accessToken: githubToken).map { getId in
            let id = try getId()
            return try Tweet(body: "\(tweet.body)\n\nhttps://gist.github.com/\(id)", attachment: .image(Image(alternativeText: "", source: .gist(id))))
        }
    }
    
    public func resolveGists(of tweets: [Tweet]) -> Promise<() throws -> [Tweet]> {
        return repeated(operation: resolveGist)(tweets)
    }
    
    public func resolveGist(of tweet: Tweet) -> Promise<() throws -> Tweet> {
        guard case let .some(.image(image)) = tweet.attachment, case let .gist(id) = image.source else {
            return Promise { tweet }
        }
        guard let outputDirectoryPath = outputDirectoryPath else {
            return Promise { throw SpeakerError.noOutputDirectoryPath }
        }
        
        let url = "https://gist.github.com/\(id)"
        let imagePath = outputDirectoryPath.appendingPathComponent("\(id).png")
        let codeRenderer = CodeRenderer(url: url)
        return codeRenderer.writeImage(to: Speaker.imagePath(imagePath, from: self.baseDirectoryPath)).map { getVoid in
            try getVoid()
            return try Tweet(body: "\(tweet.body)", attachment: .image(Image(alternativeText: image.alternativeText, source: .local(imagePath))))
        }
    }
}

public enum SpeakerError: Error {
    case noTwitterCredential
    case noGithubToken
    case noOutputDirectoryPath
}
