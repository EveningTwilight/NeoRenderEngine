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
        var bufferSize = 0
        var members: [String: ShaderStructMember] = [:]
        
        switch arg.type {
        case .buffer:
            bufferIndex = arg.index
            bufferSize = arg.bufferDataSize
            if let structType = arg.bufferStructType {
                members = parseStruct(structType)
            }
        case .texture:
            textureIndex = arg.index
        default:
            return nil
        }
        
        return ShaderArgument(name: arg.name, type: type, bufferIndex: bufferIndex, textureIndex: textureIndex, isActive: arg.isActive, bufferSize: bufferSize, members: members)
    }
    
    private static func parseStruct(_ structType: MTLStructType) -> [String: ShaderStructMember] {
        var members: [String: ShaderStructMember] = [:]
        for member in structType.members {
            let type = convertDataType(member.dataType)
            let shaderMember = ShaderStructMember(name: member.name, type: type, offset: member.offset, size: 0) // Size might need more logic if needed, but offset is key
            members[member.name] = shaderMember
        }
        return members
    }
    
    private static func convertDataType(_ dataType: MTLDataType) -> UniformType {
        switch dataType {
        case .float: return .float
        case .float2: return .float2
        case .float3: return .float3
        case .float4: return .float4
        case .float4x4: return .mat4
        default: return .float // Fallback
        }
    }
}
