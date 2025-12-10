import XCTest
@testable import RenderEngine
@testable import RenderCore
@testable import RenderMath

final class SceneGraphTests: XCTestCase {
    
    func testNodeHierarchy() {
        let root = Node(name: "Root")
        let child = Node(name: "Child")
        
        root.addChild(child)
        
        XCTAssertEqual(root.children.count, 1)
        XCTAssertTrue(root.children.first === child)
        XCTAssertTrue(child.parent === root)
        
        child.removeFromParent()
        XCTAssertEqual(root.children.count, 0)
        XCTAssertNil(child.parent)
    }
    
    func testTransformPropagation() {
        let root = Node(name: "Root")
        root.transform.position = Vec3(1, 0, 0)
        
        let child = Node(name: "Child")
        child.transform.position = Vec3(0, 1, 0)
        
        root.addChild(child)
        
        // Child world position should be (1, 1, 0)
        let worldPos = child.worldPosition
        XCTAssertEqual(worldPos.x, 1, accuracy: 0.0001)
        XCTAssertEqual(worldPos.y, 1, accuracy: 0.0001)
        XCTAssertEqual(worldPos.z, 0, accuracy: 0.0001)
    }
    
    func testComponentSystem() {
        let device = MockRenderDevice()
        let node = Node(name: "Entity")
        let mesh = Mesh(device: device, vertices: [0,0,0], indices: [], vertexDescriptor: nil)
        let material = Material(pipelineState: MockPipelineState(descriptor: PipelineDescriptor(label: "Test")))
        
        let renderer = MeshRenderer(mesh: mesh, material: material)
        node.addComponent(renderer)
        
        XCTAssertEqual(node.components.count, 1)
        XCTAssertTrue(node.getComponent(MeshRenderer.self) === renderer)
        
        node.removeComponent(renderer)
        XCTAssertEqual(node.components.count, 0)
    }
    
    func testCameraComponentSync() {
        let node = Node(name: "CameraNode")
        node.transform.position = Vec3(0, 5, 0)
        // Rotate 90 degrees around X (look down)
        // Euler angles in Quaternion init are usually (pitch, yaw, roll) or similar.
        // Let's just check position sync first.
        
        let camera = PerspectiveCamera()
        let camComp = CameraComponent(camera: camera)
        node.addComponent(camComp)
        
        // Update should sync
        node.update(deltaTime: 0.016)
        
        XCTAssertEqual(camera.position.y, 5, accuracy: 0.0001)
    }
}
