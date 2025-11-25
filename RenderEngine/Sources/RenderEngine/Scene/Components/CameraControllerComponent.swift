import Foundation
import RenderMath

public class CameraControllerComponent: Component {
    public var distance: Float = 5.0
    public var yaw: Float = 0.0
    public var pitch: Float = 0.0
    public var sensitivity: Float = 0.01
    public var zoomSpeed: Float = 0.1
    
    public override func handleInput(_ event: InputEvent) {
        switch event {
        case .mouseMoved(_, let delta), .touchMoved(_, let delta):
            yaw -= delta.x * sensitivity
            pitch += delta.y * sensitivity
            
            // Clamp pitch to avoid gimbal lock
            let limit = Float.pi / 2.0 - 0.1
            if pitch > limit { pitch = limit }
            if pitch < -limit { pitch = -limit }
            
        case .scroll(let delta):
            distance -= delta.y * zoomSpeed
            if distance < 1.0 { distance = 1.0 }
            if distance > 20.0 { distance = 20.0 }
            
        default:
            break
        }
    }
    
    public override func update(deltaTime: Double) {
        guard let node = node else { return }
        
        // Calculate position based on spherical coordinates
        let x = distance * sin(yaw) * cos(pitch)
        let y = distance * sin(pitch)
        let z = distance * cos(yaw) * cos(pitch)
        
        node.transform.position = Vec3(x, y, z)
        
        // Calculate Rotation from Yaw and Pitch
        // We want the camera to look at the origin.
        // The camera looks down its local -Z axis.
        // So we need to rotate the camera such that its -Z axis points to the origin.
        // This is equivalent to the inverse of the rotation that places the camera at (x,y,z) looking at origin?
        
        // Let's construct the rotation:
        // 1. Rotate around Y by Yaw
        // 2. Rotate around X by Pitch
        // Note: The order depends on how we defined x,y,z above.
        // x = d * sin(yaw) * cos(pitch)
        // z = d * cos(yaw) * cos(pitch)
        // This implies Yaw=0 -> x=0, z=d. (Position is on +Z axis)
        // This matches standard starting position.
        
        // To look at origin from +Z, we need no rotation (if camera looks down -Z? No, if camera looks down -Z, and is at +Z, it looks at origin).
        // So at Yaw=0, Pitch=0, Rotation should be Identity.
        
        // If Yaw increases (positive), x becomes positive. Camera moves to +X.
        // To keep looking at origin, camera must rotate around Y axis (pan right).
        // Actually, if camera moves right, it must turn left to face center.
        // So rotation should be +Yaw around Y?
        
        let qYaw = Quaternion(angle: yaw, axis: Vec3(0, 1, 0))
        let qPitch = Quaternion(angle: -pitch, axis: Vec3(1, 0, 0)) // Pitch up means y increases. Camera needs to look down.
        
        // Combine rotations: Apply Yaw then Pitch (or vice versa depending on frame)
        // Usually for orbit: Yaw (Global Y) * Pitch (Local X)
        node.transform.rotation = qYaw * qPitch
    }
}

extension Quaternion {
    // Removed unused lookAt helper
}
