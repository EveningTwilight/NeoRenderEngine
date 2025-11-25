# RenderEngine

A lightweight, cross-platform rendering engine abstraction layer (RHI) supporting Metal and OpenGL ES 2.0 (Stub).

## Features

- **RenderCore**: Protocol-based RHI (Render Hardware Interface).
- **RenderMath**: SIMD-based math library (Vec3, Mat4, Quaternion, etc.).
- **RenderMetal**: Metal backend implementation.
- **RenderGL**: OpenGL ES 2.0 backend implementation (Work in Progress).

## Usage

### Initialization

```swift
import RenderEngine

// Create a device (automatically chooses Metal on Apple platforms)
guard let device = RenderEngine.makeDevice() else {
    fatalError("Failed to create render device")
}

// Create a command queue
let commandQueue = device.makeCommandQueue()
```

### Pipeline Creation

```swift
let pipelineDescriptor = PipelineDescriptor(
    vertexFunction: "vertex_main",
    fragmentFunction: "fragment_main",
    colorPixelFormat: 80, // .bgra8Unorm
    depthPixelFormat: 252 // .depth32Float
)

let shader = try device.makeShaderProgram(source: shaderSource, label: "MyShader")
let pipeline = try device.makePipeline(descriptor: pipelineDescriptor, shader: shader)
```

### Depth Stencil State

```swift
let depthDescriptor = DepthStencilDescriptor(
    label: "DepthState",
    depthCompareFunction: .less,
    isDepthWriteEnabled: true
)
let depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
```

### Rendering

```swift
let commandBuffer = commandQueue.makeCommandBuffer()
let renderPassDescriptor = RenderPassDescriptor(
    colorTargets: [RenderTargetDescriptor(texture: drawableTexture, clearColor: Vec4(0, 0, 0, 1))],
    depthTarget: RenderTargetDescriptor(texture: depthTexture, clearColor: Vec4(1, 0, 0, 0)) // Clear depth to 1.0
)

let encoder = commandBuffer.beginRenderPass(renderPassDescriptor)
encoder.setPipeline(pipeline)
encoder.setDepthStencilState(depthState)
encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
encoder.drawIndexed(indexCount: indices.count, indexBuffer: indexBuffer, indexOffset: 0, indexType: .uint16)
encoder.endEncoding()

commandBuffer.present(drawableTexture)
commandBuffer.commit()
```

### Scene Graph

The engine provides a simple Node-Component based scene graph.

```swift
// Create a root node
let root = Node(name: "Root")

// Create a child node and attach it
let child = Node(name: "Child")
child.transform.position = Vec3(0, 1, 0)
root.addChild(child)

// Attach components
let meshRenderer = MeshRenderer(mesh: myMesh, material: myMaterial)
child.addComponent(meshRenderer)

// Update the scene (propagates transforms)
root.update(deltaTime: 0.016)
```
