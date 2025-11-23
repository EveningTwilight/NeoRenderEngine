import Foundation
import Metal
import RenderCore
import RenderMath

public class MetalDevice: RenderDevice {
    public let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineCache: PipelineLRUCache
    private let libraryCache: MetalLibraryCache
    
    private static let pipelineCompileQueue = DispatchQueue(label: "com.renderengine.pipeline.compile")

    public init?(preferred: MTLDevice? = MTLCreateSystemDefaultDevice(), pipelineCacheCapacity: Int = 64) {
        guard let d = preferred ?? MTLCreateSystemDefaultDevice(), let q = d.makeCommandQueue() else { return nil }
        self.device = d
        self.commandQueue = q
        self.pipelineCache = PipelineLRUCache(capacity: pipelineCacheCapacity)
        self.libraryCache = MetalLibraryCache(device: d)
    }

    public func makeBuffer(length: Int) -> Buffer {
        let mtlBuffer = device.makeBuffer(length: length, options: [])!
        return MetalBuffer(mtlBuffer)
    }

    public func makeCommandQueue() -> CommandQueue {
        return MetalCommandQueue(commandQueue: commandQueue, device: self)
    }

    public func makeTexture(descriptor: TextureDescriptor) -> Texture {
        let mtlDesc = MTLTextureDescriptor()
        mtlDesc.width = descriptor.width
        mtlDesc.height = descriptor.height
        if let pf = MTLPixelFormat(rawValue: UInt(descriptor.pixelFormat)) {
            mtlDesc.pixelFormat = pf
        } else {
            mtlDesc.pixelFormat = .bgra8Unorm
        }
        mtlDesc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        guard let tex = device.makeTexture(descriptor: mtlDesc) else {
            fatalError("MetalDevice: failed to create MTLTexture")
        }
        return MetalTexture(tex)
    }

    public func makeShaderProgram(source: String, label: String?) throws -> ShaderProgram {
        let library = try device.makeLibrary(source: source, options: nil)
        
        // Simple heuristic: find vertex_main and fragment_main
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        guard let vfn = vertexFunction else {
            throw NSError(domain: "RenderEngineMetal", code: -1, userInfo: [NSLocalizedDescriptionKey: "No vertex_main function found"])
        }
        
        return MetalShader(vertex: vfn, fragment: fragmentFunction, library: library, label: label)
    }

    public func makeShaderLoader() -> ShaderLoader {
        return MetalShaderLoader(device: self)
    }
    
    public func makeDepthStencilState(descriptor: DepthStencilDescriptor) -> DepthStencilState {
        return MetalDepthStencilState(descriptor: descriptor, device: device)
    }
    
    public func loadLibrary(from url: URL) throws -> MTLLibrary {
        return try libraryCache.loadLibrary(from: url)
    }

    public func makePipeline(descriptor: PipelineDescriptor, shader: ShaderProgram) throws -> PipelineState {
        guard let metalShader = shader as? MetalShader else {
            throw NSError(domain: "RenderEngineMetal", code: -2, userInfo: [NSLocalizedDescriptionKey: "ShaderProgram is not MetalShader"])
        }

        if let cached = pipelineCache.get(descriptor) {
            return cached
        }

        let desc = MTLRenderPipelineDescriptor()
        
        // Vertex Function
        if let vname = descriptor.vertexFunction, let lib = metalShader.library, let vfn = lib.makeFunction(name: vname) {
            desc.vertexFunction = vfn
        } else {
            desc.vertexFunction = metalShader.vertexFunction
        }
        
        // Fragment Function
        if let fname = descriptor.fragmentFunction, let lib = metalShader.library, let ffn = lib.makeFunction(name: fname) {
            desc.fragmentFunction = ffn
        } else {
            desc.fragmentFunction = metalShader.fragmentFunction
        }

        guard desc.vertexFunction != nil else {
            throw NSError(domain: "RenderEngineMetal", code: -3, userInfo: [NSLocalizedDescriptionKey: "No vertex function available for pipeline"])
        }

        if let pf = MTLPixelFormat(rawValue: UInt(descriptor.colorPixelFormat)), pf != .invalid {
            desc.colorAttachments[0].pixelFormat = pf
        } else {
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        }
        
        if let dpf = MTLPixelFormat(rawValue: UInt(descriptor.depthPixelFormat)), dpf != .invalid {
            desc.depthAttachmentPixelFormat = dpf
        }

        var pipelineStateResult: MTLRenderPipelineState? = nil
        var pipelineError: Error? = nil
        
        MetalDevice.pipelineCompileQueue.sync {
            do {
                pipelineStateResult = try self.device.makeRenderPipelineState(descriptor: desc)
            } catch {
                pipelineError = error
            }
        }

        if let err = pipelineError { throw err }
        guard let pipeline = pipelineStateResult else {
            throw NSError(domain: "RenderEngineMetal", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unknown error creating pipeline state"])
        }

        let state = MetalPipelineState(descriptor: descriptor, pipelineState: pipeline)
        pipelineCache.insert(descriptor, value: state)
        return state
    }
}
