import XCTest
@testable import RenderMath

final class QuaternionTests: XCTestCase {
    func testIdentity() {
        let q = Quaternion.identity
        XCTAssertEqual(q.x, 0)
        XCTAssertEqual(q.y, 0)
        XCTAssertEqual(q.z, 0)
        XCTAssertEqual(q.w, 1)
    }
    
    func testEulerAngles() {
        // Rotate 90 degrees around X axis
        let euler = Vec3(Float.pi / 2, 0, 0)
        let q = Quaternion(eulerAngles: euler)
        
        // Expected: x = sin(45), w = cos(45)
        let val = sin(Float.pi / 4)
        XCTAssertEqual(q.x, val, accuracy: 0.0001)
        XCTAssertEqual(q.y, 0, accuracy: 0.0001)
        XCTAssertEqual(q.z, 0, accuracy: 0.0001)
        XCTAssertEqual(q.w, val, accuracy: 0.0001)
    }
    
    func testMultiplication() {
        // Rotate 90 deg around X
        let q1 = Quaternion(eulerAngles: Vec3(Float.pi / 2, 0, 0))
        // Rotate 90 deg around Y
        let q2 = Quaternion(eulerAngles: Vec3(0, Float.pi / 2, 0))
        
        let q3 = q1 * q2
        // Result should be a combined rotation
        // Just checking it's not identity and is normalized
        XCTAssertNotEqual(q3, Quaternion.identity)
        
        let len = sqrt(q3.x*q3.x + q3.y*q3.y + q3.z*q3.z + q3.w*q3.w)
        XCTAssertEqual(len, 1.0, accuracy: 0.0001)
    }
    
    func testSlerp() {
        let q1 = Quaternion.identity
        // Rotate 180 degrees around X
        let q2 = Quaternion(x: 1, y: 0, z: 0, w: 0) 
        
        let mid = Quaternion.slerp(q1, q2, t: 0.5)
        
        // Midpoint should be 90 degrees around X
        // x = sin(45), w = cos(45)
        let val = sin(Float.pi / 4)
        XCTAssertEqual(mid.x, val, accuracy: 0.0001)
        XCTAssertEqual(mid.w, val, accuracy: 0.0001)
    }
}
