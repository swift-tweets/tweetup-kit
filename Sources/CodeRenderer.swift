import WebKit
import Foundation

private let queue = DispatchQueue(label: "TweetupKit.CodeRenderer")

internal class CodeRenderer: NSObject {
    private var webView: WebView!
    fileprivate var loading = true
    fileprivate var _image: CGImage!
    fileprivate var error: Error?
    
    fileprivate static let height: CGFloat = 736
    
    init(url: String) {
        super.init()
        
        webView = WebView(frame: NSRect(x: 0, y: 0, width: 414, height: CodeRenderer.height))
        webView.frameLoadDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"
        webView.mainFrameURL = url
        
        let runLoop = RunLoop.current
        while loading && runLoop.run(mode: .defaultRunLoopMode, before: .distantFuture) { }
    }
    
    func image() throws -> CGImage {
        if let error = self.error {
            throw error
        }
        
        return _image
    }
    
    func writeImage(to path: String) throws {
        let image = try self.image()
        let url = URL(fileURLWithPath: path)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
            throw CodeRendererError.writingFailed
        }
        
        CGImageDestinationAddImage(destination, image, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            throw CodeRendererError.writingFailed
        }
    }
}

extension CodeRenderer: WebFrameLoadDelegate {
    func webView(_ sender: WebView, didFinishLoadFor frame: WebFrame) {
        let document = frame.domDocument!
        let body = document.getElementsByTagName("body").item(0)!
        let bodyBox = body.boundingBox()
        let pageBox = CGRect(origin: bodyBox.origin, size: CGSize(width: bodyBox.width, height: max(bodyBox.size.height, CodeRenderer.height)))
        
        let files = document.getElementsByClassName("blob-file-content")!
        guard files.length > 0 else {
            error = CodeRendererError.illegalResponse
            return
        }
        let code = files.item(0) as! DOMElement
        let codeBox = code.boundingBox()
        
        let view = frame.frameView.documentView!
        let imageRep = view.bitmapImageRepForCachingDisplay(in: CGRect(origin: .zero, size: pageBox.size))!
        
        view.cacheDisplay(in: pageBox, to: imageRep)
        
        let scale: CGFloat = 2.0
        let codeBox2 = codeBox * scale
        let pageBox2 = pageBox * scale
        
        let width = Int(codeBox2.size.width)
        let height = Int(codeBox2.size.height)
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        let targetRect = CGRect(x: -codeBox2.origin.x, y: codeBox2.origin.y - CGFloat(pageBox2.size.height - codeBox2.size.height), width: pageBox2.size.width, height: pageBox2.size.height)
        context.draw(imageRep.cgImage!, in: targetRect)
        
        let provider: CGDataProvider = CGDataProvider(data: Data(bytes: pixels) as CFData)!
        _image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        loading = false
    }
    
    func webView(_ sender: WebView, didFailLoadWithError error: Error, for frame: WebFrame) {
        self.error = error
        loading = false
    }
}

public enum CodeRendererError: Error {
    case writingFailed
    case illegalResponse
}

internal func *(rect: CGRect, k: CGFloat) -> CGRect {
    return CGRect(origin: rect.origin * k, size: rect.size * k)
}

internal func *(point: CGPoint, k: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * k, y: point.y * k)
}

internal func *(size: CGSize, k: CGFloat) -> CGSize {
    return CGSize(width: size.width * k, height: size.height * k)
}
