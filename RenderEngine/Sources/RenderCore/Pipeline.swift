import Foundation

public struct PipelineDescriptor: Hashable {
    public var label: String?
    public var vertexFunction: String?
    public var fragmentFunction: String?
    public var colorPixelFormat: Int

    public init(label: String? = nil, vertexFunction: String? = nil, fragmentFunction: String? = nil, colorPixelFormat: Int = 0) {
        self.label = label
        self.vertexFunction = vertexFunction
        self.fragmentFunction = fragmentFunction
        self.colorPixelFormat = colorPixelFormat
    }
}

public protocol PipelineState: AnyObject {
    var descriptor: PipelineDescriptor { get }
}
