import Foundation
import RenderMath

public class CameraComponent: Component {
    public var camera: Camera
    
    public init(camera: Camera) {
        self.camera = camera
        super.init()
    }
    
    public override func update(deltaTime: Double) {
        guard let node = node else { return }
        
        // Sync Camera with Node Transform
        camera.position = node.worldPosition
        
        // Calculate target based on rotation
        // Assuming standard forward is (0, 0, -1) for looking into the screen in RH system
        // But Vec3.forward is (0, 0, 1).
        // If we use lookAt, we need a target.
        
        // Let's assume the camera looks down its local -Z axis (standard OpenGL/Metal convention for view space)
        // So we rotate (0, 0, -1) by the node's rotation.
        
        let forward = node.transform.rotation * Vec3(0, 0, -1)
        let up = node.transform.rotation * Vec3(0, 1, 0)
        
        camera.target = camera.position + forward
        camera.up = up
    }
}
