# TweetupKit

_TweetupKit_ is a Swift library which helps to make a presentation on Twitter. It parses decodes scripts of presentations written in a format similar to Markdown. Decoded tweets are automatically posted with a constant interval.

```swift
let speaker = Speaker(
    twitterCredential: twitterCredential,
    githubToken: githubToken,
    outputDirectoryPath: imageDirectoryPath
)

let tweetsString = """
    Twinkle, twinkle, little star,
    How I wonder what you are!

    ---

    Up above the world so high,
    Like a diamond in the sky.

    ```swift:hello.swift
    let name = "Swift"
    print("Hello \\(name)!")
    ```

    ---

    Twinkle, twinkle, little star,
    How I wonder what you are!

    ![](\(imagePath))
    """

let tweets = try! Tweet.tweets(from: tweetsString)
speaker.post(tweets: tweets, interval: 10.0).get { getResponses in
    let responses = try getResponses()
    for response in responses {
        print("\(response.statusId), \(response.screenName)")
    }
}
```

## Tweets format

    Tweets can be written in a format similar to Markdown like this.
    Each tweet is separated by ---.
    
    ---
    
    Tweets can contain code. TweetupKit creates a Gist of the code,
    and a link to the Gist and a screenshot of the code are posted together.
    
    ```swift:hello.swift
    let name = "Swift"
    print("Hello \(name)!")
    ```
    
    ---
    
    Also images can be attached to tweets.
    
    ![](path/to/image)

## Installation

Swift Package Manager is available.

```swift
.package(
    url: "https://github.com/swift-tweets/tweetup-kit.git",
    from: "0.2.0"
)
```
