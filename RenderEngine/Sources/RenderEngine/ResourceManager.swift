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
    
    public func createProceduralSkybox(name: String, size: Int = 512) throws -> Texture {
        if let texture = textures[name] {
            return texture
        }
        
        let texture = try textureLoader.createProceduralSkybox(size: size)
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
            
            // Preprocess source to handle #include
            let preprocessor = ShaderPreprocessor { includeName in
                // Try to find the included file in the same bundle
                // We assume included files are in the same directory or relative to bundle root
                // For simplicity, we search the bundle for the file name
                // A more robust implementation would handle relative paths based on current file
                
                // 1. Try relative to current file (if we knew the directory, but here we just have fileName)
                // 2. Try bundle resource lookup
                
                // Strategy: Look for resource with the includeName
                
                // Try to find in the same subdirectory if possible, or just flat search
                // Since bundle.url(forResource:...) searches flat by default unless subdirectory is specified
                // We try to be smart: if the original file was in "Shaders/CubeShader.metal", we might want to look in "Shaders/"
                
                var includeURL: URL?
                
                // Try to infer subdirectory from the original fileName
                let originalPath = (fileName as NSString).deletingLastPathComponent
                if !originalPath.isEmpty {
                    includeURL = bundle.url(forResource: includeName, withExtension: nil, subdirectory: originalPath)
                }
                
                if includeURL == nil {
                    includeURL = bundle.url(forResource: includeName, withExtension: nil)
                }
                
                guard let foundURL = includeURL else {
                    throw NSError(domain: "ResourceManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Included file '\(includeName)' not found"])
                }
                
                return try String(contentsOf: foundURL, encoding: .utf8)
            }
            
            let processedSource = try preprocessor.process(source: source, currentFile: fileName)
            return try createShader(name: name, source: processedSource)
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
