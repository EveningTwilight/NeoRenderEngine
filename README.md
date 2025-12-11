# NeoRenderEngine

![Build Status](https://github.com/EveningTwilight/NeoRenderEngine/actions/workflows/swift.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg)

A lightweight, cross-platform rendering engine abstraction layer (RHI) supporting Metal and OpenGL ES 2.0 (Stub).

## Features

- **RenderCore**: Protocol-based RHI (Render Hardware Interface).
- **RenderMath**: SIMD-based math library (Vec3, Mat4, Quaternion, etc.).
- **RenderMetal**: Metal backend implementation.
- **RenderGL**: OpenGL ES 2.0 backend implementation (Work in Progress).

## Installation

### Swift Package Manager

Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/EveningTwilight/NeoRenderEngine.git", from: "1.0.0")
]
```

And add `NeoRenderEngine` to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "NeoRenderEngine", package: "NeoRenderEngine")
        ]
    )
]
```

## Usage

### Initialization

```swift
import NeoRenderEngine

// Create the graphic engine (automatically chooses Metal on Apple platforms)
let engine = try GraphicEngine(backendType: .metal)

// Access the device
let device = engine.device

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
