import SwiftUI
import RenderEngine

struct ContentView: View {
    @StateObject private var viewModel = DemoViewModel()

    var body: some View {
        ZStack {
            if let engine = viewModel.engine {
                RenderViewRepresentable(engine: engine)
                    .ignoresSafeArea()
            } else {
                Text("Initializing RenderEngine...")
            }
        }
        .onAppear {
            viewModel.setup()
        }
    }
}

class DemoViewModel: ObservableObject {
    @Published var engine: GraphicEngine?
    private var renderer: RenderEngineDelegate?
    
    func setup() {
        do {
            // Initialize Engine with Metal backend
            let engine = try GraphicEngine(backendType: .openGLES2)
            
            // Create our custom renderer
            let renderer = CubeRenderer()
            engine.delegate = renderer
            
            self.renderer = renderer
            self.engine = engine
            
            // Start the render loop
            engine.startRendering()
        } catch {
            print("Failed to initialize RenderEngine: \(error)")
        }
    }
}
