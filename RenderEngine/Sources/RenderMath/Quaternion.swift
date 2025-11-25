import Foundation
import simd

public struct Quaternion: Equatable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float
    
    public static let identity = Quaternion(x: 0, y: 0, z: 0, w: 1)
    
    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    public init(eulerAngles: Vec3) {
        let cx = cos(eulerAngles.x * 0.5)
        let sx = sin(eulerAngles.x * 0.5)
        let cy = cos(eulerAngles.y * 0.5)
        let sy = sin(eulerAngles.y * 0.5)
        let cz = cos(eulerAngles.z * 0.5)
        let sz = sin(eulerAngles.z * 0.5)
        
        self.w = cx * cy * cz + sx * sy * sz
        self.x = sx * cy * cz - cx * sy * sz
        self.y = cx * sy * cz + sx * cy * sz
        self.z = cx * cy * sz - sx * sy * cz
    }
    
    internal func toSIMDMatrix() -> simd_float4x4 {
        let xx = x * x
        let yy = y * y
        let zz = z * z
        let xy = x * y
        let xz = x * z
        let yz = y * z
        let wx = w * x
        let wy = w * y
        let wz = w * z
        
        return simd_float4x4(
            SIMD4(1 - 2*(yy + zz), 2*(xy + wz), 2*(xz - wy), 0),
            SIMD4(2*(xy - wz), 1 - 2*(xx + zz), 2*(yz + wx), 0),
            SIMD4(2*(xz + wy), 2*(yz - wx), 1 - 2*(xx + yy), 0),
            SIMD4(0, 0, 0, 1)
        )
    }
    
    public func toMat4() -> Mat4 {
        return Mat4(storage: toSIMDMatrix())
    }
    
    public static func slerp(_ q1: Quaternion, _ q2: Quaternion, t: Float) -> Quaternion {
        var q2 = q2
        var dot = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w
        
        if dot < 0 {
            q2.x = -q2.x
            q2.y = -q2.y
            q2.z = -q2.z
            q2.w = -q2.w
            dot = -dot
        }
        
        if dot > 0.9995 {
            let result = Quaternion(
                x: q1.x + t * (q2.x - q1.x),
                y: q1.y + t * (q2.y - q1.y),
                z: q1.z + t * (q2.z - q1.z),
                w: q1.w + t * (q2.w - q1.w)
            )
            return result.normalized()
        }
        
        let theta = acos(dot)
        let sinTheta = sin(theta)
        let w1 = sin((1 - t) * theta) / sinTheta
        let w2 = sin(t * theta) / sinTheta
        
        return Quaternion(
            x: w1 * q1.x + w2 * q2.x,
            y: w1 * q1.y + w2 * q2.y,
            z: w1 * q1.z + w2 * q2.z,
            w: w1 * q1.w + w2 * q2.w
        )
    }
    
    public func normalized() -> Quaternion {
        let len = sqrt(x*x + y*y + z*z + w*w)
        if len > 0 {
            return Quaternion(x: x/len, y: y/len, z: z/len, w: w/len)
        }
        return .identity
    }
    
    public static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        return Quaternion(
            x: lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            z: lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
            w: lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
        )
    }
    
    public static func * (lhs: Quaternion, rhs: Vec3) -> Vec3 {
        let qVec = Vec3(lhs.x, lhs.y, lhs.z)
        let uv = qVec.cross(rhs)
        let uuv = qVec.cross(uv)
        
        return rhs + ((uv * lhs.w) + uuv) * 2.0
    }
}
