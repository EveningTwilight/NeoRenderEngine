import Foundation
import simd

public struct Vec4: Equatable, Hashable {
    internal var storage: SIMD4<Float>
    
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
    
    public var w: Float {
        get { storage.w }
        set { storage.w = newValue }
    }
    
    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.storage = SIMD4<Float>(x, y, z, w)
    }
    
    public init(x: Float, y: Float, z: Float, w: Float) {
        self.storage = SIMD4<Float>(x, y, z, w)
    }
    
    internal init(storage: SIMD4<Float>) {
        self.storage = storage
    }
    
    public static let zero = Vec4(0, 0, 0, 0)
    public static let one = Vec4(1, 1, 1, 1)
    
    public static func + (lhs: Vec4, rhs: Vec4) -> Vec4 {
        return Vec4(storage: lhs.storage + rhs.storage)
    }
    
    public static func - (lhs: Vec4, rhs: Vec4) -> Vec4 {
        return Vec4(storage: lhs.storage - rhs.storage)
    }
    
    public static func * (lhs: Vec4, rhs: Float) -> Vec4 {
        return Vec4(storage: lhs.storage * rhs)
    }
}
