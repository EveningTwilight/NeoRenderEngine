import Foundation

open class Component {
    public weak var node: Node?
    
    public init() {}
    
    open func start() {}
    open func update(deltaTime: Double) {}
    open func onAttach() {}
    open func onDetach() {}
}
