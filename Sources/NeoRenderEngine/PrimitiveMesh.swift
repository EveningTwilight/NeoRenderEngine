import Foundation
import RenderCore
import RenderMath

public class PrimitiveMesh {
    
    public static func createPlane(device: RenderDevice, size: Float = 10.0) -> Mesh {
        let s = size / 2.0
        
        // Position (3), Normal (3), UV (2)
        let vertices: [Float] = [
            // Position          // Normal       // UV
            -s, 0,  s,           0, 1, 0,        0, size,
             s, 0,  s,           0, 1, 0,        size, size,
             s, 0, -s,           0, 1, 0,        size, 0,
            -s, 0, -s,           0, 1, 0,        0, 0
        ]
        
        let indices: [UInt16] = [
            0, 1, 2,
            2, 3, 0
        ]
        
        var vertexDescriptor = VertexDescriptor()
        vertexDescriptor.attributes.append(VertexAttribute(format: .float3, offset: 0, bufferIndex: 0))
        vertexDescriptor.attributes.append(VertexAttribute(format: .float3, offset: 12, bufferIndex: 0))
        vertexDescriptor.attributes.append(VertexAttribute(format: .float2, offset: 24, bufferIndex: 0))
        vertexDescriptor.layouts.append(VertexLayout(stride: 32))
        
        return Mesh(device: device, vertices: vertices, indices: indices, vertexDescriptor: vertexDescriptor)
    }
    
    public static func createCube(device: RenderDevice, size: Float = 1.0) -> Mesh {
        let s = size / 2.0
        
        // 24 vertices (4 per face * 6 faces) to support hard edges/normals
        // Position (3), Normal (3), UV (2)
        let vertices: [Float] = [
            // Front Face
            -s, -s,  s,   0, 0, 1,   0, 1,
             s, -s,  s,   0, 0, 1,   1, 1,
             s,  s,  s,   0, 0, 1,   1, 0,
            -s,  s,  s,   0, 0, 1,   0, 0,
            
            // Back Face
             s, -s, -s,   0, 0, -1,  0, 1,
            -s, -s, -s,   0, 0, -1,  1, 1,
            -s,  s, -s,   0, 0, -1,  1, 0,
             s,  s, -s,   0, 0, -1,  0, 0,
            
            // Top Face
            -s,  s,  s,   0, 1, 0,   0, 1,
             s,  s,  s,   0, 1, 0,   1, 1,
             s,  s, -s,   0, 1, 0,   1, 0,
            -s,  s, -s,   0, 1, 0,   0, 0,
            
            // Bottom Face
            -s, -s, -s,   0, -1, 0,  0, 1,
             s, -s, -s,   0, -1, 0,  1, 1,
             s, -s,  s,   0, -1, 0,  1, 0,
            -s, -s,  s,   0, -1, 0,  0, 0,
            
            // Right Face
             s, -s,  s,   1, 0, 0,   0, 1,
             s, -s, -s,   1, 0, 0,   1, 1,
             s,  s, -s,   1, 0, 0,   1, 0,
             s,  s,  s,   1, 0, 0,   0, 0,
            
            // Left Face
            -s, -s, -s,  -1, 0, 0,   0, 1,
            -s, -s,  s,  -1, 0, 0,   1, 1,
            -s,  s,  s,  -1, 0, 0,   1, 0,
            -s,  s, -s,  -1, 0, 0,   0, 0
        ]
        
        let indices: [UInt16] = [
            0, 1, 2, 2, 3, 0,       // Front
            4, 5, 6, 6, 7, 4,       // Back
            8, 9, 10, 10, 11, 8,    // Top
            12, 13, 14, 14, 15, 12, // Bottom
            16, 17, 18, 18, 19, 16, // Right
            20, 21, 22, 22, 23, 20  // Left
        ]
        
        var vertexDescriptor = VertexDescriptor()
        vertexDescriptor.attributes.append(VertexAttribute(format: .float3, offset: 0, bufferIndex: 0))
        vertexDescriptor.attributes.append(VertexAttribute(format: .float3, offset: 12, bufferIndex: 0))
        vertexDescriptor.attributes.append(VertexAttribute(format: .float2, offset: 24, bufferIndex: 0))
        vertexDescriptor.layouts.append(VertexLayout(stride: 32))
        
        return Mesh(device: device, vertices: vertices, indices: indices, vertexDescriptor: vertexDescriptor)
    }
}
