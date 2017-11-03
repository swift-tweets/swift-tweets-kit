import Foundation

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
    
    public func talk(title: String, tweets: [Tweet], interval: TimeInterval?, callback: @escaping (() throws -> URL) -> ()) {
        post(tweets: tweets, with: interval) { getIds in
            do {
                let ids = try getIds()
                assert(ids.count == tweets.count)
                fatalError("Unimplemented.")
//                for (idAndScreenName, tweet) in zip(ids, tweets) {
//                    let (id, screenName) = idAndScreenName
//                    // TODO
//                    fatalError("Unimplemented.")
//                }
            } catch let error {
                callback {
                    throw error
                }
            }
        }
    }
    
    public func post(tweets: [Tweet], with interval: TimeInterval?, callback: @escaping (() throws -> ([(String, String)])) -> ()) {
        repeated(operation: post, interval: interval)(tweets, callback)
    }
    
    public func post(tweet: Tweet, callback: @escaping (() throws -> (String, String)) -> ()) {
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
                Twitter.update(status: status, mediaId: mediaId, credential: twitterCredential).get { getId in
                    callback {
                        try getId()
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
            let imagePath = Speaker.imagePath(path, from: baseDirectoryPath)
            Twitter.upload(media: try Data(contentsOf: URL(fileURLWithPath: imagePath)), credential: twitterCredential).get { getId in
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
    
    internal static func imagePath(_ path: String, from: String?) -> String {
        if let from = from, !path.hasPrefix("/") {
            return from.appendingPathComponent(path)
        } else {
            return path
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
        
        Gist.createGist(description: tweet.body, code: code, accessToken: githubToken).get { getId in
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
        guard case let .some(.image(image)) = tweet.attachment, case let .gist(id) = image.source else {
            callback {
                tweet
            }
            return
        }
        guard let outputDirectoryPath = outputDirectoryPath else {
            callback {
                throw SpeakerError.noOutputDirectoryPath
            }
            return
        }
        
        let url = "https://gist.github.com/\(id)"
        let imagePath = outputDirectoryPath.appendingPathComponent("\(id).png")
        let codeRenderer = CodeRenderer(url: url)
        codeRenderer.writeImage(to: Speaker.imagePath(imagePath, from: self.baseDirectoryPath)) { getVoid in
            callback {
                try getVoid()
                return try Tweet(body: "\(tweet.body)", attachment: .image(Image(alternativeText: image.alternativeText, source: .local(imagePath))))
            }
        }
    }
}

public enum SpeakerError: Error {
    case noTwitterCredential
    case noGithubToken
    case noOutputDirectoryPath
}
