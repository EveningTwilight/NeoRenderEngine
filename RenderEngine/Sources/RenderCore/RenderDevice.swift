import Foundation
import RenderMath

public protocol RenderDevice {
    /// Create a buffer with given size
    func makeBuffer(length: Int) -> Buffer

    /// Create a command queue
    func makeCommandQueue() -> CommandQueue

    /// Create a texture from descriptor
    func makeTexture(descriptor: TextureDescriptor) -> Texture

    /// Create shader program from source (backend handles compilation)
    func makeShaderProgram(source: String, label: String?) throws -> ShaderProgram

    /// Create pipeline state from descriptor and shader program
    func makePipeline(descriptor: PipelineDescriptor, shader: ShaderProgram) throws -> PipelineState

    /// Create a shader loader helper bound to this device
    func makeShaderLoader() -> ShaderLoader
}
