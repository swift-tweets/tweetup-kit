import Foundation

extension NSTextCheckingResult {
    internal func validRangeAt(_ index: Int) -> NSRange? {
        let range = rangeAt(index)
        guard range.location != NSNotFound else {
            return nil
        }
        return range
    }
}
