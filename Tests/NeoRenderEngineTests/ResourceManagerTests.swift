import XCTest
@testable import NeoRenderEngine
@testable import RenderCore

final class ResourceManagerTests: XCTestCase {
    var device: MockRenderDevice!
    var resourceManager: ResourceManager!
    
    override func setUp() {
        super.setUp()
        device = MockRenderDevice()
        resourceManager = ResourceManager(device: device)
    }
    
    func testShaderCaching() throws {
        let source = "void main() {}"
        let name = "TestShader"
        
        // First creation
        let shader1 = try resourceManager.createShader(name: name, source: source)
        XCTAssertNotNil(shader1)
        
        // Second creation (should return cached instance)
        let shader2 = try resourceManager.createShader(name: name, source: source)
        
        // Verify they are the same instance (reference equality)
        XCTAssertTrue(shader1 === shader2)
        
        // Verify retrieval
        let retrieved = resourceManager.getShader(name: name)
        XCTAssertTrue(shader1 === retrieved)
    }
    
    func testPipelineCaching() throws {
        let source = "void main() {}"
        let shader = try resourceManager.createShader(name: "Shader", source: source)
        let desc = PipelineDescriptor(label: "Pipeline")
        let name = "TestPipeline"
        
        // First creation
        let pipeline1 = try resourceManager.createPipeline(name: name, descriptor: desc, shader: shader)
        XCTAssertNotNil(pipeline1)
        
        // Second creation
        let pipeline2 = try resourceManager.createPipeline(name: name, descriptor: desc, shader: shader)
        
        // Verify equality
        XCTAssertTrue(pipeline1 === pipeline2)
        
        // Verify retrieval
        let retrieved = resourceManager.getPipeline(name: name)
        XCTAssertTrue(pipeline1 === retrieved)
    }
    
    func testTextureCaching() throws {
        let name = "Checkerboard"
        
        // Create checkerboard
        let tex1 = try resourceManager.createCheckerboardTexture(name: name)
        XCTAssertNotNil(tex1)
        
        // Create again
        let tex2 = try resourceManager.createCheckerboardTexture(name: name)
        
        // Verify equality
        XCTAssertTrue(tex1 === tex2)
        
        // Verify retrieval
        let retrieved = resourceManager.getTexture(name: name)
        XCTAssertTrue(tex1 === retrieved)
    }
    
    func testAddTexture() {
        let tex = MockTexture(width: 100, height: 100)
        let name = "ManualTexture"
        
        resourceManager.addTexture(tex, name: name)
        
        let retrieved = resourceManager.getTexture(name: name)
        XCTAssertTrue(tex === retrieved)
    }
}
