import WebKit
import Foundation

private let queue = DispatchQueue(label: "TweetupKit.CodeRenderer")

public class CodeRenderer: NSObject {
    private var webView: WebView!
    fileprivate var loading = true
    fileprivate var _image: CGImage!
    fileprivate var error: Error?
    
    fileprivate static let height: CGFloat = 736
    
    public init(url: String) {
        super.init()
        
        webView = WebView(frame: NSRect(x: 0, y: 0, width: 414, height: CodeRenderer.height))
        webView.frameLoadDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"
        webView.mainFrameURL = url
        
        let runLoop = RunLoop.current
        while loading && runLoop.run(mode: .defaultRunLoopMode, before: .distantFuture) { }
    }
    
    public func image() throws -> CGImage {
        if let error = self.error {
            throw error
        }
        
        return _image
    }
    
    public func writeImage(to path: String) throws {
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
    public func webView(_ sender: WebView, didFinishLoadFor frame: WebFrame) {
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
        
        let image = imageRep.cgImage!
        let scale = CGFloat(image.width) / pageBox.size.width
        
        let x = codeBox.origin.x * scale
        let y = codeBox.origin.y * scale
        let width = Int(codeBox.size.width * scale)
        let height = Int(codeBox.size.height * scale)
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        let targetRect = CGRect(x: -x, y: y - CGFloat(image.height - height), width: CGFloat(image.width), height: CGFloat(image.height))
        context.draw(imageRep.cgImage!, in: targetRect)
        
        let provider: CGDataProvider = CGDataProvider(data: Data(bytes: pixels) as CFData)!
        _image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        loading = false
    }
    
    public func webView(_ sender: WebView, didFailLoadWithError error: Error, for frame: WebFrame) {
        self.error = error
        loading = false
    }
}

public enum CodeRendererError: Error {
    case writingFailed
    case illegalResponse
}
