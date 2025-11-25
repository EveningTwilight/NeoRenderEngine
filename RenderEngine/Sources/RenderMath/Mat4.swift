import Foundation
import simd

public struct Mat4: Equatable {
    internal var storage: simd_float4x4
    
    internal init(storage: simd_float4x4) {
        self.storage = storage
    }
    
    public init(array: [Float]) {
        precondition(array.count == 16, "Mat4 requires exactly 16 floats")
        self.storage = simd_float4x4(
            SIMD4(array[0], array[1], array[2], array[3]),
            SIMD4(array[4], array[5], array[6], array[7]),
            SIMD4(array[8], array[9], array[10], array[11]),
            SIMD4(array[12], array[13], array[14], array[15])
        )
    }
    
    public static let identity = Mat4(storage: matrix_identity_float4x4)
    
    public var position: Vec3 {
        return Vec3(storage.columns.3.x, storage.columns.3.y, storage.columns.3.z)
    }
    
    public static func perspective(fovRadians: Float,
                                  aspectRatio: Float,
                                  near: Float,
                                  far: Float) -> Mat4 {
        let ys = 1 / tan(fovRadians * 0.5)
        let xs = ys / aspectRatio
        let zs = far / (near - far)
        
        let matrix = simd_float4x4(
            SIMD4(xs, 0, 0, 0),
            SIMD4(0, ys, 0, 0),
            SIMD4(0, 0, zs, -1),
            SIMD4(0, 0, zs * near, 0)
        )
        
        return Mat4(storage: matrix)
    }
    
    public static func perspectiveGL(fovRadians: Float,
                                   aspectRatio: Float,
                                   near: Float,
                                   far: Float) -> Mat4 {
        let ys = 1 / tan(fovRadians * 0.5)
        let xs = ys / aspectRatio
        let zs = -(far + near) / (far - near)
        let ws = -(2 * far * near) / (far - near)
        
        let matrix = simd_float4x4(
            SIMD4(xs, 0, 0, 0),
            SIMD4(0, ys, 0, 0),
            SIMD4(0, 0, zs, -1),
            SIMD4(0, 0, ws, 0)
        )
        
        return Mat4(storage: matrix)
    }
    
    public static func orthographic(left: Float, right: Float,
                                   bottom: Float, top: Float,
                                   near: Float, far: Float) -> Mat4 {
        let xs = 2 / (right - left)
        let ys = 2 / (top - bottom)
        let zs = 1 / (far - near)
        
        let matrix = simd_float4x4(
            SIMD4(xs, 0, 0, 0),
            SIMD4(0, ys, 0, 0),
            SIMD4(0, 0, zs, 0),
            SIMD4(-(right + left) / (right - left),
                  -(top + bottom) / (top - bottom),
                  -near / (far - near), 1)
        )
        
        return Mat4(storage: matrix)
    }
    
    public static func lookAt(eye: Vec3, center: Vec3, up: Vec3) -> Mat4 {
        let zAxis = (eye - center).normalized()
        let xAxis = up.cross(zAxis).normalized()
        let yAxis = zAxis.cross(xAxis)
        
        let matrix = simd_float4x4(
            SIMD4(xAxis.x, yAxis.x, zAxis.x, 0),
            SIMD4(xAxis.y, yAxis.y, zAxis.y, 0),
            SIMD4(xAxis.z, yAxis.z, zAxis.z, 0),
            SIMD4(-xAxis.dot(eye), -yAxis.dot(eye), -zAxis.dot(eye), 1)
        )
        
        return Mat4(storage: matrix)
    }
    
    public static func translation(_ position: Vec3) -> Mat4 {
        let matrix = simd_float4x4(
            SIMD4(1, 0, 0, 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(0, 0, 1, 0),
            SIMD4(position.x, position.y, position.z, 1)
        )
        return Mat4(storage: matrix)
    }
    
    public static func scale(_ scale: Vec3) -> Mat4 {
        let matrix = simd_float4x4(
            SIMD4(scale.x, 0, 0, 0),
            SIMD4(0, scale.y, 0, 0),
            SIMD4(0, 0, scale.z, 0),
            SIMD4(0, 0, 0, 1)
        )
        return Mat4(storage: matrix)
    }
    
    public static func rotation(angleRadians: Float, axis: Vec3) -> Mat4 {
        let a = axis.normalized()
        let x = a.x, y = a.y, z = a.z
        let c = cos(angleRadians)
        let s = sin(angleRadians)
        let t = 1 - c

        let col0 = SIMD4<Float>(t*x*x + c,    t*x*y + s*z,  t*x*z - s*y, 0)
        let col1 = SIMD4<Float>(t*x*y - s*z,  t*y*y + c,    t*y*z + s*x, 0)
        let col2 = SIMD4<Float>(t*x*z + s*y,  t*y*z - s*x,  t*z*z + c,   0)
        let col3 = SIMD4<Float>(0, 0, 0, 1)

        return Mat4(storage: simd_float4x4(columns: (col0, col1, col2, col3)))
    }
    
    public static func * (lhs: Mat4, rhs: Mat4) -> Mat4 {
        return Mat4(storage: lhs.storage * rhs.storage)
    }
    
    public func toArray() -> [Float] {
        var array = [Float](repeating: 0, count: 16)
        withUnsafePointer(to: storage) { ptr in
            ptr.withMemoryRebound(to: Float.self, capacity: 16) { floatPtr in
                for i in 0..<16 {
                    array[i] = floatPtr[i]
                }
            }
        }
        return array
    }
}
