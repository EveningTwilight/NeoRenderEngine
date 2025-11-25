import Foundation
@testable import RenderCore
@testable import RenderMath

// Duplicated from RenderCoreTests/Mocks.swift for use in RenderEngineTests
class MockBuffer: Buffer {
    var length: Int
    var data: UnsafeMutableRawPointer
    
    init(length: Int) {
        self.length = length
        self.data = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: 1)
    }
    
    deinit {
        data.deallocate()
    }
    
    func contents() -> UnsafeMutableRawPointer {
        return data
    }
    
    func bind(target: Int) { } // Added for GL compatibility if needed
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
    
    func getBytes(_ buffer: UnsafeMutableRawPointer, bytesPerRow: Int) {
        // Mock implementation
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
    var reflection: PipelineReflection?
    
    init(descriptor: PipelineDescriptor) {
        self.descriptor = descriptor
    }
}

class MockDepthStencilState: DepthStencilState {
    var descriptor: DepthStencilDescriptor
    init(descriptor: DepthStencilDescriptor) {
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

    func setDepthStencilState(_ depthStencilState: DepthStencilState) {
    }
    
    func setVertexBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        vertexBufferSet = true
    }
    
    func setFragmentBuffer(_ buffer: Buffer, offset: Int, index: Int) {
    }
    
    func setFragmentTexture(_ texture: Texture, index: Int) {
    }
    
    func drawIndexed(indexCount: Int, indexBuffer: Buffer, indexOffset: Int, indexType: IndexType) {
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
    
    func synchronize(_ texture: Texture) {}
    
    func waitUntilCompleted() {}
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

    func makeDepthStencilState(descriptor: DepthStencilDescriptor) -> DepthStencilState {
        return MockDepthStencilState(descriptor: descriptor)
    }
}
