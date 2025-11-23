import Foundation
import RenderMath

public protocol Camera: AnyObject {
    var position: Vec3 { get set }
    var target: Vec3 { get set }
    var up: Vec3 { get set }
    
    var viewMatrix: Mat4 { get }
    var projectionMatrix: Mat4 { get }
    
    func updateAspectRatio(_ aspectRatio: Float)
}

public class PerspectiveCamera: Camera {
    public var position: Vec3
    public var target: Vec3
    public var up: Vec3
    
    public var fovRadians: Float
    public var aspectRatio: Float
    public var near: Float
    public var far: Float
    
    public init(position: Vec3 = Vec3(0, 0, 5), 
                target: Vec3 = Vec3(0, 0, 0), 
                up: Vec3 = Vec3(0, 1, 0), 
                fovRadians: Float = Float.pi / 3, 
                aspectRatio: Float = 1.0, 
                near: Float = 0.1, 
                far: Float = 100.0) {
        self.position = position
        self.target = target
        self.up = up
        self.fovRadians = fovRadians
        self.aspectRatio = aspectRatio
        self.near = near
        self.far = far
    }
    
    public var viewMatrix: Mat4 {
        return Mat4.lookAt(eye: position, center: target, up: up)
    }
    
    public var projectionMatrix: Mat4 {
        return Mat4.perspective(fovRadians: fovRadians, aspectRatio: aspectRatio, near: near, far: far)
    }
    
    public func updateAspectRatio(_ aspectRatio: Float) {
        self.aspectRatio = aspectRatio
    }
}
