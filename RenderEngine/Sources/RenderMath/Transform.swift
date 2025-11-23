import Foundation

public struct Transform {
    public var position: Vec3
    public var rotation: Quaternion
    public var scale: Vec3
    
    public init(position: Vec3 = .zero,
                rotation: Quaternion = .identity,
                scale: Vec3 = .one) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
    
    public var modelMatrix: Mat4 {
        let translationMatrix = Mat4.translation(position)
        let rotationMatrix = rotation.toMat4()
        let scaleMatrix = Mat4.scale(scale)
        
        return translationMatrix * rotationMatrix * scaleMatrix
    }
}
