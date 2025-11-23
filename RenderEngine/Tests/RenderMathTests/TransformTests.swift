import XCTest
@testable import RenderMath

final class TransformTests: XCTestCase {
    func testInitialization() {
        let t = Transform()
        XCTAssertEqual(t.position, Vec3.zero)
        XCTAssertEqual(t.rotation, Quaternion.identity)
        XCTAssertEqual(t.scale, Vec3.one)
    }
    
    func testModelMatrix() {
        var t = Transform()
        t.position = Vec3(1, 2, 3)
        
        let mat = t.modelMatrix
        XCTAssertEqual(mat.position, Vec3(1, 2, 3))
        
        // Test scale
        t.scale = Vec3(2, 2, 2)
        // Scale affects the diagonal elements of the matrix (mostly)
        // But we don't have easy access to elements.
        // We can check that position is still correct.
        XCTAssertEqual(t.modelMatrix.position, Vec3(1, 2, 3))
    }
}
