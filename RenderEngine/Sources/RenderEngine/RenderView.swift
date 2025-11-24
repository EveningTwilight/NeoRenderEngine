import Foundation
import RenderCore
import RenderMetal

#if os(iOS)
import UIKit
import SwiftUI

public class RenderView: UIView {
    public var engine: GraphicEngine? {
        didSet {
            setupLayer()
        }
    }
    
    public override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    private func setupLayer() {
        guard let engine = engine else { return }
        engine.targetLayer = self.layer
        if engine.backendType == .metal {
            if let metalLayer = self.layer as? CAMetalLayer, let metalDevice = engine.device as? MetalDevice {
                metalLayer.device = metalDevice.device
                metalLayer.pixelFormat = .bgra8Unorm
                metalLayer.framebufferOnly = true
            }
        }
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
        engine.targetLayer = self.layer
        if engine.backendType == .metal {
            if let metalLayer = self.layer as? CAMetalLayer, let metalDevice = engine.device as? MetalDevice {
                metalLayer.device = metalDevice.device
                metalLayer.pixelFormat = .bgra8Unorm
                metalLayer.framebufferOnly = true
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
