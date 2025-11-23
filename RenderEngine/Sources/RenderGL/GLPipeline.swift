import Foundation
import RenderCore

public class GLPipeline: PipelineState {
    public let descriptor: PipelineDescriptor
    
    init(descriptor: PipelineDescriptor) {
        self.descriptor = descriptor
    }
}
