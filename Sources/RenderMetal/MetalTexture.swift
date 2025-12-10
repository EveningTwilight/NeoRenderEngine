import Foundation
import Metal
import QuartzCore
import RenderCore

public class MetalTexture: Texture {
    public let mtlTexture: MTLTexture
    public let drawable: CAMetalDrawable? // Keep reference to drawable if this is a swapchain texture
    
    public var width: Int { mtlTexture.width }
    public var height: Int { mtlTexture.height }

    public init(_ texture: MTLTexture, drawable: CAMetalDrawable? = nil) {
        self.mtlTexture = texture
        self.drawable = drawable
    }

    public func upload(data: Data, bytesPerRow: Int) throws {
        try upload(data: data, bytesPerRow: bytesPerRow, slice: 0)
    }

    public func upload(data: Data, bytesPerRow: Int, slice: Int) throws {
        let w = mtlTexture.width
        let h = mtlTexture.height
        let expected = bytesPerRow * h
        guard data.count >= expected else {
            throw NSError(domain: "RenderEngineMetal", code: -1, userInfo: [NSLocalizedDescriptionKey: "Insufficient data length for upload"]) }

        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            guard let base = ptr.baseAddress else { return }
            let region = MTLRegionMake2D(0, 0, w, h)
            mtlTexture.replace(region: region, mipmapLevel: 0, slice: slice, withBytes: base, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerRow * h)
        }
    }
    
    public func getBytes(_ buffer: UnsafeMutableRawPointer, bytesPerRow: Int) {
        let region = MTLRegionMake2D(0, 0, width, height)
        mtlTexture.getBytes(buffer, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
    }
}
