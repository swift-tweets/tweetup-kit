import Foundation

extension String {
    internal var lines: [String] {
        var lines: [String] = []
        self.enumerateLines() { line, _ in
            lines.append(line)
        }
        return lines
    }
    
    internal var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
    
    internal func appendingPathComponent(_ pathComponent: String) -> String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
}
