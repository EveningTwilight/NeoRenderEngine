#if os(iOS)
import Foundation
import RenderCore

public class GLPipeline: PipelineState {
    public let descriptor: PipelineDescriptor
    public let shader: GLShader
    
    init(descriptor: PipelineDescriptor, shader: GLShader) {
        self.descriptor = descriptor
        self.shader = shader
    }
}
#endif
