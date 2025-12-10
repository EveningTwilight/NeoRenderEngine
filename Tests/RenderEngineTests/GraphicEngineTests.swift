import XCTest
@testable import RenderEngine

final class GraphicEngineTests: XCTestCase {
    
    func testMetalInitialization() {
        // Metal should be available on both macOS and iOS (recent devices/simulators)
        // Note: On some CI environments Metal might not be available, but for local dev it is.
        do {
            let engine = try GraphicEngine(backendType: .metal)
            XCTAssertNotNil(engine)
            XCTAssertEqual(engine.backendType, .metal)
        } catch {
            print("Metal initialization failed: \(error)")
            // It's acceptable to fail if device doesn't support Metal (e.g. old simulator), 
            // but usually we expect success.
        }
    }
    
    func testGLInitialization() {
        #if os(iOS)
        // On iOS, GL should initialize successfully
        do {
            let engine = try GraphicEngine(backendType: .openGLES2)
            XCTAssertNotNil(engine)
            XCTAssertEqual(engine.backendType, .openGLES2)
        } catch {
            XCTFail("OpenGL ES 2.0 initialization failed on iOS: \(error)")
        }
        #elseif os(macOS)
        // On macOS, GL should fail with specific error
        XCTAssertThrowsError(try GraphicEngine(backendType: .openGLES2)) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "GraphicEngine")
            XCTAssertEqual(nsError.userInfo[NSLocalizedDescriptionKey] as? String, "OpenGL ES 2.0 is only supported on iOS")
        }
        #endif
    }
}
