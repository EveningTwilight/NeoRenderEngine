import XCTest
@testable import RenderMath

final class Vec4Tests: XCTestCase {
    func testInitialization() {
        let v = Vec4(1, 2, 3, 4)
        XCTAssertEqual(v.x, 1)
        XCTAssertEqual(v.y, 2)
        XCTAssertEqual(v.z, 3)
        XCTAssertEqual(v.w, 4)
    }
    
    func testAddition() {
        let v1 = Vec4(1, 2, 3, 4)
        let v2 = Vec4(5, 6, 7, 8)
        let result = v1 + v2
        XCTAssertEqual(result, Vec4(6, 8, 10, 12))
    }
    
    func testSubtraction() {
        let v1 = Vec4(5, 6, 7, 8)
        let v2 = Vec4(1, 2, 3, 4)
        let result = v1 - v2
        XCTAssertEqual(result, Vec4(4, 4, 4, 4))
    }
    
    func testScalarMultiplication() {
        let v = Vec4(1, 2, 3, 4)
        let result = v * 2
        XCTAssertEqual(result, Vec4(2, 4, 6, 8))
    }
}
