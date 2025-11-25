import Foundation
import RenderCore

public class ResourceManager {
    public let device: RenderDevice
    private let textureLoader: TextureLoader
    
    private var textures: [String: Texture] = [:]
    private var shaders: [String: ShaderProgram] = [:]
    private var pipelines: [String: PipelineState] = [:]
    
    public init(device: RenderDevice) {
        self.device = device
        self.textureLoader = TextureLoader(device: device)
    }
    
    // MARK: - Textures
    
    public func loadTexture(name: String, bundle: Bundle = .main) throws -> Texture {
        if let texture = textures[name] {
            return texture
        }
        
        let texture = try textureLoader.loadTexture(name: name, bundle: bundle)
        textures[name] = texture
        return texture
    }
    
    public func createCheckerboardTexture(name: String, size: Int = 256, segments: Int = 8) throws -> Texture {
        if let texture = textures[name] {
            return texture
        }
        
        let texture = try textureLoader.createCheckerboardTexture(size: size, segments: segments)
        textures[name] = texture
        return texture
    }
    
    public func getTexture(name: String) -> Texture? {
        return textures[name]
    }
    
    public func addTexture(_ texture: Texture, name: String) {
        textures[name] = texture
    }
    
    // MARK: - Shaders
    
    public func createShader(name: String, source: String) throws -> ShaderProgram {
        if let shader = shaders[name] {
            return shader
        }
        
        let shader = try device.makeShaderProgram(source: source, label: name)
        shaders[name] = shader
        return shader
    }
    
    public func loadShader(name: String, fileName: String, bundle: Bundle = .main) throws -> ShaderProgram {
        if let shader = shaders[name] {
            return shader
        }
        
        guard let url = bundle.url(forResource: fileName, withExtension: nil) else {
            throw NSError(domain: "ResourceManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shader file '\(fileName)' not found in bundle"])
        }
        
        // Check extension
        if url.pathExtension == "metallib" {
            let shader = try device.makeShaderProgram(from: url, label: name)
            shaders[name] = shader
            return shader
        } else {
            let source = try String(contentsOf: url, encoding: .utf8)
            return try createShader(name: name, source: source)
        }
    }
    
    public func getShader(name: String) -> ShaderProgram? {
        return shaders[name]
    }
    
    // MARK: - Pipelines
    
    public func createPipeline(name: String, descriptor: PipelineDescriptor, shader: ShaderProgram) throws -> PipelineState {
        if let pipeline = pipelines[name] {
            return pipeline
        }
        
        let pipeline = try device.makePipeline(descriptor: descriptor, shader: shader)
        pipelines[name] = pipeline
        return pipeline
    }
    
    public func getPipeline(name: String) -> PipelineState? {
        return pipelines[name]
    }
}
