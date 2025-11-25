import XCTest
@testable import RenderEngine
@testable import RenderCore
@testable import RenderMetal

final class PipelineTests: XCTestCase {
    
    var device: MetalDevice!
    var resourceManager: ResourceManager!
    
    override func setUp() {
        super.setUp()
        device = MetalDevice(preferred: nil)
        resourceManager = ResourceManager(device: device)
    }
    
    func testPipelineCreationFailsWithInvalidFunctionName() throws {
        guard let device = device else {
            throw XCTSkip("Metal is not supported on this device")
        }
        
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;
        vertex float4 my_vertex() { return float4(0); }
        fragment float4 my_fragment() { return float4(0); }
        """
        
        // Note: MetalDevice.makeShaderProgram currently looks for "vertex_main" and "fragment_main" by default
        // inside makeShaderProgram. If we want to test custom names, we need to ensure makeShaderProgram doesn't fail first.
        // Actually, makeShaderProgram throws if it can't find "vertex_main".
        // So let's provide a source that HAS vertex_main, but we ask for "invalid_main".
        
        let validSource = """
        #include <metal_stdlib>
        using namespace metal;
        vertex float4 vertex_main() { return float4(0); }
        fragment float4 fragment_main() { return float4(0); }
        """
        
        let shader = try resourceManager.createShader(name: "TestShader", source: validSource)
        
        var descriptor = PipelineDescriptor(label: "TestPipeline")
        descriptor.vertexFunction = "invalid_vertex_function" // This should fail
        descriptor.fragmentFunction = "fragment_main"
        descriptor.colorPixelFormat = .bgra8Unorm
        
        XCTAssertThrowsError(try resourceManager.createPipeline(name: "TestPipeline", descriptor: descriptor, shader: shader)) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "RenderEngineMetal")
            // Code -5 is for Vertex function not found
            XCTAssertEqual(nsError.code, -5)
        }
    }
}
