import Foundation
import RenderCore

public class GLRenderPassEncoder: RenderPassEncoder {
    public func setViewport(x: Float, y: Float, width: Float, height: Float) {
        // glViewport
    }

    public func setPipeline(_ pipeline: PipelineState) {
        // glUseProgram, etc.
    }

    public func setVertexBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        // glBindBuffer
    }

    public func drawIndexed(indexCount: Int, indexBuffer: Buffer, indexOffset: Int) {
        // glDrawElements
    }

    public func endEncoding() {
        // Cleanup
    }
}
