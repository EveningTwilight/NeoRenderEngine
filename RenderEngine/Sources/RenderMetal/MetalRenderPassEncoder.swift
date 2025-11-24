import Foundation
import Metal
import RenderCore

public class MetalRenderPassEncoder: RenderPassEncoder {
    let encoder: MTLRenderCommandEncoder
    
    // Validation state
    private var boundVertexBuffers: Set<Int> = []
    private var boundFragmentBuffers: Set<Int> = []
    private var currentPipeline: PipelineState?

    init(encoder: MTLRenderCommandEncoder) {
        self.encoder = encoder
    }

    public func setViewport(x: Float, y: Float, width: Float, height: Float) {
        let vp = MTLViewport(originX: Double(x), originY: Double(y), width: Double(width), height: Double(height), znear: 0, zfar: 1)
        encoder.setViewport(vp)
    }

    public func setPipeline(_ pipeline: PipelineState) {
        self.currentPipeline = pipeline
        guard let p = pipeline as? MetalPipelineState else { return }
        encoder.setRenderPipelineState(p.pipelineState)
    }

    public func setDepthStencilState(_ depthStencilState: DepthStencilState) {
        guard let dss = depthStencilState as? MetalDepthStencilState else { return }
        encoder.setDepthStencilState(dss.mtlDepthStencilState)
    }

    public func setVertexBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        boundVertexBuffers.insert(index)
        guard let b = buffer as? MetalBuffer else { return }
        encoder.setVertexBuffer(b.mtlBuffer, offset: offset, index: index)
    }

    public func setFragmentBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        boundFragmentBuffers.insert(index)
        guard let b = buffer as? MetalBuffer else { return }
        encoder.setFragmentBuffer(b.mtlBuffer, offset: offset, index: index)
    }

    public func setFragmentTexture(_ texture: Texture, index: Int) {
        guard let t = texture as? MetalTexture else { return }
        encoder.setFragmentTexture(t.mtlTexture, index: index)
    }

    public func drawIndexed(indexCount: Int, indexBuffer: Buffer, indexOffset: Int, indexType: IndexType) {
        validateBindings()
        guard let ib = indexBuffer as? MetalBuffer else { return }
        let mtlIndexType: MTLIndexType = (indexType == .uint16) ? .uint16 : .uint32
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: mtlIndexType, indexBuffer: ib.mtlBuffer, indexBufferOffset: indexOffset)
    }

    public func endEncoding() {
        encoder.endEncoding()
    }
    
    private func validateBindings() {
        guard let pipeline = currentPipeline as? MetalPipelineState else {
            print("Validation skipped: No pipeline set")
            return
        }
        
        // Use reflection if available (Preferred)
        if let reflection = pipeline.reflection {
            validateArguments(reflection.vertexArguments, boundBuffers: boundVertexBuffers, stage: "Vertex")
            validateArguments(reflection.fragmentArguments, boundBuffers: boundFragmentBuffers, stage: "Fragment")
            return
        }
        
        // Fallback to manual descriptor bindings
        let descriptor = pipeline.descriptor
        for binding in descriptor.uniformBindings {
            if binding.stage == .vertex || binding.stage == .both {
                if !boundVertexBuffers.contains(binding.bufferIndex) {
                    print("⚠️ WARNING: Vertex buffer at index \(binding.bufferIndex) (\(binding.name)) is NOT bound!")
                }
            }
            
            if binding.stage == .fragment || binding.stage == .both {
                if !boundFragmentBuffers.contains(binding.bufferIndex) {
                    print("⚠️ WARNING: Fragment buffer at index \(binding.bufferIndex) (\(binding.name)) is NOT bound!")
                }
            }
        }
    }
    
    private func validateArguments(_ arguments: [MTLArgument]?, boundBuffers: Set<Int>, stage: String) {
        guard let args = arguments else { return }
        for arg in args {
            if arg.type == .buffer && arg.isActive {
                // Skip system buffers if any (usually indices like 30, 31 might be reserved in some contexts, but standard MSL buffers are 0-29)
                // For now, we assume all active buffer arguments are user-defined.
                if !boundBuffers.contains(arg.index) {
                    print("⚠️ WARNING: \(stage) buffer at index \(arg.index) (\(arg.name)) is NOT bound!")
                }
            }
        }
    }
}
