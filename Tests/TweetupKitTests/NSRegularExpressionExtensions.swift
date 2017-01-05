import Foundation

extension NSRegularExpression {
    func matches(in string: String) -> [NSTextCheckingResult] {
        return matches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
    }
}
