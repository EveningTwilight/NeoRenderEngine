import Foundation

public protocol ShaderLoader: AnyObject {
    func makeShaderProgram(source: String, label: String?) throws -> ShaderProgram
}
