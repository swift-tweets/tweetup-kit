public struct Code {
    public var language: Language
    public var fileName: String
    public var body: String
}

extension Code: CustomStringConvertible {
    public var description: String {
        return "```\(language.identifier):\(fileName)\n\(body)\n```"
    }
}

extension Code: Equatable {
    public static func ==(lhs: Code, rhs: Code) -> Bool {
        return lhs.language == rhs.language && lhs.fileName == rhs.fileName && lhs.body == rhs.body
    }
}
