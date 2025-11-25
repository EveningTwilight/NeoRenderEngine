import XCTest
@testable import RenderEngine
@testable import RenderCore
@testable import RenderMetal

final class ReflectionTests: XCTestCase {
    var device: MetalDevice!
    var resourceManager: ResourceManager!
    
    override func setUp() {
        super.setUp()
        device = MetalDevice(preferred: nil)
        resourceManager = ResourceManager(device: device)
    }
    
    func testReflectionParsing() throws {
        guard let device = device else {
            throw XCTSkip("Metal is not supported")
        }
        
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct Uniforms {
            float4x4 model;
        };
        
        vertex float4 vertex_main(constant Uniforms& uniforms [[buffer(1)]],
                                  uint vid [[vertex_id]]) {
            return uniforms.model[0];
        }
        
        fragment float4 fragment_main(texture2d<float> tex [[texture(0)]]) {
            return tex.sample(sampler(filter::linear), float2(0));
        }
        """
        
        let shader = try resourceManager.createShader(name: "ReflectionShader", source: source)
        var desc = PipelineDescriptor(label: "ReflectionPipeline")
        desc.vertexFunction = "vertex_main"
        desc.fragmentFunction = "fragment_main"
        desc.colorPixelFormat = .bgra8Unorm // Default
        
        let pipeline = try resourceManager.createPipeline(name: "ReflectionPipeline", descriptor: desc, shader: shader)
        
        guard let reflection = pipeline.reflection else {
            XCTFail("Reflection should not be nil")
            return
        }
        
        // Check Vertex Argument "uniforms" at buffer 1
        if let arg = reflection.vertexArguments["uniforms"] {
            XCTAssertEqual(arg.bufferIndex, 1)
        } else {
            XCTFail("Vertex argument 'uniforms' not found")
        }
        
        // Check Fragment Argument "tex" at texture 0
        if let arg = reflection.fragmentArguments["tex"] {
            XCTAssertEqual(arg.textureIndex, 0)
        } else {
            XCTFail("Fragment argument 'tex' not found")
        }
    }
}
