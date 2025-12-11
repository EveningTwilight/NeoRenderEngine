import XCTest
@testable import RenderCore
@testable import NeoRenderEngine
@testable import RenderMath

class PostProcessorTests: XCTestCase {
    var device: MockRenderDevice!
    var postProcessor: PostProcessor!
    
    override func setUp() {
        super.setUp()
        device = MockRenderDevice()
        postProcessor = PostProcessor(device: device)
    }
    
    func testInitialization() {
        XCTAssertNotNil(postProcessor)
        XCTAssertNotNil(postProcessor.quadMesh)
        
        // Verify Quad Mesh
        // 4 vertices * 20 bytes stride = 80 bytes
        XCTAssertEqual((postProcessor.quadMesh.vertexBuffer as? MockBuffer)?.length, 80)
        // 6 indices * 2 bytes (UInt16) = 12 bytes
        XCTAssertEqual((postProcessor.quadMesh.indexBuffer as? MockBuffer)?.length, 12)
    }
    
    func testRender() {
        let texture = MockTexture(width: 100, height: 100)
        let commandBuffer = MockCommandBuffer()
        let passDescriptor = RenderPassDescriptor()
        
        // Pipeline must be set
        let pipelineDesc = PipelineDescriptor()
        let pipeline = MockPipelineState(descriptor: pipelineDesc)
        postProcessor.pipelineState = pipeline
        
        postProcessor.render(texture: texture, in: commandBuffer, passDescriptor: passDescriptor)
        
        XCTAssertTrue(commandBuffer.encoderCreated)
        // We can't easily check if drawIndexed was called on the encoder because MockCommandBuffer creates a new MockRenderPassEncoder internally and doesn't expose it.
        // But we can verify that beginRenderPass was called.
    }
}
