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
        let colorDesc = TextureDescriptor(width: width, height: height, pixelFormat: .bgra8Unorm, usage: [.renderTarget, .shaderRead, .cpuRead])
        let colorTexture = device.makeTexture(descriptor: colorDesc)
        
        // Create Depth Texture
        let depthDesc = TextureDescriptor(width: width, height: height, pixelFormat: .depth32Float, usage: [.renderTarget])
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
        
        // Synchronize for CPU Read
        commandBuffer.synchronize(colorTexture)
        
        // Commit
        commandBuffer.commit()
        
        // Wait for completion
        commandBuffer.waitUntilCompleted()
        
        // Read Pixels
        printPixelData(texture: colorTexture)
        saveTextureToPNG(texture: colorTexture, url: outputURL.deletingPathExtension().appendingPathExtension("png"))
    }
    
    private func printPixelData(texture: Texture) {
        let bytesPerPixel = 4
        let rowBytes = width * bytesPerPixel
        var buffer = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        texture.getBytes(&buffer, bytesPerRow: rowBytes)
        
        // Check center pixel
        let cx = width / 2
        let cy = height / 2
        let offset = (cy * width + cx) * bytesPerPixel
        let b = buffer[offset]
        let g = buffer[offset+1]
        let r = buffer[offset+2]
        let a = buffer[offset+3]
        print("Center Pixel (BGRA): \(b), \(g), \(r), \(a)")
        
        // Check corner pixel (0,0)
        let b0 = buffer[0]
        let g0 = buffer[1]
        let r0 = buffer[2]
        let a0 = buffer[3]
        print("Corner Pixel (BGRA): \(b0), \(g0), \(r0), \(a0)")
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
