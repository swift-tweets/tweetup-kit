public struct Image {
    public var alternativeText: String
    public var path: String
}

extension Image: CustomStringConvertible {
    public var description: String {
        return "![\(alternativeText)](\(path))"
    }
}

