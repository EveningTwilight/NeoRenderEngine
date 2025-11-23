import Foundation
import RenderCore

public class GLShader: ShaderProgram {
    public let label: String?
    
    init(label: String?) {
        self.label = label
    }
}
