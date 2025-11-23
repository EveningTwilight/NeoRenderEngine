import Foundation
import Metal
import RenderCore

public class MetalShader: ShaderProgram {
    public let vertexFunction: MTLFunction
    public let fragmentFunction: MTLFunction?
    public let library: MTLLibrary?
    public var label: String?

    init(vertex: MTLFunction, fragment: MTLFunction?, library: MTLLibrary?, label: String?) {
        self.vertexFunction = vertex
        self.fragmentFunction = fragment
        self.library = library
        self.label = label
    }
}
