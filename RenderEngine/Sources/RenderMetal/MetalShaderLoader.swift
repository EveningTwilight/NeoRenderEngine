import Foundation
import RenderCore

public class MetalShaderLoader: ShaderLoader {
    private let device: MetalDevice

    init(device: MetalDevice) {
        self.device = device
    }

    public func makeShaderProgram(source: String, label: String?) throws -> ShaderProgram {
        return try device.makeShaderProgram(source: source, label: label)
    }
}
