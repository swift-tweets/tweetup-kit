public struct Tweet {
    public let message: String
    public let attached: Attached?
    
    public init(message: String, attached: Attached? = nil) throws {
        self.message = message
        self.attached = attached
    }
    
    public enum Attached {
        case image(Image)
        case code(Code)
    }
}
