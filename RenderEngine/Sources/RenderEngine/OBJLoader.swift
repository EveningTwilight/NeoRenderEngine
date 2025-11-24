import Foundation
import RenderCore
import RenderMath

public class OBJLoader {
    public enum LoaderError: Error {
        case fileNotFound
        case invalidFormat
    }
    
    // Standard Vertex Layout: Position (3) + Normal (3) + UV (2)
    // Stride: 8 * 4 = 32 bytes
    public static func load(name: String, bundle: Bundle = .main, device: RenderDevice) throws -> Mesh {
        guard let url = bundle.url(forResource: name, withExtension: "obj") else {
            throw LoaderError.fileNotFound
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        return parse(content, device: device)
    }
    
    private static func parse(_ content: String, device: RenderDevice) -> Mesh {
        var positions: [Vec3] = []
        var texCoords: [Vec2] = []
        var normals: [Vec3] = []
        
        var finalVertices: [Float] = []
        var finalIndices: [UInt16] = []
        
        // Map "v/vt/vn" string to index in finalVertices
        var indexMap: [String: UInt16] = [:]
        var nextIndex: UInt16 = 0
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard !parts.isEmpty else { continue }
            
            switch parts[0] {
            case "v":
                if parts.count >= 4 {
                    positions.append(Vec3(Float(parts[1])!, Float(parts[2])!, Float(parts[3])!))
                }
            case "vt":
                if parts.count >= 3 {
                    texCoords.append(Vec2(Float(parts[1])!, Float(parts[2])!))
                }
            case "vn":
                if parts.count >= 4 {
                    normals.append(Vec3(Float(parts[1])!, Float(parts[2])!, Float(parts[3])!))
                }
            case "f":
                // Triangulate fan
                for i in 2..<parts.count-1 {
                    let faceIndices = [parts[1], parts[i], parts[i+1]]
                    
                    for faceIndex in faceIndices {
                        if let existingIndex = indexMap[faceIndex] {
                            finalIndices.append(existingIndex)
                        } else {
                            // Parse v/vt/vn
                            let components = faceIndex.components(separatedBy: "/")
                            let vIdx = Int(components[0])! - 1
                            
                            var pos = positions[vIdx]
                            var uv = Vec2(0, 0)
                            var norm = Vec3(0, 0, 0)
                            
                            if components.count > 1 && !components[1].isEmpty {
                                let vtIdx = Int(components[1])! - 1
                                if vtIdx < texCoords.count {
                                    uv = texCoords[vtIdx]
                                    // Flip V coordinate for Metal/GL convention if needed
                                    uv.y = 1.0 - uv.y 
                                }
                            }
                            
                            if components.count > 2 && !components[2].isEmpty {
                                let vnIdx = Int(components[2])! - 1
                                if vnIdx < normals.count {
                                    norm = normals[vnIdx]
                                }
                            }
                            
                            // Append to vertex buffer
                            finalVertices.append(pos.x); finalVertices.append(pos.y); finalVertices.append(pos.z)
                            finalVertices.append(norm.x); finalVertices.append(norm.y); finalVertices.append(norm.z)
                            finalVertices.append(uv.x); finalVertices.append(uv.y)
                            
                            indexMap[faceIndex] = nextIndex
                            finalIndices.append(nextIndex)
                            nextIndex += 1
                        }
                    }
                }
            default:
                continue
            }
        }
        
        // Create Vertex Descriptor
        var vertexDescriptor = VertexDescriptor()
        // Position
        vertexDescriptor.attributes.append(VertexAttribute(format: .float3, offset: 0, bufferIndex: 0))
        // Normal
        vertexDescriptor.attributes.append(VertexAttribute(format: .float3, offset: 12, bufferIndex: 0))
        // UV
        vertexDescriptor.attributes.append(VertexAttribute(format: .float2, offset: 24, bufferIndex: 0))
        
        vertexDescriptor.layouts.append(VertexLayout(stride: 32))
        
        return Mesh(device: device, vertices: finalVertices, indices: finalIndices, vertexDescriptor: vertexDescriptor)
    }
}
