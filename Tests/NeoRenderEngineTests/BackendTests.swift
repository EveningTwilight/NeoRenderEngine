import XCTest
@testable import NeoRenderEngine
@testable import RenderCore

final class BackendTests: XCTestCase {
    
    func testMetalBackend() throws {
        // 1. Initialize Engine
        let engine = try GraphicEngine(backendType: .metal)
        XCTAssertEqual(engine.backendType, .metal)
        
        let device = engine.device
        XCTAssertNotNil(device)
        
        // 2. Test Buffer Creation
        let buffer = device.makeBuffer(length: 256)
        XCTAssertEqual(buffer.length, 256)
        
        // 3. Test Texture Creation
        let texDesc = TextureDescriptor(width: 64, height: 64)
        let texture = device.makeTexture(descriptor: texDesc)
        XCTAssertEqual(texture.width, 64)
        XCTAssertEqual(texture.height, 64)
        
        // 4. Test Shader & Pipeline Creation
        // Simple shader source (Metal)
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        vertex float4 vertex_main(const device float4* vertex_array [[ buffer(0) ]], uint vid [[ vertex_id ]]) {
            return vertex_array[vid];
        }
        fragment float4 fragment_main() {
            return float4(1.0, 0.0, 0.0, 1.0);
        }
        """
        
        // Note: Compiling Metal shaders at runtime in tests might be slow or fail if library not found,
        // but basic object creation should work if we mock or use simple sources.
        // For now, we skip complex pipeline compilation in unit tests to avoid dependency on system Metal compiler availability in all envs.
        // But we can test the CommandQueue.
        
        let queue = device.makeCommandQueue()
        let cmdBuffer = queue.makeCommandBuffer()
        XCTAssertNotNil(cmdBuffer)
    }
    
    func testGLBackend() throws {
        #if os(iOS)
        // 1. Initialize Engine
        let engine = try GraphicEngine(backendType: .openGLES2)
        XCTAssertEqual(engine.backendType, .openGLES2)
        
        let device = engine.device
        XCTAssertNotNil(device)
        
        // 2. Test Buffer Creation
        let buffer = device.makeBuffer(length: 256)
        XCTAssertEqual(buffer.length, 256)
        
        // 3. Test Texture Creation
        let texDesc = TextureDescriptor(width: 64, height: 64)
        let texture = device.makeTexture(descriptor: texDesc)
        XCTAssertEqual(texture.width, 64)
        XCTAssertEqual(texture.height, 64)
        
        // 4. Test Command Queue
        let queue = device.makeCommandQueue()
        let cmdBuffer = queue.makeCommandBuffer()
        XCTAssertNotNil(cmdBuffer)
        
        #else
        print("Skipping GL Backend tests on macOS")
        #endif
    }
}
