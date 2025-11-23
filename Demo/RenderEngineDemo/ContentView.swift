//
//  ContentView.swift
//  RenderEngineDemo
//
//  Created by Ai Deng on 2025/11/22.
//

import SwiftUI
import RenderEngine
import RenderCore
import RenderMath

struct ContentView: View {
    @StateObject private var viewModel = TriangleDemoViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if let engine = viewModel.renderEngine {
                RenderViewRepresentable(engine: engine)
                    .frame(minWidth: 400, minHeight: 400)
            } else {
                Text("Initializing Engine...")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Hello Triangle")
                    .font(.headline)
                Text("RenderEngine Demo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            viewModel.start()
        }
    }
}

class TriangleDemoViewModel: ObservableObject, RenderEngineDelegate {
    @Published var renderEngine: RenderEngine?
    
    private var pipeline: PipelineState?
    private var vertexBuffer: Buffer?
    
    init() {
        do {
            let engine = try RenderEngine(backendType: .metal)
            engine.delegate = self
            self.renderEngine = engine
        } catch {
            print("Failed to init engine: \(error)")
        }
    }
    
    func start() {
        renderEngine?.startRendering()
    }
    
    func renderEngineWillBeginFrame(_ engine: RenderEngine) {
        // Setup resources if needed
        if pipeline == nil {
            setupResources(engine: engine)
        }
        
        // Rendering logic would go here
    }
    
    func renderEngineDidEndFrame(_ engine: RenderEngine) {
    }
    
    private func setupResources(engine: RenderEngine) {
        let device = engine.device
        
        let vertexSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct VertexIn {
            float3 position [[attribute(0)]];
            float4 color [[attribute(1)]];
        };
        
        struct VertexOut {
            float4 position [[position]];
            float4 color;
        };
        
        vertex VertexOut vertex_main(
            const device VertexIn* vertices [[buffer(0)]],
            uint vertexID [[vertex_id]]
        ) {
            VertexOut out;
            out.position = float4(vertices[vertexID].position, 1.0);
            out.color = vertices[vertexID].color;
            return out;
        }
        
        fragment float4 fragment_main(VertexOut in [[stage_in]]) {
            return in.color;
        }
        """
        
        do {
            let shader = try device.makeShaderProgram(source: vertexSource, label: "TriangleShader")
            let descriptor = PipelineDescriptor(
                label: "TrianglePipeline",
                vertexFunction: "vertex_main",
                fragmentFunction: "fragment_main",
                colorPixelFormat: 80 // bgra8Unorm
            )
            self.pipeline = try device.makePipeline(descriptor: descriptor, shader: shader)
            
            // Vertices
            let vertices: [Float] = [
                 0.0,  0.5, 0.0,   1.0, 0.0, 0.0, 1.0,
                -0.5, -0.5, 0.0,   0.0, 1.0, 0.0, 1.0,
                 0.5, -0.5, 0.0,   0.0, 0.0, 1.0, 1.0
            ]
            
            let buffer = device.makeBuffer(length: vertices.count * 4)
            // TODO: Upload data to buffer (Buffer protocol needs upload/map)
            self.vertexBuffer = buffer
            
        } catch {
            print("Failed to setup resources: \(error)")
        }
    }
}
