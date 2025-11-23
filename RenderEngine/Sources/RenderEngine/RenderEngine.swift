import Foundation
import RenderCore
import RenderMetal
import RenderGL
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

public protocol RenderEngineDelegate: AnyObject {
    func renderEngineWillBeginFrame(_ engine: RenderEngine)
    func renderEngineDidEndFrame(_ engine: RenderEngine)
}

public class RenderEngine {
    public let device: RenderDevice
    public let backendType: RenderBackendType
    public weak var delegate: RenderEngineDelegate?
    public weak var targetLayer: CALayer?
    
    private var isRunning: Bool = false
    private var preferredFrameRate: Int = 60
    
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
                throw NSError(domain: "RenderEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create Metal device"])
            }
            self.device = d
        case .openGLES2:
            self.device = GLDevice()
        }
    }
    
    public func startRendering() {
        guard !isRunning else { return }
        isRunning = true
        
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
        delegate?.renderEngineWillBeginFrame(self)
        // Actual rendering logic would go here or be triggered by the delegate
        delegate?.renderEngineDidEndFrame(self)
    }
}
