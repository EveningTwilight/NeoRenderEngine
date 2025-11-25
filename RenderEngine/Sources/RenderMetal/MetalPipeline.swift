import Foundation
import Metal
import RenderCore

public class MetalPipelineState: PipelineState {
    public let descriptor: PipelineDescriptor
    public let pipelineState: MTLRenderPipelineState
    public let reflection: PipelineReflection?

    init(descriptor: PipelineDescriptor, pipelineState: MTLRenderPipelineState, reflection: MTLRenderPipelineReflection?) {
        self.descriptor = descriptor
        self.pipelineState = pipelineState
        self.reflection = MetalPipelineState.parseReflection(reflection)
    }
    
    private static func parseReflection(_ mtlReflection: MTLRenderPipelineReflection?) -> PipelineReflection? {
        guard let reflection = mtlReflection else { return nil }
        
        var vertexArgs: [String: ShaderArgument] = [:]
        var fragmentArgs: [String: ShaderArgument] = [:]
        
        for arg in reflection.vertexArguments ?? [] {
            if let shaderArg = convertArgument(arg) {
                vertexArgs[shaderArg.name] = shaderArg
            }
        }
        
        for arg in reflection.fragmentArguments ?? [] {
            if let shaderArg = convertArgument(arg) {
                fragmentArgs[shaderArg.name] = shaderArg
            }
        }
        
        return PipelineReflection(vertexArguments: vertexArgs, fragmentArguments: fragmentArgs)
    }
    
    private static func convertArgument(_ arg: MTLArgument) -> ShaderArgument? {
        guard arg.isActive else { return nil }
        
        let type: UniformType = .float // Default/Placeholder
        var bufferIndex = -1
        var textureIndex = -1
        
        switch arg.type {
        case .buffer:
            bufferIndex = arg.index
        case .texture:
            textureIndex = arg.index
        default:
            return nil
        }
        
        return ShaderArgument(name: arg.name, type: type, bufferIndex: bufferIndex, textureIndex: textureIndex, isActive: arg.isActive)
    }
}
