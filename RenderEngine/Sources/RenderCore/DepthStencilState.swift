import Foundation

public enum CompareFunction {
    case never
    case less
    case equal
    case lessEqual
    case greater
    case notEqual
    case greaterEqual
    case always
}

public struct DepthStencilDescriptor {
    public var label: String?
    public var depthCompareFunction: CompareFunction
    public var isDepthWriteEnabled: Bool
    
    public init(label: String? = nil, depthCompareFunction: CompareFunction = .always, isDepthWriteEnabled: Bool = false) {
        self.label = label
        self.depthCompareFunction = depthCompareFunction
        self.isDepthWriteEnabled = isDepthWriteEnabled
    }
}

public protocol DepthStencilState: AnyObject {
    var descriptor: DepthStencilDescriptor { get }
}
