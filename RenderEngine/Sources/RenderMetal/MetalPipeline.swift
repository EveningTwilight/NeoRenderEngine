import Foundation
import Metal
import RenderCore

public class MetalPipelineState: PipelineState {
    public let descriptor: PipelineDescriptor
    public let pipelineState: MTLRenderPipelineState

    init(descriptor: PipelineDescriptor, pipelineState: MTLRenderPipelineState) {
        self.descriptor = descriptor
        self.pipelineState = pipelineState
    }
}
