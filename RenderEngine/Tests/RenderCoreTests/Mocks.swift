import Foundation
@testable import RenderCore
@testable import RenderMath

class MockBuffer: Buffer {
    var length: Int
    init(length: Int) {
        self.length = length
    }
}

class MockTexture: Texture {
    var width: Int
    var height: Int
    var uploadedData: Data?
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    func upload(data: Data, bytesPerRow: Int) throws {
        self.uploadedData = data
    }
}

class MockShaderProgram: ShaderProgram {
    var label: String?
    init(label: String?) {
        self.label = label
    }
}

class MockPipelineState: PipelineState {
    var descriptor: PipelineDescriptor
    init(descriptor: PipelineDescriptor) {
        self.descriptor = descriptor
    }
}

class MockRenderPassEncoder: RenderPassEncoder {
    var viewportSet = false
    var pipelineSet = false
    var vertexBufferSet = false
    var drawCallMade = false
    var encodingEnded = false
    
    func setViewport(x: Float, y: Float, width: Float, height: Float) {
        viewportSet = true
    }
    
    func setPipeline(_ pipeline: PipelineState) {
        pipelineSet = true
    }
    
    func setVertexBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        vertexBufferSet = true
    }
    
    func drawIndexed(indexCount: Int, indexBuffer: Buffer, indexOffset: Int) {
        drawCallMade = true
    }
    
    func endEncoding() {
        encodingEnded = true
    }
}

class MockCommandBuffer: CommandBuffer {
    var committed = false
    var encoderCreated = false
    var presentedTexture: Texture?
    
    func beginRenderPass(_ descriptor: RenderPassDescriptor) -> RenderPassEncoder {
        encoderCreated = true
        return MockRenderPassEncoder()
    }
    
    func present(_ texture: Texture) {
        presentedTexture = texture
    }
    
    func commit() {
        committed = true
    }
}

class MockCommandQueue: CommandQueue {
    func makeCommandBuffer() -> CommandBuffer {
        return MockCommandBuffer()
    }
}

class MockShaderLoader: ShaderLoader {
    func makeShaderProgram(source: String, label: String?) throws -> ShaderProgram {
        return MockShaderProgram(label: label)
    }
}

class MockRenderDevice: RenderDevice {
    func makeBuffer(length: Int) -> Buffer {
        return MockBuffer(length: length)
    }
    
    func makeCommandQueue() -> CommandQueue {
        return MockCommandQueue()
    }
    
    func makeTexture(descriptor: TextureDescriptor) -> Texture {
        return MockTexture(width: descriptor.width, height: descriptor.height)
    }
    
    func makeShaderProgram(source: String, label: String?) throws -> ShaderProgram {
        return MockShaderProgram(label: label)
    }
    
    func makePipeline(descriptor: PipelineDescriptor, shader: ShaderProgram) throws -> PipelineState {
        return MockPipelineState(descriptor: descriptor)
    }
    
    func makeShaderLoader() -> ShaderLoader {
        return MockShaderLoader()
    }
}
