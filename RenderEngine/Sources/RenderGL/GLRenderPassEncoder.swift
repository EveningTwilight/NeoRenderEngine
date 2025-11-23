import Foundation
import RenderCore

public class GLRenderPassEncoder: RenderPassEncoder {
    public func setViewport(x: Float, y: Float, width: Float, height: Float) {
        // glViewport
    }

    public func setPipeline(_ pipeline: PipelineState) {
        // glUseProgram, etc.
    }

    public func setDepthStencilState(_ depthStencilState: DepthStencilState) {
        // glEnable(GL_DEPTH_TEST), glDepthFunc, etc.
    }

    public func setVertexBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        // glBindBuffer
    }

    public func setFragmentBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        // In GL ES 2.0, Uniform Buffers (UBO) are not supported directly in the same way.
        // We would typically map this to glUniform calls. 
        // For now, we leave this stubbed as we focus on Metal.
    }

    public func setFragmentTexture(_ texture: Texture, index: Int) {
        // glActiveTexture, glBindTexture
    }

    public func drawIndexed(indexCount: Int, indexBuffer: Buffer, indexOffset: Int, indexType: IndexType) {
        // glDrawElements
    }

    public func endEncoding() {
        // Cleanup
    }
}
