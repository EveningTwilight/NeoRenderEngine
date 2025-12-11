# RenderEngine Demo

This directory contains example code showcasing the capabilities of the NeoRenderEngine.

## How to Use

The Demo examples are provided as reference code that should be integrated directly into your own projects. Since the Demo directory no longer maintains its own Package.swift, you should:

1. Copy the relevant demo source files from `Demo/Sources/RenderDemo/` into your project
2. Add NeoRenderEngine as a dependency in your project's Package.swift
3. Adapt the example code to fit your application's needs

## Example Features Demonstrated

- Initializing `RenderEngine` with Metal backend
- Rendering a simple colored triangle using custom shaders
- Implementing the `RenderEngineDelegate` workflow

Refer to the main project README for information on adding NeoRenderEngine as a dependency.
