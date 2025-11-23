import Foundation
import Metal
import RenderCore

public class MetalRenderPassEncoder: RenderPassEncoder {
    let encoder: MTLRenderCommandEncoder

    init(encoder: MTLRenderCommandEncoder) {
        self.encoder = encoder
    }

    public func setViewport(x: Float, y: Float, width: Float, height: Float) {
        let vp = MTLViewport(originX: Double(x), originY: Double(y), width: Double(width), height: Double(height), znear: 0, zfar: 1)
        encoder.setViewport(vp)
    }

    public func setPipeline(_ pipeline: PipelineState) {
        guard let p = pipeline as? MetalPipelineState else { return }
        encoder.setRenderPipelineState(p.pipelineState)
    }

    public func setDepthStencilState(_ depthStencilState: DepthStencilState) {
        guard let dss = depthStencilState as? MetalDepthStencilState else { return }
        encoder.setDepthStencilState(dss.mtlDepthStencilState)
    }

    public func setVertexBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        guard let b = buffer as? MetalBuffer else { return }
        encoder.setVertexBuffer(b.mtlBuffer, offset: offset, index: index)
    }

    public func setFragmentBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        guard let b = buffer as? MetalBuffer else { return }
        encoder.setFragmentBuffer(b.mtlBuffer, offset: offset, index: index)
    }

    public func setFragmentTexture(_ texture: Texture, index: Int) {
        guard let t = texture as? MetalTexture else { return }
        encoder.setFragmentTexture(t.mtlTexture, index: index)
    }

    public func drawIndexed(indexCount: Int, indexBuffer: Buffer, indexOffset: Int, indexType: IndexType) {
        guard let ib = indexBuffer as? MetalBuffer else { return }
        let mtlIndexType: MTLIndexType = (indexType == .uint16) ? .uint16 : .uint32
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: mtlIndexType, indexBuffer: ib.mtlBuffer, indexBufferOffset: indexOffset)
    }

    public func endEncoding() {
        encoder.endEncoding()
    }
}
