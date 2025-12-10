import Foundation

public enum VertexFormat: Hashable {
    case float
    case float2
    case float3
    case float4
    case uchar4
}

public enum VertexStepFunction: Hashable {
    case perVertex
    case perInstance
}

public struct VertexAttribute: Hashable {
    public var format: VertexFormat
    public var offset: Int
    public var bufferIndex: Int
    
    public init(format: VertexFormat, offset: Int, bufferIndex: Int) {
        self.format = format
        self.offset = offset
        self.bufferIndex = bufferIndex
    }
}

public struct VertexLayout: Hashable {
    public var stride: Int
    public var stepFunction: VertexStepFunction
    public var stepRate: Int
    
    public init(stride: Int, stepFunction: VertexStepFunction = .perVertex, stepRate: Int = 1) {
        self.stride = stride
        self.stepFunction = stepFunction
        self.stepRate = stepRate
    }
}

public struct VertexDescriptor: Hashable {
    public var attributes: [VertexAttribute]
    public var layouts: [VertexLayout]
    
    public init() {
        self.attributes = []
        self.layouts = []
    }
}
