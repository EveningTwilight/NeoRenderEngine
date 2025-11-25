import SwiftUI
import RenderEngine
import RenderCore
import RenderMath

struct SceneGraphDemoView: View {
    @StateObject private var viewModel = SceneGraphViewModel()
    
    var body: some View {
        ZStack {
            if let engine = viewModel.engine {
                RenderViewRepresentable(engine: engine)
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            Text("Scene Graph Demo")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                            Spacer()
                        }
                        .padding(.top, 50)
                    )
            } else {
                Text("Initializing Scene...")
            }
        }
        .onAppear {
            viewModel.setup()
        }
    }
}

class RotatorComponent: Component {
    var speed: Float = 1.0
    var axis: Vec3 = Vec3(0, 1, 0)
    
    override func update(deltaTime: Double) {
        guard let node = node else { return }
        let rotation = Quaternion(angle: speed * Float(deltaTime), axis: axis)
        node.transform.rotation = rotation * node.transform.rotation
    }
}

class SceneGraphViewModel: ObservableObject {
    @Published var engine: GraphicEngine?
    
    func setup() {
        do {
            // 1. Initialize Engine
            let engine = try GraphicEngine(backendType: .metal)
            
            // 2. Create Scene
            let scene = RenderScene()
            
            // 3. Setup Resources
            let device = engine.device
            let resourceManager = engine.resourceManager
            
            // Load Mesh
            let mesh = try OBJLoader.load(name: "cube", bundle: Bundle.module, device: device)
            
            // Load Shader
            let shaderSource = try loadShaderSource(name: "SimpleShader", ext: "metal")
            let shader = try resourceManager.createShader(name: "SimpleShader", source: shaderSource)
            
            // Create Pipeline
            var pipelineDesc = PipelineDescriptor(label: "SimplePipeline")
            pipelineDesc.vertexFunction = "vertex_main"
            pipelineDesc.fragmentFunction = "fragment_main"
            pipelineDesc.colorPixelFormat = .bgra8Unorm
            pipelineDesc.depthPixelFormat = .depth32Float
            pipelineDesc.vertexDescriptor = mesh.vertexDescriptor
            
            // Define Uniform Bindings (for reflection/auto-binding)
            // Note: In a real app, reflection would handle this, but we define it for clarity if needed.
            // The Material system uses reflection from the PipelineState.
            
            let pipelineState = try resourceManager.createPipeline(name: "SimplePipeline", descriptor: pipelineDesc, shader: shader)
            let material = Material(pipelineState: pipelineState)
            
            // Setup Depth State
            let depthDesc = DepthStencilDescriptor(label: "DepthState", depthCompareFunction: .less, isDepthWriteEnabled: true)
            material.depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
            
            // Load Textures
            let diffuseTexture = try resourceManager.createCheckerboardTexture(name: "Checkerboard")
            material.setTexture(diffuseTexture, for: "diffuseMap")
            
            // Create Specular Map (using a different checkerboard pattern)
            let specularTexture = try resourceManager.createCheckerboardTexture(name: "SpecularMap", size: 256, segments: 4)
            material.setTexture(specularTexture, for: "specularMap")
            
            // Set Static Uniforms
            // material.setValue(Vec4(2.0, 4.0, 2.0, 1.0), for: "lightPos") // Now handled by LightComponent
            // material.setValue(Vec4(1.0, 1.0, 1.0, 1.0), for: "lightColor") // Now handled by LightComponent
            material.setValue(Vec4(1.0, 0.5, 0.31, 1.0), for: "objectColor")
            
            // 4. Build Scene Graph
            
            // Light Node
            let lightNode = Node(name: "Light")
            lightNode.transform.position = Vec3(2.0, 4.0, 2.0)
            let lightComp = LightComponent(type: .point, color: Vec3(1, 1, 1), intensity: 1.0)
            lightNode.addComponent(lightComp)
            
            // Make the light orbit
            let lightRotator = RotatorComponent()
            lightRotator.speed = 0.5
            lightRotator.axis = Vec3(0, 1, 0)
            // To orbit, we need a parent that rotates, or a custom orbiter.
            // RotatorComponent rotates the node itself. If the node is at (0,0,0), it rotates in place.
            // If the node is at (2,4,2), rotating it in place changes its orientation, not position.
            // To orbit, we can attach it to a pivot node.
            
            let lightPivot = Node(name: "LightPivot")
            lightPivot.addComponent(lightRotator)
            lightPivot.addChild(lightNode)
            scene.addNode(lightPivot)
            
            // Cube Node
            let cubeNode = Node(name: "Cube")
            cubeNode.addComponent(MeshRenderer(mesh: mesh, material: material))
            
            // Add Rotator Component
            let rotator = RotatorComponent()
            rotator.speed = 1.0
            rotator.axis = Vec3(0.5, 1.0, 0.0).normalized()
            cubeNode.addComponent(rotator)
            
            scene.addNode(cubeNode)
            
            // Camera Node
            let camera = PerspectiveCamera(position: Vec3(0, 0, 5), target: Vec3(0, 0, 0), up: Vec3(0, 1, 0))
            let cameraNode = Node(name: "Camera")
            cameraNode.addComponent(CameraComponent(camera: camera))
            
            // Add Camera Controller
            let controller = CameraControllerComponent()
            controller.distance = 5.0
            cameraNode.addComponent(controller)
            
            scene.addNode(cameraNode)
            
            // 5. Bind to Engine
            engine.scene = scene
            engine.camera = camera
            
            self.engine = engine
            engine.startRendering()
            
        } catch {
            print("Failed to setup Scene Graph Demo: \(error)")
        }
    }
    
    private func loadShaderSource(name: String, ext: String) throws -> String {
        // Try to find the resource with subdirectory
        if let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Resources/Shaders") {
            return try String(contentsOf: url, encoding: .utf8)
        }
        if let url = Bundle.module.url(forResource: name, withExtension: ext) {
            return try String(contentsOf: url, encoding: .utf8)
        }
        throw NSError(domain: "SceneGraphDemo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shader file '\(name).\(ext)' not found"])
    }
}
