import Foundation

extension String {
    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
    
    func appendingPathComponent(_ pathComponent: String) -> String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
}
