import Foundation

public enum UniformType: Hashable {
    case float
    case float2
    case float3
    case float4
    case mat4
}

public enum ShaderStage: Hashable {
    case vertex
    case fragment
    case both
}

public struct UniformBinding: Hashable {
    public var name: String
    public var type: UniformType
    public var bufferIndex: Int
    public var stage: ShaderStage
    
    public init(name: String, type: UniformType, bufferIndex: Int, stage: ShaderStage = .both) {
        self.name = name
        self.type = type
        self.bufferIndex = bufferIndex
        self.stage = stage
    }
}

public struct PipelineDescriptor: Hashable {
    public var label: String?
    public var vertexFunction: String?
    public var fragmentFunction: String?
    public var colorPixelFormat: Int
    public var depthPixelFormat: Int
    public var vertexDescriptor: VertexDescriptor?
    public var uniformBindings: [UniformBinding]

    public init(label: String? = nil, vertexFunction: String? = nil, fragmentFunction: String? = nil, colorPixelFormat: Int = 0, depthPixelFormat: Int = 0, vertexDescriptor: VertexDescriptor? = nil, uniformBindings: [UniformBinding] = []) {
        self.label = label
        self.vertexFunction = vertexFunction
        self.fragmentFunction = fragmentFunction
        self.colorPixelFormat = colorPixelFormat
        self.depthPixelFormat = depthPixelFormat
        self.vertexDescriptor = vertexDescriptor
        self.uniformBindings = uniformBindings
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
        hasher.combine(vertexFunction)
        hasher.combine(fragmentFunction)
        hasher.combine(colorPixelFormat)
        hasher.combine(depthPixelFormat)
        hasher.combine(vertexDescriptor)
        hasher.combine(uniformBindings)
    }
    
    public static func == (lhs: PipelineDescriptor, rhs: PipelineDescriptor) -> Bool {
        return lhs.label == rhs.label &&
               lhs.vertexFunction == rhs.vertexFunction &&
               lhs.fragmentFunction == rhs.fragmentFunction &&
               lhs.colorPixelFormat == rhs.colorPixelFormat &&
               lhs.depthPixelFormat == rhs.depthPixelFormat &&
               lhs.vertexDescriptor == rhs.vertexDescriptor &&
               lhs.uniformBindings == rhs.uniformBindings
    }
}

public protocol PipelineState: AnyObject {
    var descriptor: PipelineDescriptor { get }
}
