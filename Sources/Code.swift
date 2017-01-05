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
