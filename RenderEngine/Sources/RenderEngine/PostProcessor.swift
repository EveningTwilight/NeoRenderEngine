import Foundation
import RenderCore
import RenderMath

public class PostProcessor {
    public let device: RenderDevice
    public var pipelineState: PipelineState?
    public var brightPipeline: PipelineState?
    public var blurPipeline: PipelineState?
    
    private var brightTexture: Texture?
    private var blurTexture: Texture?
    private var dummyBlackTexture: Texture?
    
    public let quadMesh: Mesh
    
    public init(device: RenderDevice) {
        self.device = device
        self.quadMesh = PostProcessor.createFullScreenQuad(device: device)
        
        // Create 1x1 black texture for when bloom is disabled
        let desc = TextureDescriptor(width: 1, height: 1, pixelFormat: .rgba8Unorm, usage: [.shaderRead])
        self.dummyBlackTexture = device.makeTexture(descriptor: desc)
        // Upload black color
        let black: [UInt8] = [0, 0, 0, 255]
        try? self.dummyBlackTexture?.upload(data: Data(black), bytesPerRow: 4)
    }
    
    public func render(texture: Texture, in commandBuffer: CommandBuffer, passDescriptor: RenderPassDescriptor) {
        guard let pipeline = pipelineState else { return }
        
        // 1. Bloom Pass (Optional)
        var bloomTextureToBind = dummyBlackTexture
        
        if let brightPipeline = brightPipeline, let blurPipeline = blurPipeline {
            // Ensure intermediate textures exist
            if brightTexture == nil || brightTexture!.width != texture.width || brightTexture!.height != texture.height {
                // Downsample for bloom? For now same size.
                let desc = TextureDescriptor(width: texture.width, height: texture.height, pixelFormat: .rgba16Float, usage: [.renderTarget, .shaderRead])
                brightTexture = device.makeTexture(descriptor: desc)
                blurTexture = device.makeTexture(descriptor: desc)
            }
            
            // A. Bright Pass
            let brightPassDesc = RenderPassDescriptor(colorTargets: [RenderTargetDescriptor(texture: brightTexture!, clearColor: Vec4(0,0,0,1))])
            let brightEncoder = commandBuffer.beginRenderPass(brightPassDesc)
            brightEncoder.setPipeline(brightPipeline)
            brightEncoder.setFragmentTexture(texture, index: 0)
            drawQuad(encoder: brightEncoder)
            brightEncoder.endEncoding()
            
            // B. Blur Pass
            let blurPassDesc = RenderPassDescriptor(colorTargets: [RenderTargetDescriptor(texture: blurTexture!, clearColor: Vec4(0,0,0,1))])
            let blurEncoder = commandBuffer.beginRenderPass(blurPassDesc)
            blurEncoder.setPipeline(blurPipeline)
            blurEncoder.setFragmentTexture(brightTexture!, index: 0)
            drawQuad(encoder: blurEncoder)
            blurEncoder.endEncoding()
            
            bloomTextureToBind = blurTexture
        }
        
        // 2. Combine & Tone Mapping Pass
        let encoder = commandBuffer.beginRenderPass(passDescriptor)
        encoder.setPipeline(pipeline)
        encoder.setFragmentTexture(texture, index: 0)
        if let bloomTex = bloomTextureToBind {
            encoder.setFragmentTexture(bloomTex, index: 1)
        }
        
        drawQuad(encoder: encoder)
        
        encoder.endEncoding()
    }
    
    private func drawQuad(encoder: RenderPassEncoder) {
        encoder.setVertexBuffer(quadMesh.vertexBuffer, offset: 0, index: 0)
        if let indexBuffer = quadMesh.indexBuffer {
            encoder.drawIndexed(indexCount: quadMesh.indexCount, indexBuffer: indexBuffer, indexOffset: 0, indexType: quadMesh.indexType)
        }
    }
    
    private static func createFullScreenQuad(device: RenderDevice) -> Mesh {
        // Full screen quad in NDC (-1 to 1)
        // Position (3), UV (2)
        let vertices: [Float] = [
            -1,  1, 0,   0, 0, // Top Left (Metal UV 0,0 is Top Left)
            -1, -1, 0,   0, 1, // Bottom Left
             1, -1, 0,   1, 1, // Bottom Right
             1,  1, 0,   1, 0  // Top Right
        ]
        
        let indices: [UInt16] = [
            0, 1, 2,
            2, 3, 0
        ]
        
        var vertexDescriptor = VertexDescriptor()
        vertexDescriptor.attributes.append(VertexAttribute(format: .float3, offset: 0, bufferIndex: 0))
        vertexDescriptor.attributes.append(VertexAttribute(format: .float2, offset: 12, bufferIndex: 0))
        vertexDescriptor.layouts.append(VertexLayout(stride: 20))
        
        return Mesh(device: device, vertices: vertices, indices: indices, vertexDescriptor: vertexDescriptor)
    }
}
