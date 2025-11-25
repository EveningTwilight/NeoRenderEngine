import Foundation
import RenderMath
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
    
    // MARK: - Input Handling
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        engine?.handleInput(.touchBegan(position: Vec2(Float(location.x), Float(location.y))))
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let prevLocation = touch.previousLocation(in: self)
        let delta = Vec2(Float(location.x - prevLocation.x), Float(location.y - prevLocation.y))
        engine?.handleInput(.touchMoved(position: Vec2(Float(location.x), Float(location.y)), delta: delta))
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        engine?.handleInput(.touchEnded(position: Vec2(Float(location.x), Float(location.y))))
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        engine?.handleInput(.touchCancelled(position: Vec2(Float(location.x), Float(location.y))))
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
    
    // MARK: - Input Handling
    
    public override var acceptsFirstResponder: Bool {
        return true
    }
    
    public override func mouseDown(with event: NSEvent) {
        let location = self.convert(event.locationInWindow, from: nil)
        // Flip Y for macOS
        let y = self.bounds.height - location.y
        engine?.handleInput(.mouseBegan(position: Vec2(Float(location.x), Float(y))))
    }
    
    public override func mouseDragged(with event: NSEvent) {
        let location = self.convert(event.locationInWindow, from: nil)
        let y = self.bounds.height - location.y
        let delta = Vec2(Float(event.deltaX), Float(event.deltaY))
        engine?.handleInput(.mouseMoved(position: Vec2(Float(location.x), Float(y)), delta: delta))
    }
    
    public override func mouseUp(with event: NSEvent) {
        let location = self.convert(event.locationInWindow, from: nil)
        let y = self.bounds.height - location.y
        engine?.handleInput(.mouseEnded(position: Vec2(Float(location.x), Float(y))))
    }
    
    public override func scrollWheel(with event: NSEvent) {
        let delta = Vec2(Float(event.scrollingDeltaX), Float(event.scrollingDeltaY))
        engine?.handleInput(.scroll(delta: delta))
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
