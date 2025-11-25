import Foundation
import RenderMath

public class MeshRenderer: Component {
    public var mesh: Mesh
    public var material: Material
    
    public init(mesh: Mesh, material: Material) {
        self.mesh = mesh
        self.material = material
        super.init()
    }
}
