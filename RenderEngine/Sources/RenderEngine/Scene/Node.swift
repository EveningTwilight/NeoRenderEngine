import Foundation
import RenderMath

public class Node {
    public var name: String
    public var transform: Transform
    
    public weak var parent: Node?
    public private(set) var children: [Node] = []
    public private(set) var components: [Component] = []
    
    public init(name: String = "Node") {
        self.name = name
        self.transform = Transform()
    }
    
    // MARK: - Hierarchy
    
    public func addChild(_ child: Node) {
        if child.parent === self { return }
        child.removeFromParent()
        child.parent = self
        children.append(child)
    }
    
    public func removeChild(_ child: Node) {
        if let index = children.firstIndex(where: { $0 === child }) {
            child.parent = nil
            children.remove(at: index)
        }
    }
    
    public func removeFromParent() {
        parent?.removeChild(self)
    }
    
    // MARK: - Components
    
    public func addComponent<T: Component>(_ component: T) {
        if component.node != nil {
            print("Warning: Component already attached to a node")
            return
        }
        component.node = self
        components.append(component)
        component.onAttach()
    }
    
    public func getComponent<T: Component>(_ type: T.Type) -> T? {
        return components.first { $0 is T } as? T
    }
    
    public func removeComponent(_ component: Component) {
        if let index = components.firstIndex(where: { $0 === component }) {
            component.onDetach()
            component.node = nil
            components.remove(at: index)
        }
    }
    
    // MARK: - Update
    
    public func update(deltaTime: Double) {
        for component in components {
            component.update(deltaTime: deltaTime)
        }
        
        for child in children {
            child.update(deltaTime: deltaTime)
        }
    }
    
    // MARK: - Transform Helpers
    
    public var worldMatrix: Mat4 {
        if let parent = parent {
            return parent.worldMatrix * transform.modelMatrix
        }
        return transform.modelMatrix
    }
    
    public var worldPosition: Vec3 {
        return worldMatrix.position
    }
}
