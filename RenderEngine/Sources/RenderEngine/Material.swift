import Foundation
import RenderCore
import RenderMath
import simd

public class Material {
    public let pipelineState: PipelineState
    public var textures: [Int: Texture] = [:]
    public var depthStencilState: DepthStencilState?
    
    private var properties: [String: Any] = [:]
    private var uniformBuffers: [String: Buffer] = [:]
    
    public init(pipelineState: PipelineState) {
        self.pipelineState = pipelineState
    }
    
    public func setTexture(_ texture: Texture, at index: Int) {
        textures[index] = texture
    }
    
    public func setValue(_ value: Float, for name: String) { properties[name] = value }
    public func setValue(_ value: Vec2, for name: String) { properties[name] = value }
    public func setValue(_ value: Vec3, for name: String) { properties[name] = value }
    public func setValue(_ value: Vec4, for name: String) { properties[name] = value }
    public func setValue(_ value: Mat4, for name: String) { properties[name] = value }
    
    public func updateUniforms(device: RenderDevice) {
        guard let reflection = pipelineState.reflection else { return }
        
        func processArguments(_ arguments: [String: ShaderArgument]) {
            for (_, arg) in arguments {
                if arg.bufferIndex >= 0 && !arg.members.isEmpty {
                    updateBuffer(device: device, argument: arg)
                }
            }
        }
        
        processArguments(reflection.vertexArguments)
        processArguments(reflection.fragmentArguments)
    }
    
    private func updateBuffer(device: RenderDevice, argument: ShaderArgument) {
        let buffer: Buffer
        if let b = uniformBuffers[argument.name], b.length >= argument.bufferSize {
            buffer = b
        } else {
            buffer = device.makeBuffer(length: argument.bufferSize)
            uniformBuffers[argument.name] = buffer
        }
        
        let ptr = buffer.contents()
        
        for (memberName, member) in argument.members {
            guard let value = properties[memberName] else { continue }
            let offset = member.offset
            
            switch member.type {
            case .float:
                if let v = value as? Float {
                    ptr.storeBytes(of: v, toByteOffset: offset, as: Float.self)
                }
            case .float2:
                if let v = value as? Vec2 {
                    let array = v.toArray()
                    ptr.storeBytes(of: array[0], toByteOffset: offset, as: Float.self)
                    ptr.storeBytes(of: array[1], toByteOffset: offset + 4, as: Float.self)
                }
            case .float3:
                if let v = value as? Vec3 {
                    let array = v.toArray()
                    ptr.storeBytes(of: array[0], toByteOffset: offset, as: Float.self)
                    ptr.storeBytes(of: array[1], toByteOffset: offset + 4, as: Float.self)
                    ptr.storeBytes(of: array[2], toByteOffset: offset + 8, as: Float.self)
                }
            case .float4:
                if let v = value as? Vec4 {
                    let array = v.toArray()
                    ptr.storeBytes(of: array[0], toByteOffset: offset, as: Float.self)
                    ptr.storeBytes(of: array[1], toByteOffset: offset + 4, as: Float.self)
                    ptr.storeBytes(of: array[2], toByteOffset: offset + 8, as: Float.self)
                    ptr.storeBytes(of: array[3], toByteOffset: offset + 12, as: Float.self)
                }
            case .mat4:
                if let v = value as? Mat4 {
                    let array = v.toArray()
                    for i in 0..<16 {
                        ptr.storeBytes(of: array[i], toByteOffset: offset + i * 4, as: Float.self)
                    }
                }
            }
        }
    }
    
    public func bind(to encoder: RenderPassEncoder) {
        encoder.setPipeline(pipelineState)
        if let depthState = depthStencilState {
            encoder.setDepthStencilState(depthState)
        }
        
        for (index, texture) in textures {
            encoder.setFragmentTexture(texture, index: index)
        }
        
        guard let reflection = pipelineState.reflection else { return }
        
        for (_, arg) in reflection.vertexArguments {
            if let buffer = uniformBuffers[arg.name] {
                encoder.setVertexBuffer(buffer, offset: 0, index: arg.bufferIndex)
            }
        }
        
        for (_, arg) in reflection.fragmentArguments {
            if let buffer = uniformBuffers[arg.name] {
                encoder.setFragmentBuffer(buffer, offset: 0, index: arg.bufferIndex)
            }
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
