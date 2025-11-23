import RenderCore

public class GLDepthStencilState: DepthStencilState {
    public let descriptor: DepthStencilDescriptor
    
    public init(descriptor: DepthStencilDescriptor) {
        self.descriptor = descriptor
    }
}
