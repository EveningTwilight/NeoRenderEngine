import Foundation
import simd

public struct Vec3: Equatable, Hashable {
    internal var storage: SIMD3<Float>
    
    public var x: Float {
        get { storage.x }
        set { storage.x = newValue }
    }
    
    public var y: Float {
        get { storage.y }
        set { storage.y = newValue }
    }
    
    public var z: Float {
        get { storage.z }
        set { storage.z = newValue }
    }
    
    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.storage = SIMD3<Float>(x, y, z)
    }
    
    public init(x: Float, y: Float, z: Float) {
        self.storage = SIMD3<Float>(x, y, z)
    }
    
    internal init(storage: SIMD3<Float>) {
        self.storage = storage
    }
    
    public static let zero = Vec3(0, 0, 0)
    public static let one = Vec3(1, 1, 1)
    public static let up = Vec3(0, 1, 0)
    public static let down = Vec3(0, -1, 0)
    public static let right = Vec3(1, 0, 0)
    public static let left = Vec3(-1, 0, 0)
    public static let forward = Vec3(0, 0, 1)
    public static let back = Vec3(0, 0, -1)
    
    public var length: Float {
        return sqrt(x*x + y*y + z*z)
    }
    
    public var lengthSquared: Float {
        return x*x + y*y + z*z
    }
    
    public func normalized() -> Vec3 {
        let len = length
        return len > 0 ? Vec3(storage: storage / len) : .zero
    }
    
    public func dot(_ other: Vec3) -> Float {
        return simd_dot(storage, other.storage)
    }
    
    public func cross(_ other: Vec3) -> Vec3 {
        return Vec3(storage: simd_cross(storage, other.storage))
    }
    
    public func distance(to other: Vec3) -> Float {
        return (self - other).length
    }
    
    public func lerp(to other: Vec3, t: Float) -> Vec3 {
        return self + (other - self) * t
    }
    
    public static func + (lhs: Vec3, rhs: Vec3) -> Vec3 {
        return Vec3(storage: lhs.storage + rhs.storage)
    }
    
    public static func - (lhs: Vec3, rhs: Vec3) -> Vec3 {
        return Vec3(storage: lhs.storage - rhs.storage)
    }
    
    public static func * (lhs: Vec3, rhs: Float) -> Vec3 {
        return Vec3(storage: lhs.storage * rhs)
    }
    
    public static func * (lhs: Float, rhs: Vec3) -> Vec3 {
        return Vec3(storage: lhs * rhs.storage)
    }
    
    public static func / (lhs: Vec3, rhs: Float) -> Vec3 {
        return Vec3(storage: lhs.storage / rhs)
    }
    
    public static prefix func - (vector: Vec3) -> Vec3 {
        return Vec3(storage: -vector.storage)
    }
}
