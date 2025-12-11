import SwiftUI
import NeoRenderEngine
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
            
            // Load Meshes
            let cubeMesh = PrimitiveMesh.createCube(device: device, size: 1.0)
            let planeMesh = PrimitiveMesh.createPlane(device: device, size: 10.0)
            
            // Load Shader
            let shaderSource = try loadShaderSource(name: "SimpleShader", ext: "metal")
            let shader = try resourceManager.createShader(name: "SimpleShader", source: shaderSource)
            
            // Create Pipeline
            var pipelineDesc = PipelineDescriptor(label: "SimplePipeline")
            pipelineDesc.vertexFunction = "vertex_main"
            pipelineDesc.fragmentFunction = "fragment_main"
            // Use rgba16Float for HDR rendering to offscreen texture
            pipelineDesc.colorPixelFormat = .rgba16Float
            pipelineDesc.depthPixelFormat = .depth32Float
            pipelineDesc.vertexDescriptor = cubeMesh.vertexDescriptor
            
            let pipelineState = try resourceManager.createPipeline(name: "SimplePipeline", descriptor: pipelineDesc, shader: shader)
            
            // Setup Depth State
            let depthDesc = DepthStencilDescriptor(label: "DepthState", depthCompareFunction: .less, isDepthWriteEnabled: true)
            let depthState = device.makeDepthStencilState(descriptor: depthDesc)
            
            // Load Textures
            let checkerTexture = try resourceManager.createCheckerboardTexture(name: "Checkerboard")
            let specularTexture = try resourceManager.createCheckerboardTexture(name: "SpecularMap", size: 256, segments: 4)
            
            // --- Materials ---
            
            // 1. Floor Material (Matte, Tiled)
            let floorMaterial = Material(pipelineState: pipelineState)
            floorMaterial.depthStencilState = depthState
            floorMaterial.setTexture(checkerTexture, for: "diffuseMap")
            floorMaterial.setTexture(specularTexture, for: "specularMap") // Low specular
            floorMaterial.setValue(Vec4(0.8, 0.8, 0.8, 1.0), for: "objectColor")
            
            // 2. Center Cube Material (Shiny Red)
            let cubeMaterial = Material(pipelineState: pipelineState)
            cubeMaterial.depthStencilState = depthState
            cubeMaterial.setTexture(checkerTexture, for: "diffuseMap")
            cubeMaterial.setTexture(specularTexture, for: "specularMap")
            cubeMaterial.setValue(Vec4(1.0, 0.3, 0.3, 1.0), for: "objectColor")
            
            // 3. Pillar Material (Blueish)
            let pillarMaterial = Material(pipelineState: pipelineState)
            pillarMaterial.depthStencilState = depthState
            pillarMaterial.setTexture(checkerTexture, for: "diffuseMap")
            pillarMaterial.setTexture(specularTexture, for: "specularMap")
            pillarMaterial.setValue(Vec4(0.3, 0.3, 1.0, 1.0), for: "objectColor")
            
            // 4. Build Scene Graph
            
            // Floor
            let floorNode = Node(name: "Floor")
            floorNode.addComponent(MeshRenderer(mesh: planeMesh, material: floorMaterial))
            scene.addNode(floorNode)
            
            // Center Cube
            let cubeNode = Node(name: "CenterCube")
            cubeNode.transform.position = Vec3(0, 1.0, 0) // Lift up
            cubeNode.addComponent(MeshRenderer(mesh: cubeMesh, material: cubeMaterial))
            
            let rotator = RotatorComponent()
            rotator.speed = 1.0
            rotator.axis = Vec3(0.5, 1.0, 0.0).normalized()
            cubeNode.addComponent(rotator)
            scene.addNode(cubeNode)
            
            // Pillars
            let pillarPositions = [
                Vec3(-3, 1, -3),
                Vec3( 3, 1, -3),
                Vec3( 3, 1,  3),
                Vec3(-3, 1,  3)
            ]
            
            for (i, pos) in pillarPositions.enumerated() {
                let pillar = Node(name: "Pillar_\(i)")
                pillar.transform.position = pos
                pillar.transform.scale = Vec3(0.5, 2.0, 0.5)
                pillar.addComponent(MeshRenderer(mesh: cubeMesh, material: pillarMaterial))
                scene.addNode(pillar)
            }
            
            // Light Node
            let lightNode = Node(name: "Light")
            lightNode.transform.position = Vec3(4.0, 5.0, 4.0)
            let lightComp = LightComponent(type: .point, color: Vec3(1, 1, 1), intensity: 1.5)
            lightNode.addComponent(lightComp)
            
            // Make the light orbit
            let lightRotator = RotatorComponent()
            lightRotator.speed = 0.8
            lightRotator.axis = Vec3(0, 1, 0)
            
            let lightPivot = Node(name: "LightPivot")
            lightPivot.addComponent(lightRotator)
            lightPivot.addChild(lightNode)
            scene.addNode(lightPivot)
            
            // Camera Node
            let camera = PerspectiveCamera(position: Vec3(0, 5, 10), target: Vec3(0, 0, 0), up: Vec3(0, 1, 0))
            let cameraNode = Node(name: "Camera")
            cameraNode.addComponent(CameraComponent(camera: camera))
            
            // Add Camera Controller
            let controller = CameraControllerComponent()
            controller.distance = 10.0
            controller.pitch = -0.5 // Look down slightly
            cameraNode.addComponent(controller)
            
            scene.addNode(cameraNode)
            
            // 5. Setup Shadows
            // Load Shadow Shader
            let shadowShaderSource = try loadShaderSource(name: "ShadowShader", ext: "metal")
            let shadowShader = try resourceManager.createShader(name: "ShadowShader", source: shadowShaderSource)
            
            // Create Shadow Pipeline
            var shadowPipelineDesc = PipelineDescriptor(label: "ShadowPipeline")
            shadowPipelineDesc.vertexFunction = "vertex_main"
            shadowPipelineDesc.fragmentFunction = nil 
            shadowPipelineDesc.depthPixelFormat = .depth32Float
            shadowPipelineDesc.vertexDescriptor = cubeMesh.vertexDescriptor // Reuse mesh descriptor
            
            let shadowPipeline = try resourceManager.createPipeline(name: "ShadowPipeline", descriptor: shadowPipelineDesc, shader: shadowShader)
            
            // Create Shadow Map Pass
            let shadowMapPass = ShadowMapPass(device: device, width: 2048, height: 2048)
            
            // Configure SceneRenderer
            engine.sceneRenderer.shadowPipeline = shadowPipeline
            engine.sceneRenderer.shadowMapPass = shadowMapPass
            
            // 6. Setup Skybox
            let skyboxShaderSource = try loadShaderSource(name: "SkyboxShader", ext: "metal")
            let skyboxShader = try resourceManager.createShader(name: "SkyboxShader", source: skyboxShaderSource)
            
            let skyboxTexture = try resourceManager.createProceduralSkybox(name: "Skybox", size: 512)
            let skybox = Skybox(device: device, texture: skyboxTexture)
            
            var skyboxPipelineDesc = PipelineDescriptor(label: "SkyboxPipeline")
            skyboxPipelineDesc.vertexFunction = "vertex_main"
            skyboxPipelineDesc.fragmentFunction = "fragment_main"
            // Use rgba16Float for HDR rendering to offscreen texture
            skyboxPipelineDesc.colorPixelFormat = .rgba16Float
            skyboxPipelineDesc.depthPixelFormat = .depth32Float
            skyboxPipelineDesc.vertexDescriptor = skybox.mesh.vertexDescriptor
            
            let skyboxPipeline = try resourceManager.createPipeline(name: "SkyboxPipeline", descriptor: skyboxPipelineDesc, shader: skyboxShader)
            skybox.pipelineState = skyboxPipeline
            
            engine.sceneRenderer.skybox = skybox
            
            // 7. Setup Post Processing
            let postProcessShaderSource = try loadShaderSource(name: "PostProcess", ext: "metal")
            let postProcessShader = try resourceManager.createShader(name: "PostProcess", source: postProcessShaderSource)
            
            var postProcessPipelineDesc = PipelineDescriptor(label: "PostProcessPipeline")
            postProcessPipelineDesc.vertexFunction = "vertex_post_process"
            postProcessPipelineDesc.fragmentFunction = "fragment_post_process"
            postProcessPipelineDesc.colorPixelFormat = .bgra8Unorm
            postProcessPipelineDesc.depthPixelFormat = .invalid
            postProcessPipelineDesc.vertexDescriptor = engine.postProcessor.quadMesh.vertexDescriptor
            
            let postProcessPipeline = try resourceManager.createPipeline(name: "PostProcessPipeline", descriptor: postProcessPipelineDesc, shader: postProcessShader)
            engine.postProcessor.pipelineState = postProcessPipeline
            
            // Setup Bloom Pipelines
            // 1. Bright Pass
            var brightPipelineDesc = PipelineDescriptor(label: "BrightPipeline")
            brightPipelineDesc.vertexFunction = "vertex_post_process"
            brightPipelineDesc.fragmentFunction = "fragment_bloom"
            brightPipelineDesc.colorPixelFormat = .rgba16Float // Intermediate HDR
            brightPipelineDesc.depthPixelFormat = .invalid
            brightPipelineDesc.vertexDescriptor = engine.postProcessor.quadMesh.vertexDescriptor
            
            let brightPipeline = try resourceManager.createPipeline(name: "BrightPipeline", descriptor: brightPipelineDesc, shader: postProcessShader)
            engine.postProcessor.brightPipeline = brightPipeline
            
            // 2. Blur Pass
            var blurPipelineDesc = PipelineDescriptor(label: "BlurPipeline")
            blurPipelineDesc.vertexFunction = "vertex_post_process"
            blurPipelineDesc.fragmentFunction = "fragment_blur"
            blurPipelineDesc.colorPixelFormat = .rgba16Float // Intermediate HDR
            blurPipelineDesc.depthPixelFormat = .invalid
            blurPipelineDesc.vertexDescriptor = engine.postProcessor.quadMesh.vertexDescriptor
            
            let blurPipeline = try resourceManager.createPipeline(name: "BlurPipeline", descriptor: blurPipelineDesc, shader: postProcessShader)
            engine.postProcessor.blurPipeline = blurPipeline
            
            // 8. Bind to Engine
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
