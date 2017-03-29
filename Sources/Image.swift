public struct Image {
    public var alternativeText: String
    public var source: Source

    public enum Source {
        case local(String)
        case twitter(String)
        case gist(String)
    }
}

extension Image: CustomStringConvertible {
    public var description: String {
        return "![\(alternativeText)](\(source))"
    }
}

extension Image: Equatable {
    public static func ==(lhs: Image, rhs: Image) -> Bool {
        return lhs.alternativeText == rhs.alternativeText && lhs.source == rhs.source
    }
}

extension Image.Source: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .local(path):
            return path
        case let .twitter(id):
            return "twitter:\(id)"
        case let .gist(id):
            return "gist:\(id)"
        }
    }
}

extension Image.Source: Equatable {
    public static func ==(lhs: Image.Source, rhs: Image.Source) -> Bool {
        switch (lhs, rhs) {
        case let (.local(path1), .local(path2)):
            return path1 == path2
        case let (.twitter(id1), .twitter(id2)):
            return id1 == id2
        case let (.gist(id1), .gist(id2)):
            return id1 == id2
        case (_, _):
            return false
        }
    }
}
