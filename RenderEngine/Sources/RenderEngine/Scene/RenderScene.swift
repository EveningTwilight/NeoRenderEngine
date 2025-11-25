import Foundation

public class RenderScene {
    public let root: Node
    
    public init() {
        self.root = Node(name: "Root")
    }
    
    public func update(deltaTime: Double) {
        root.update(deltaTime: deltaTime)
    }
    
    public func handleInput(_ event: InputEvent) {
        root.handleInput(event)
    }
    
    public func addNode(_ node: Node) {
        root.addChild(node)
    }
}
