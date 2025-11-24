#if os(iOS)
import Foundation
import RenderCore
import OpenGLES

public class GLRenderPassEncoder: RenderPassEncoder {
    private var pipeline: GLPipeline?
    private var depthStencilState: GLDepthStencilState?
    private var vertexBuffers: [Int: (buffer: GLBuffer, offset: Int)] = [:]
    private var fragmentTextures: [Int: GLTexture] = [:]
    
    public init() {}

    public func setViewport(x: Float, y: Float, width: Float, height: Float) {
        glViewport(GLint(x), GLint(y), GLsizei(width), GLsizei(height))
    }

    public func setPipeline(_ pipeline: PipelineState) {
        if let glPipeline = pipeline as? GLPipeline {
            self.pipeline = glPipeline
            glUseProgram(glPipeline.shader.programID)
        }
    }

    public func setDepthStencilState(_ depthStencilState: DepthStencilState) {
        if let glState = depthStencilState as? GLDepthStencilState {
            self.depthStencilState = glState
            if glState.descriptor.isDepthWriteEnabled || glState.descriptor.depthCompareFunction != .always {
                glEnable(GLenum(GL_DEPTH_TEST))
                glDepthFunc(glState.depthFunc)
                glDepthMask(glState.depthMask)
            } else {
                glDisable(GLenum(GL_DEPTH_TEST))
            }
        }
    }

    public func setVertexBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        if let glBuffer = buffer as? GLBuffer {
            vertexBuffers[index] = (glBuffer, offset)
        }
    }

    public func setFragmentBuffer(_ buffer: Buffer, offset: Int, index: Int) {
        if let glBuffer = buffer as? GLBuffer {
            vertexBuffers[index] = (glBuffer, offset)
        }
    }

    public func setFragmentTexture(_ texture: Texture, index: Int) {
        if let glTexture = texture as? GLTexture {
            fragmentTextures[index] = glTexture
        }
    }

    public func drawIndexed(indexCount: Int, indexBuffer: Buffer, indexOffset: Int, indexType: IndexType) {
        guard let pipeline = pipeline else { return }
        
        // 1. Bind Vertex Attributes
        if let vertexDescriptor = pipeline.descriptor.vertexDescriptor {
            for (location, attribute) in vertexDescriptor.attributes.enumerated() {
                if let (buffer, bufferOffset) = vertexBuffers[attribute.bufferIndex], let glBuffer = buffer as? GLBuffer {
                    // Use buffer.bind() to ensure data is uploaded if dirty
                    glBuffer.bind(target: GLenum(GL_ARRAY_BUFFER))
                    
                    let stride = vertexDescriptor.layouts.count > attribute.bufferIndex ? vertexDescriptor.layouts[attribute.bufferIndex].stride : 0
                    
                    let size: GLint
                    switch attribute.format {
                    case .float: size = 1
                    case .float2: size = 2
                    case .float3: size = 3
                    case .float4: size = 4
                    case .uchar4: size = 4
                    }
                    
                    glEnableVertexAttribArray(GLuint(location))
                    
                    let ptrOffset = UnsafeRawPointer(bitPattern: bufferOffset + attribute.offset)
                    glVertexAttribPointer(GLuint(location), size, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(stride), ptrOffset)
                }
            }
        }
        
        // 2. Bind Uniforms
        for binding in pipeline.descriptor.uniformBindings {
            if let (buffer, _) = vertexBuffers[binding.bufferIndex] {
                let ptr = buffer.contents()
                let loc = pipeline.shader.getUniformLocation(binding.name)
                if loc != -1 {
                    switch binding.type {
                    case .mat4:
                        // glUniformMatrix4fv expects UnsafePointer<GLfloat>
                        // ptr is UnsafeMutableRawPointer
                        // We bind it to Float (GLfloat)
                        let floatPtr = ptr.bindMemory(to: Float.self, capacity: 16)
                        // Convert UnsafeMutablePointer to UnsafePointer implicitly or explicitly if needed
                        glUniformMatrix4fv(loc, 1, GLboolean(GL_FALSE), floatPtr)
                    default:
                        break // TODO: Implement other types
                    }
                }
            }
        }
        
        // 3. Bind Textures
        for (index, texture) in fragmentTextures {
            glActiveTexture(GLenum(GL_TEXTURE0 + Int32(index)))
            glBindTexture(GLenum(GL_TEXTURE_2D), texture.textureID)
            
            // Hardcoded uniform name for demo
            let loc = pipeline.shader.getUniformLocation("texture")
            if loc != -1 {
                glUniform1i(loc, GLint(index))
            }
        }
        
        // 4. Draw
        if let glIndexBuffer = indexBuffer as? GLBuffer {
            // Use buffer.bind() to ensure data is uploaded if dirty
            glIndexBuffer.bind(target: GLenum(GL_ELEMENT_ARRAY_BUFFER))
            
            let type = (indexType == .uint16) ? GLenum(GL_UNSIGNED_SHORT) : GLenum(GL_UNSIGNED_INT)
            let ptrOffset = UnsafeRawPointer(bitPattern: indexOffset)
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indexCount), type, ptrOffset)
        }
    }

    public func endEncoding() {
        // Cleanup if needed
    }
}
#endif
