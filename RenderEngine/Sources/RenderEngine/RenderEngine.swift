import Foundation
import RenderCore
import RenderMetal
import RenderGL
import RenderMath
import QuartzCore

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum RenderBackendType {
    case metal
    case openGLES2
}

public protocol RenderEngineDelegate: AnyObject, InputDelegate {
    func update(deltaTime: Double)
    func draw(in engine: GraphicEngine, commandBuffer: CommandBuffer, renderPassDescriptor: RenderPassDescriptor)
}

// Default implementation for InputDelegate to make it optional
public extension RenderEngineDelegate {
    func handleInput(_ event: InputEvent) {}
}

public class GraphicEngine {
    public let device: RenderDevice
    public let backendType: RenderBackendType
    public let resourceManager: ResourceManager
    public weak var delegate: RenderEngineDelegate?
    public weak var targetLayer: CALayer?
    
    // Scene Graph Support
    public var scene: RenderScene?
    public var camera: Camera?
    private lazy var sceneRenderer: SceneRenderer = {
        return SceneRenderer(device: self.device)
    }()
    
    private var isRunning: Bool = false
    private var preferredFrameRate: Int = 60
    private var commandQueue: CommandQueue
    private var depthTexture: Texture?
    private var lastFrameTime: Double = 0
    
    #if os(iOS)
    private var displayLink: CADisplayLink?
    #elseif os(macOS)
    private var timer: Timer?
    #endif
    
    public init(backendType: RenderBackendType) throws {
        self.backendType = backendType
        switch backendType {
        case .metal:
            guard let d = MetalDevice() else {
                throw NSError(domain: "GraphicEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create Metal device"])
            }
            self.device = d
        case .openGLES2:
            #if os(iOS)
            self.device = GLDevice()
            #else
            throw NSError(domain: "GraphicEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenGL ES 2.0 is only supported on iOS"])
            #endif
        }
        self.commandQueue = self.device.makeCommandQueue()
        self.resourceManager = ResourceManager(device: self.device)
    }
    
    public func handleInput(_ event: InputEvent) {
        if let delegate = delegate {
            delegate.handleInput(event)
        } else {
            scene?.handleInput(event)
        }
    }
    
    public func startRendering() {
        guard !isRunning else { return }
        isRunning = true
        lastFrameTime = CFAbsoluteTimeGetCurrent()
        
        #if os(iOS)
        displayLink = CADisplayLink(target: self, selector: #selector(renderFrame))
        displayLink?.preferredFramesPerSecond = preferredFrameRate
        displayLink?.add(to: .main, forMode: .common)
        #elseif os(macOS)
        let interval = 1.0 / Double(preferredFrameRate)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.renderFrame()
        }
        RunLoop.main.add(timer!, forMode: .common)
        #endif
    }
    
    public func stopRendering() {
        guard isRunning else { return }
        isRunning = false
        
        #if os(iOS)
        displayLink?.invalidate()
        displayLink = nil
        #elseif os(macOS)
        timer?.invalidate()
        timer = nil
        #endif
    }
    
    @objc private func renderFrame() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        // 0. Update Logic
        if let delegate = delegate {
            delegate.update(deltaTime: deltaTime)
        } else {
            scene?.update(deltaTime: deltaTime)
        }
        
        var currentTexture: Texture?
        
        // 1. Acquire Drawable
        if backendType == .metal {
             guard let layer = targetLayer as? CAMetalLayer else { return }
             guard let drawable = layer.nextDrawable() else { return }
             currentTexture = MetalTexture(drawable.texture, drawable: drawable)
        } else if backendType == .openGLES2 {
            #if os(iOS)
            // iOS GL context handling would go here (usually via CAEAGLLayer)
            // For now, we assume the context is managed externally or by GLKView
            #endif
        }
        
        guard let texture = currentTexture else { return }
        
        // Create/Update Depth Texture
        if depthTexture == nil || depthTexture!.width != texture.width || depthTexture!.height != texture.height {
            let depthDesc = TextureDescriptor(width: texture.width, height: texture.height, pixelFormat: .depth32Float, usage: [.renderTarget])
            depthTexture = device.makeTexture(descriptor: depthDesc)
        }
        
        // 2. Create RenderPassDescriptor
        let passDescriptor = RenderPassDescriptor(
            colorTargets: [RenderTargetDescriptor(texture: texture, clearColor: Vec4(0, 0, 0, 1))],
            depthTarget: RenderTargetDescriptor(texture: depthTexture!, clearDepth: 1.0)
        )
        
        // Manual Clear for GL (since CommandBuffer ignores descriptor)
        if backendType == .openGLES2 {
            #if os(iOS)
            let c = passDescriptor.colorTargets[0].clearColor ?? Vec4(0, 0, 0, 1)
            glClearColor(GLclampf(c.x), GLclampf(c.y), GLclampf(c.z), GLclampf(c.w))
            glClearDepthf(GLclampf(passDescriptor.depthTarget?.clearDepth ?? 1.0))
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
            #endif
        }
        
        // 3. Create CommandBuffer
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // 4. Draw
        if let delegate = delegate {
            delegate.draw(in: self, commandBuffer: commandBuffer, renderPassDescriptor: passDescriptor)
        } else if let scene = scene, let camera = camera {
            sceneRenderer.render(scene: scene, camera: camera, in: commandBuffer, passDescriptor: passDescriptor)
        }
        
        // 5. Present and Commit
        commandBuffer.present(texture)
        commandBuffer.commit()
    }
}
