import Foundation

extension NSRegularExpression {
    internal func matches(in string: String) -> [NSTextCheckingResult] {
        return matches(in: string, options: [], range: NSMakeRange(0, (string as NSString).length))
    }
}
