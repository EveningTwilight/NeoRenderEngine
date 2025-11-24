import Foundation
import Metal
import RenderCore

public class MetalPipelineState: PipelineState {
    public let descriptor: PipelineDescriptor
    public let pipelineState: MTLRenderPipelineState
    public let reflection: MTLRenderPipelineReflection?

    init(descriptor: PipelineDescriptor, pipelineState: MTLRenderPipelineState, reflection: MTLRenderPipelineReflection?) {
        self.descriptor = descriptor
        self.pipelineState = pipelineState
        self.reflection = reflection
    }
}
