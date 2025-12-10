import Foundation
import RenderCore
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public class TextureLoader {
    private let device: RenderDevice
    
    public init(device: RenderDevice) {
        self.device = device
    }
    
    public func loadTexture(name: String, bundle: Bundle = .main) throws -> Texture {
        #if os(iOS)
        guard let image = UIImage(named: name, in: bundle, compatibleWith: nil)?.cgImage else {
            throw NSError(domain: "TextureLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image: \(name)"])
        }
        #elseif os(macOS)
        guard let image = NSImage(named: name)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "TextureLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image: \(name)"])
        }
        #endif
        return try createTexture(from: image)
    }
    
    public func createCheckerboardTexture(size: Int = 256, segments: Int = 8) throws -> Texture {
        let width = size
        let height = size
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = Data(count: height * bytesPerRow)
        
        data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            let buffer = ptr.bindMemory(to: UInt8.self)
            let segmentSize = size / segments
            
            for y in 0..<height {
                for x in 0..<width {
                    let isWhite = ((x / segmentSize) + (y / segmentSize)) % 2 == 0
                    let offset = y * bytesPerRow + x * bytesPerPixel
                    let value: UInt8 = isWhite ? 255 : 0
                    
                    // BGRA
                    buffer[offset] = value     // B
                    buffer[offset + 1] = value // G
                    buffer[offset + 2] = value // R
                    buffer[offset + 3] = 255   // A
                }
            }
        }
        
        let descriptor = TextureDescriptor(width: width, height: height, pixelFormat: .bgra8Unorm, usage: [.shaderRead, .cpuWrite])
        let texture = device.makeTexture(descriptor: descriptor)
        try texture.upload(data: data, bytesPerRow: bytesPerRow)
        
        return texture
    }
    
    public func createProceduralSkybox(size: Int = 512) throws -> Texture {
        let descriptor = TextureDescriptor(width: size, height: size, pixelFormat: .bgra8Unorm, usage: [.shaderRead, .cpuWrite], textureType: .typeCube)
        let texture = device.makeTexture(descriptor: descriptor)
        
        let bytesPerPixel = 4
        let bytesPerRow = size * bytesPerPixel
        
        // Generate 6 faces
        for slice in 0..<6 {
            var data = Data(count: size * size * bytesPerPixel)
            data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
                let buffer = ptr.bindMemory(to: UInt8.self)
                for i in 0..<(size * size) {
                    let offset = i * bytesPerPixel
                    
                    // Simple star field
                    let isStar = Int.random(in: 0...1000) > 998
                    let starIntensity = isStar ? UInt8.random(in: 200...255) : 0
                    
                    // Dark blue background
                    let r: UInt8 = starIntensity
                    let g: UInt8 = starIntensity
                    let b: UInt8 = starIntensity > 0 ? starIntensity : 20 
                    
                    buffer[offset] = b     // B
                    buffer[offset + 1] = g // G
                    buffer[offset + 2] = r // R
                    buffer[offset + 3] = 255 // A
                }
            }
            try texture.upload(data: data, bytesPerRow: bytesPerRow, slice: slice)
        }
        
        return texture
    }
    
    private func createTexture(from cgImage: CGImage) throws -> Texture {
        let width = cgImage.width
        let height = cgImage.height
        
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = Data(count: height * bytesPerRow)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Use BGRA for Metal compatibility
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            throw NSError(domain: "TextureLoader", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGContext"])
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        if let rawData = context.data {
            data = Data(bytes: rawData, count: height * bytesPerRow)
        }
        
        let descriptor = TextureDescriptor(width: width, height: height, pixelFormat: .bgra8Unorm, usage: [.shaderRead, .cpuWrite])
        let texture = device.makeTexture(descriptor: descriptor)
        try texture.upload(data: data, bytesPerRow: bytesPerRow)
        
        return texture
    }
}
