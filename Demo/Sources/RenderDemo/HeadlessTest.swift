import Foundation
import RenderEngine
import RenderCore
import RenderMath
import AppKit

// Headless Renderer for Debugging
class HeadlessRenderer {
    let engine: GraphicEngine
    let width: Int
    let height: Int
    
    init(width: Int, height: Int) throws {
        self.engine = try GraphicEngine(backendType: .metal)
        self.width = width
        self.height = height
    }
    
    func captureFrame(renderer: RenderEngineDelegate, outputURL: URL) {
        let device = engine.device
        
        // Create Color Texture
        let colorDesc = TextureDescriptor(width: width, height: height, pixelFormat: 80, usage: 0) // .bgra8Unorm
        let colorTexture = device.makeTexture(descriptor: colorDesc)
        
        // Create Depth Texture
        let depthDesc = TextureDescriptor(width: width, height: height, pixelFormat: 252, usage: 0) // .depth32Float
        let depthTexture = device.makeTexture(descriptor: depthDesc)
        
        // Create RenderPassDescriptor
        let passDescriptor = RenderPassDescriptor(
            colorTargets: [RenderTargetDescriptor(texture: colorTexture, clearColor: Vec4(0.2, 0.2, 0.2, 1))],
            depthTarget: RenderTargetDescriptor(texture: depthTexture, clearDepth: 1.0)
        )
        
        // Create CommandBuffer
        let commandQueue = device.makeCommandQueue()
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // Draw
        renderer.update(deltaTime: 0.016)
        renderer.draw(in: engine, commandBuffer: commandBuffer, renderPassDescriptor: passDescriptor)
        
        // Commit
        commandBuffer.commit()
        
        // Wait for completion
        commandBuffer.waitUntilCompleted()
        
        // Read Pixels
        saveTextureToPNG(texture: colorTexture, url: outputURL.deletingPathExtension().appendingPathExtension("png"))
    }
    
    private func saveTextureToPNG(texture: Texture, url: URL) {
        let bytesPerPixel = 4
        let rowBytes = width * bytesPerPixel
        let imageBytes = rowBytes * height
        
        var buffer = [UInt8](repeating: 0, count: imageBytes)
        texture.getBytes(&buffer, bytesPerRow: rowBytes)
        
        // Create CGImage from buffer
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        guard let provider = CGDataProvider(data: Data(buffer) as CFData),
              let cgImage = CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bitsPerPixel: 32,
                                    bytesPerRow: rowBytes,
                                    space: colorSpace,
                                    bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent) else {
            print("Failed to create CGImage")
            return
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("Failed to create PNG data")
            return
        }
        
        do {
            try pngData.write(to: url)
            print("Saved frame to \(url.path)")
        } catch {
            print("Failed to save PNG: \(error)")
        }
    }
}

// Main execution for headless test
func runHeadlessTest() {
    do {
        let headless = try HeadlessRenderer(width: 800, height: 600)
        let renderer = CubeRenderer()
        
        // Rotate cube to see faces
        renderer.rotationAngle = 0.5
        
        let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("debug_frame.ppm")
        headless.captureFrame(renderer: renderer, outputURL: outputURL)
        
    } catch {
        print("Headless test failed: \(error)")
    }
}
