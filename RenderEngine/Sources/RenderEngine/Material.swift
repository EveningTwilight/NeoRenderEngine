import Foundation
import RenderCore

public class Material {
    public let pipelineState: PipelineState
    public var textures: [Int: Texture] = [:]
    public var depthStencilState: DepthStencilState?
    
    public init(pipelineState: PipelineState) {
        self.pipelineState = pipelineState
    }
    
    public func setTexture(_ texture: Texture, at index: Int) {
        textures[index] = texture
    }
    
    public func bind(to encoder: RenderPassEncoder) {
        encoder.setPipeline(pipelineState)
        if let depthState = depthStencilState {
            encoder.setDepthStencilState(depthState)
        }
        
        for (index, texture) in textures {
            encoder.setFragmentTexture(texture, index: index)
        }
    }
}
