import XCTest
@testable import RenderMath

final class Vec3Tests: XCTestCase {
    func testInitialization() {
        let v = Vec3(1, 2, 3)
        XCTAssertEqual(v.x, 1)
        XCTAssertEqual(v.y, 2)
        XCTAssertEqual(v.z, 3)
    }
    
    func testAddition() {
        let v1 = Vec3(1, 2, 3)
        let v2 = Vec3(4, 5, 6)
        let result = v1 + v2
        XCTAssertEqual(result, Vec3(5, 7, 9))
    }
    
    func testDotProduct() {
        let v1 = Vec3(1, 0, 0)
        let v2 = Vec3(0, 1, 0)
        XCTAssertEqual(v1.dot(v2), 0)
        
        let v3 = Vec3(1, 2, 3)
        XCTAssertEqual(v3.dot(v3), 14)
    }
    
    func testCrossProduct() {
        let v1 = Vec3(1, 0, 0)
        let v2 = Vec3(0, 1, 0)
        let result = v1.cross(v2)
        XCTAssertEqual(result, Vec3(0, 0, 1))
    }
    
    func testNormalization() {
        let v = Vec3(3, 0, 0)
        XCTAssertEqual(v.normalized(), Vec3(1, 0, 0))
        
        let zero = Vec3.zero
        XCTAssertEqual(zero.normalized(), Vec3.zero)
    }
}
