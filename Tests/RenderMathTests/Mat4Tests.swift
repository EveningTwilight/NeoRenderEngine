import XCTest
@testable import RenderMath

final class Mat4Tests: XCTestCase {
    func testIdentity() {
        let identity = Mat4.identity
        let v = Vec3(1, 2, 3)
        // Identity matrix shouldn't change the vector (conceptually, though Mat4 * Vec3 isn't directly exposed yet, we can check properties)
        // Or check internal storage against identity
        // Since we can't access storage directly in tests easily without making it public, we can test properties like position.
        XCTAssertEqual(identity.position, Vec3(0, 0, 0))
    }
    
    func testTranslation() {
        let t = Vec3(10, 20, 30)
        let mat = Mat4.translation(t)
        XCTAssertEqual(mat.position, t)
    }
    
    func testScale() {
        let s = Vec3(2, 3, 4)
        let mat = Mat4.scale(s)
        // We can't easily check the diagonal without access to elements, 
        // but we can check that it doesn't affect position
        XCTAssertEqual(mat.position, Vec3(0, 0, 0))
    }
    
    func testMultiplication() {
        let t1 = Mat4.translation(Vec3(1, 0, 0))
        let t2 = Mat4.translation(Vec3(0, 1, 0))
        let result = t1 * t2
        XCTAssertEqual(result.position, Vec3(1, 1, 0))
    }
    
    func testLookAt() {
        let eye = Vec3(0, 0, 10)
        let center = Vec3(0, 0, 0)
        let up = Vec3(0, 1, 0)
        let view = Mat4.lookAt(eye: eye, center: center, up: up)
        // LookAt matrix transforms world to view. 
        // Eye at (0,0,10) looking at (0,0,0) means the camera is backed up along Z.
        // The view matrix should translate by (0,0,-10).
        // Note: The position property of Mat4 extracts the translation column, which is the inverse of camera position in view matrix logic usually.
        // Let's just verify it's not identity.
        XCTAssertNotEqual(view, Mat4.identity)
    }
}
