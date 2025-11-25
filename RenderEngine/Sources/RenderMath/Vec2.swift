import Foundation
import simd

public struct Vec2: Equatable, Hashable {
    internal var storage: SIMD2<Float>
    
    public var x: Float {
        get { storage.x }
        set { storage.x = newValue }
    }
    
    public var y: Float {
        get { storage.y }
        set { storage.y = newValue }
    }
    
    public init(_ x: Float, _ y: Float) {
        self.storage = SIMD2<Float>(x, y)
    }
    
    public init(x: Float, y: Float) {
        self.storage = SIMD2<Float>(x, y)
    }
    
    internal init(storage: SIMD2<Float>) {
        self.storage = storage
    }
    
    public static let zero = Vec2(0, 0)
    public static let one = Vec2(1, 1)
    
    public var length: Float {
        return sqrt(x*x + y*y)
    }
    
    public func normalized() -> Vec2 {
        let len = length
        return len > 0 ? Vec2(storage: storage / len) : .zero
    }
    
    public static func + (lhs: Vec2, rhs: Vec2) -> Vec2 {
        return Vec2(storage: lhs.storage + rhs.storage)
    }
    
    public static func - (lhs: Vec2, rhs: Vec2) -> Vec2 {
        return Vec2(storage: lhs.storage - rhs.storage)
    }
    
    public static func * (lhs: Vec2, rhs: Float) -> Vec2 {
        return Vec2(storage: lhs.storage * rhs)
    }
    
    public static func * (lhs: Float, rhs: Vec2) -> Vec2 {
        return Vec2(storage: lhs * rhs.storage)
    }
    
    public static func / (lhs: Vec2, rhs: Float) -> Vec2 {
        return Vec2(storage: lhs.storage / rhs)
    }
    
    public func toArray() -> [Float] {
        return [storage.x, storage.y]
    }
}
