import Foundation
import RenderMath

public struct RenderTargetDescriptor {
    public var texture: Texture
    public var clearColor: Vec4?
    public var clearDepth: Double?
    public var clearStencil: UInt32?
    
    public init(texture: Texture, clearColor: Vec4? = nil, clearDepth: Double? = nil, clearStencil: UInt32? = nil) {
        self.texture = texture
        self.clearColor = clearColor
        self.clearDepth = clearDepth
        self.clearStencil = clearStencil
    }
}

public struct RenderPassDescriptor {
    public var colorTargets: [RenderTargetDescriptor]
    public var depthTarget: RenderTargetDescriptor?

    public init(colorTargets: [RenderTargetDescriptor] = [], depthTarget: RenderTargetDescriptor? = nil) {
        self.colorTargets = colorTargets
        self.depthTarget = depthTarget
    }
}

public enum IndexType {
    case uint16
    case uint32
}

public protocol RenderPassEncoder {
    func setViewport(x: Float, y: Float, width: Float, height: Float)
    func setPipeline(_ pipeline: PipelineState)
    func setDepthStencilState(_ depthStencilState: DepthStencilState)
    func setVertexBuffer(_ buffer: Buffer, offset: Int, index: Int)
    func setFragmentBuffer(_ buffer: Buffer, offset: Int, index: Int)
    func drawIndexed(indexCount: Int, indexBuffer: Buffer, indexOffset: Int, indexType: IndexType)
    func endEncoding()
}
