import Foundation
import NeoRenderEngine
import RenderCore
import RenderMath

class TriangleRenderer: RenderEngineDelegate {
    var pipeline: PipelineState?
    var vertexBuffer: Buffer?
    
    // Vertex data: Position (x, y, z) + Color (r, g, b, a)
    // Interleaved: x, y, z, r, g, b, a
    let vertices: [Float] = [
         0.0,  0.5, 0.0,   1.0, 0.0, 0.0, 1.0, // Top, Red
        -0.5, -0.5, 0.0,   0.0, 1.0, 0.0, 1.0, // Bottom Left, Green
         0.5, -0.5, 0.0,   0.0, 0.0, 1.0, 1.0  // Bottom Right, Blue
    ]
    
    func update(deltaTime: Double) {
        // No update logic for static triangle
    }
    
    func draw(in engine: GraphicEngine, commandBuffer: CommandBuffer, renderPassDescriptor: RenderPassDescriptor) {
        let device = engine.device
        
        // 1. Initialize Resources (One-time)
        if pipeline == nil {
            do {
                try setupResources(device: device)
            } catch {
                print("Failed to setup resources: \(error)")
                return
            }
        }
        
        guard let pipeline = pipeline, let vertexBuffer = vertexBuffer else { return }
        
        // 2. Encode Render Pass
        let encoder = commandBuffer.beginRenderPass(renderPassDescriptor)
        
        encoder.setPipeline(pipeline)
        encoder.setViewport(x: 0, y: 0, width: Float(renderPassDescriptor.colorTargets[0].texture.width), height: Float(renderPassDescriptor.colorTargets[0].texture.height))
        
        // Set vertex buffer at index 0
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Draw 3 vertices
        // Note: RenderPassEncoder currently has drawIndexed, but we need drawPrimitives (non-indexed) for this simple demo.
        // Or we can create an index buffer.
        // Let's assume we need to add drawPrimitives to RenderPassEncoder or use drawIndexed with an index buffer.
        // For simplicity, let's create a simple index buffer [0, 1, 2]
        
        // Wait, I need to create an index buffer every frame? No, cache it.
        // Or better, add drawPrimitives to RenderPassEncoder.
        // For now, I'll use drawIndexed with a temporary index buffer or cached one.
        
        // Let's create a quick index buffer
        let indices: [UInt16] = [0, 1, 2]
        let indexBufferSize = indices.count * MemoryLayout<UInt16>.size
        let indexBuffer = device.makeBuffer(length: indexBufferSize)
        let ptr = indexBuffer.contents()
        indices.withUnsafeBytes {
            ptr.copyMemory(from: $0.baseAddress!, byteCount: indexBufferSize)
        }
        
        encoder.drawIndexed(indexCount: 3, indexBuffer: indexBuffer, indexOffset: 0, indexType: .uint16)
        
        encoder.endEncoding()
    }
    
    private func setupResources(device: RenderDevice) throws {
        // Shader Source
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct VertexIn {
            float3 position [[attribute(0)]];
            float4 color [[attribute(1)]];
        };
        
        struct VertexOut {
            float4 position [[position]];
            float4 color;
        };
        
        vertex VertexOut vertex_main(const device float* vertices [[buffer(0)]], uint vertexID [[vertex_id]]) {
            VertexOut out;
            // Stride is 7 floats (3 pos + 4 color)
            uint stride = 7;
            uint offset = vertexID * stride;
            
            out.position = float4(vertices[offset], vertices[offset+1], vertices[offset+2], 1.0);
            out.color = float4(vertices[offset+3], vertices[offset+4], vertices[offset+5], vertices[offset+6]);
            return out;
        }
        
        fragment float4 fragment_main(VertexOut in [[stage_in]]) {
            return in.color;
        }
        """
        
        // Create Shader Program
        let shader = try device.makeShaderProgram(source: shaderSource, label: "TriangleShader")
        
        // Create Pipeline
        var pipelineDesc = PipelineDescriptor(label: "TrianglePipeline")
        pipelineDesc.vertexFunction = "vertex_main"
        pipelineDesc.fragmentFunction = "fragment_main"
        pipelineDesc.colorPixelFormat = .bgra8Unorm
        
        self.pipeline = try device.makePipeline(descriptor: pipelineDesc, shader: shader)
        
        // Create Vertex Buffer
        let bufferSize = vertices.count * MemoryLayout<Float>.size
        let buffer = device.makeBuffer(length: bufferSize)
        
        // Upload data
        let ptr = buffer.contents()
        vertices.withUnsafeBytes {
            ptr.copyMemory(from: $0.baseAddress!, byteCount: bufferSize)
        }
        
        self.vertexBuffer = buffer
    }
}
