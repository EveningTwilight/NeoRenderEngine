import XCTest
@testable import RenderCore
@testable import RenderMath

final class RenderDeviceTests: XCTestCase {
    var device: MockRenderDevice!
    
    override func setUp() {
        super.setUp()
        device = MockRenderDevice()
    }
    
    func testMakeBuffer() {
        let buffer = device.makeBuffer(length: 1024)
        XCTAssertEqual(buffer.length, 1024)
        XCTAssertTrue(buffer is MockBuffer)
    }
    
    func testMakeTexture() {
        let desc = TextureDescriptor(width: 100, height: 200)
        let texture = device.makeTexture(descriptor: desc)
        XCTAssertEqual(texture.width, 100)
        XCTAssertEqual(texture.height, 200)
        XCTAssertTrue(texture is MockTexture)
    }
    
    func testMakePipeline() throws {
        let shader = try device.makeShaderProgram(source: "void main() {}", label: "test")
        let desc = PipelineDescriptor(label: "pipeline")
        let pipeline = try device.makePipeline(descriptor: desc, shader: shader)
        XCTAssertEqual(pipeline.descriptor.label, "pipeline")
    }
    
    func testCommandQueueAndBuffer() {
        let queue = device.makeCommandQueue()
        let buffer = queue.makeCommandBuffer()
        
        XCTAssertFalse((buffer as! MockCommandBuffer).committed)
        buffer.commit()
        XCTAssertTrue((buffer as! MockCommandBuffer).committed)
    }
    
    func testRenderPassEncoding() {
        let queue = device.makeCommandQueue()
        let buffer = queue.makeCommandBuffer()
        
        let texture = device.makeTexture(descriptor: TextureDescriptor(width: 100, height: 100))
        let passDesc = RenderPassDescriptor(colorTargets: [RenderTargetDescriptor(texture: texture)])
        
        let encoder = buffer.beginRenderPass(passDesc)
        XCTAssertTrue(encoder is MockRenderPassEncoder)
        
        let mockEncoder = encoder as! MockRenderPassEncoder
        XCTAssertFalse(mockEncoder.encodingEnded)
        
        encoder.endEncoding()
        XCTAssertTrue(mockEncoder.encodingEnded)
    }
}
