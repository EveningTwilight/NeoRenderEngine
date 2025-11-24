import Foundation
import RenderCore

public class Mesh {
    public let vertexBuffer: Buffer
    public let indexBuffer: Buffer?
    public let indexCount: Int
    public let indexType: IndexType
    public let vertexDescriptor: VertexDescriptor?
    
    public init(device: RenderDevice, 
                vertices: [Float], 
                indices: [UInt16]? = nil, 
                vertexDescriptor: VertexDescriptor? = nil) {
        
        // Create Vertex Buffer
        let vSize = vertices.count * MemoryLayout<Float>.size
        self.vertexBuffer = device.makeBuffer(length: vSize)
        let vPtr = self.vertexBuffer.contents()
        vertices.withUnsafeBytes {
            vPtr.copyMemory(from: $0.baseAddress!, byteCount: vSize)
        }
        
        self.vertexDescriptor = vertexDescriptor
        
        // Create Index Buffer if indices provided
        if let indices = indices {
            let iSize = indices.count * MemoryLayout<UInt16>.size
            self.indexBuffer = device.makeBuffer(length: iSize)
            let iPtr = self.indexBuffer!.contents()
            indices.withUnsafeBytes {
                iPtr.copyMemory(from: $0.baseAddress!, byteCount: iSize)
            }
            self.indexCount = indices.count
            self.indexType = .uint16
        } else {
            self.indexBuffer = nil
            self.indexCount = 0 // Or vertex count if we supported non-indexed drawing
            self.indexType = .uint16 // Default
        }
    }
}
