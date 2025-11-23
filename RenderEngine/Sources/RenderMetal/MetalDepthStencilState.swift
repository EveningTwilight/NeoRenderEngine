import Metal
import RenderCore

public class MetalDepthStencilState: DepthStencilState {
    public let descriptor: DepthStencilDescriptor
    public let mtlDepthStencilState: MTLDepthStencilState

    public init(descriptor: DepthStencilDescriptor, device: MTLDevice) {
        self.descriptor = descriptor
        
        let mtlDescriptor = MTLDepthStencilDescriptor()
        mtlDescriptor.label = descriptor.label
        mtlDescriptor.depthCompareFunction = MetalDepthStencilState.mapCompareFunction(descriptor.depthCompareFunction)
        mtlDescriptor.isDepthWriteEnabled = descriptor.isDepthWriteEnabled
        
        guard let state = device.makeDepthStencilState(descriptor: mtlDescriptor) else {
            fatalError("Failed to create Metal depth stencil state")
        }
        self.mtlDepthStencilState = state
    }
    
    private static func mapCompareFunction(_ function: CompareFunction) -> MTLCompareFunction {
        switch function {
        case .never: return .never
        case .less: return .less
        case .equal: return .equal
        case .lessEqual: return .lessEqual
        case .greater: return .greater
        case .notEqual: return .notEqual
        case .greaterEqual: return .greaterEqual
        case .always: return .always
        }
    }
}
