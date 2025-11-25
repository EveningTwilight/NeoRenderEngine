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
    
    public func getBindingIndex(forName name: String) -> Int? {
        guard let reflection = pipelineState.reflection else { return nil }
        
        // Check Vertex
        if let arg = reflection.vertexArguments[name] {
            if arg.bufferIndex >= 0 { return arg.bufferIndex }
            if arg.textureIndex >= 0 { return arg.textureIndex }
        }
        
        // Check Fragment
        if let arg = reflection.fragmentArguments[name] {
            if arg.bufferIndex >= 0 { return arg.bufferIndex }
            if arg.textureIndex >= 0 { return arg.textureIndex }
        }
        
        return nil
    }
}
