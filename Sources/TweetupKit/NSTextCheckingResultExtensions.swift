import Foundation

extension NSTextCheckingResult {
    internal func validRangeAt(_ index: Int) -> NSRange? {
        let range = self.range(at: index)
        guard range.location != NSNotFound else {
            return nil
        }
        return range
    }
}
