import Foundation
import RenderCore

public class GLShaderLoader: ShaderLoader {
    private unowned let device: GLDevice
    
    init(device: GLDevice) {
        self.device = device
    }
    
    public func makeShaderProgram(source: String, label: String?) throws -> ShaderProgram {
        return try device.makeShaderProgram(source: source, label: label)
    }
}
