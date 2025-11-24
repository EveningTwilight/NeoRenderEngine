import Foundation
import RenderCore
import RenderMetal
import RenderGL

#if os(iOS)
import UIKit
import SwiftUI

// MARK: - Internal Backend Views

private class MetalView: UIView {
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
}

private class GLView: UIView {
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
}

// MARK: - Public RenderView

public class RenderView: UIView {
    public var engine: GraphicEngine? {
        didSet {
            setupBackendView()
        }
    }
    
    private var backendView: UIView?
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        backendView?.frame = self.bounds
    }
    
    private func setupBackendView() {
        // Remove existing backend view if any
        backendView?.removeFromSuperview()
        backendView = nil
        
        guard let engine = engine else { return }
        
        let view: UIView
        switch engine.backendType {
        case .metal:
            let mIconView = MetalView()
            if let metalLayer = mIconView.layer as? CAMetalLayer, let metalDevice = engine.device as? MetalDevice {
                metalLayer.device = metalDevice.device
                metalLayer.pixelFormat = .bgra8Unorm
                metalLayer.framebufferOnly = true
            }
            view = mIconView
        case .openGLES2:
            let glView = GLView()
            if let glLayer = glView.layer as? CAEAGLLayer {
                glLayer.isOpaque = true
                glLayer.drawableProperties = [
                    kEAGLDrawablePropertyRetainedBacking: false,
                    kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
                ]
            }
            view = glView
        }
        
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
        self.backendView = view
        
        // Update engine target layer
        engine.targetLayer = view.layer
    }
}

public struct RenderViewRepresentable: UIViewRepresentable {
    let engine: GraphicEngine
    
    public init(engine: GraphicEngine) {
        self.engine = engine
    }
    
    public func makeUIView(context: Context) -> RenderView {
        let view = RenderView()
        view.engine = engine
        return view
    }
    
    public func updateUIView(_ uiView: RenderView, context: Context) {}
}

#elseif os(macOS)
import AppKit
import SwiftUI

public class RenderView: NSView {
    public var engine: GraphicEngine? {
        didSet {
            setupLayer()
        }
    }
    
    public override func makeBackingLayer() -> CALayer {
        return CAMetalLayer()
    }
    
    private func setupLayer() {
        self.wantsLayer = true
        guard let engine = engine else { return }
        
        // macOS currently only supports Metal
        if engine.backendType == .metal {
            if let metalLayer = self.layer as? CAMetalLayer, let metalDevice = engine.device as? MetalDevice {
                metalLayer.device = metalDevice.device
                metalLayer.pixelFormat = .bgra8Unorm
                metalLayer.framebufferOnly = true
                engine.targetLayer = metalLayer
            }
        }
    }
}

public struct RenderViewRepresentable: NSViewRepresentable {
    let engine: GraphicEngine
    
    public init(engine: GraphicEngine) {
        self.engine = engine
    }
    
    public func makeNSView(context: Context) -> RenderView {
        let view = RenderView()
        view.engine = engine
        return view
    }
    
    public func updateNSView(_ nsView: RenderView, context: Context) {}
}
#endif
