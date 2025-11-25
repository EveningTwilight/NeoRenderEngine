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
        mtlDesc.pixelFormat = convertPixelFormat(descriptor.pixelFormat)
        mtlDesc.usage = convertTextureUsage(descriptor.usage)
        
        // Handle CPU Read/Write access
        if descriptor.usage.contains(.cpuRead) || descriptor.usage.contains(.cpuWrite) {
            #if os(macOS)
            mtlDesc.storageMode = .managed
            #else
            mtlDesc.storageMode = .shared
            #endif
            // print("MetalDevice: Created Managed/Shared Texture")
        } else {
            mtlDesc.storageMode = .private
            // print("MetalDevice: Created Private Texture")
        }
        
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
        if let vname = descriptor.vertexFunction {
            guard let lib = metalShader.library, let vfn = lib.makeFunction(name: vname) else {
                throw NSError(domain: "RenderEngineMetal", code: -5, userInfo: [NSLocalizedDescriptionKey: "Vertex function '\(vname)' not found in shader library"])
            }
            desc.vertexFunction = vfn
        } else {
            desc.vertexFunction = metalShader.vertexFunction
        }
        
        // Fragment Function
        if let fname = descriptor.fragmentFunction {
            guard let lib = metalShader.library, let ffn = lib.makeFunction(name: fname) else {
                throw NSError(domain: "RenderEngineMetal", code: -6, userInfo: [NSLocalizedDescriptionKey: "Fragment function '\(fname)' not found in shader library"])
            }
            desc.fragmentFunction = ffn
        } else {
            desc.fragmentFunction = metalShader.fragmentFunction
        }

        guard desc.vertexFunction != nil else {
            throw NSError(domain: "RenderEngineMetal", code: -3, userInfo: [NSLocalizedDescriptionKey: "No vertex function available for pipeline"])
        }

        desc.colorAttachments[0].pixelFormat = convertPixelFormat(descriptor.colorPixelFormat)
        desc.depthAttachmentPixelFormat = convertPixelFormat(descriptor.depthPixelFormat)

        // Vertex Descriptor Conversion
        if let vd = descriptor.vertexDescriptor {
            let mtlVD = MTLVertexDescriptor()
            
            for (i, attr) in vd.attributes.enumerated() {
                mtlVD.attributes[i].format = convertVertexFormat(attr.format)
                mtlVD.attributes[i].offset = attr.offset
                mtlVD.attributes[i].bufferIndex = attr.bufferIndex
            }
            
            for (i, layout) in vd.layouts.enumerated() {
                mtlVD.layouts[i].stride = layout.stride
                mtlVD.layouts[i].stepFunction = layout.stepFunction == .perVertex ? .perVertex : .perInstance
                mtlVD.layouts[i].stepRate = layout.stepRate
            }
            
            desc.vertexDescriptor = mtlVD
        }

        var pipelineStateResult: MTLRenderPipelineState? = nil
        var reflection: MTLRenderPipelineReflection? = nil
        var pipelineError: Error? = nil
        
        MetalDevice.pipelineCompileQueue.sync {
            do {
                let options: MTLPipelineOption = [.bufferTypeInfo, .argumentInfo]
                pipelineStateResult = try self.device.makeRenderPipelineState(descriptor: desc, options: options, reflection: &reflection)
            } catch {
                pipelineError = error
            }
        }

        if let err = pipelineError { throw err }
        guard let pipeline = pipelineStateResult else {
            throw NSError(domain: "RenderEngineMetal", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unknown error creating pipeline state"])
        }

        let state = MetalPipelineState(descriptor: descriptor, pipelineState: pipeline, reflection: reflection)
        pipelineCache.insert(descriptor, value: state)
        return state
    }
    
    private func convertVertexFormat(_ format: RenderCore.VertexFormat) -> MTLVertexFormat {
        switch format {
        case .float: return .float
        case .float2: return .float2
        case .float3: return .float3
        case .float4: return .float4
        case .uchar4: return .uchar4
        }
    }

    private func convertPixelFormat(_ format: PixelFormat) -> MTLPixelFormat {
        switch format {
        case .bgra8Unorm: return .bgra8Unorm
        case .rgba8Unorm: return .rgba8Unorm
        case .depth32Float: return .depth32Float
        case .invalid: return .invalid
        }
    }
    
    private func convertTextureUsage(_ usage: TextureUsage) -> MTLTextureUsage {
        var mtlUsage: MTLTextureUsage = []
        if usage.contains(.shaderRead) { mtlUsage.insert(.shaderRead) }
        if usage.contains(.shaderWrite) { mtlUsage.insert(.shaderWrite) }
        if usage.contains(.renderTarget) { mtlUsage.insert(.renderTarget) }
        return mtlUsage
    }
}
