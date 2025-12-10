#if os(iOS)
import Foundation
import RenderCore
import OpenGLES

public class GLShader: ShaderProgram {
    public let label: String?
    public var programID: GLuint = 0
    
    // Cache uniform locations
    private var uniformLocations: [String: GLint] = [:]
    
    init(vertexSource: String, fragmentSource: String, label: String?) throws {
        self.label = label
        self.programID = glCreateProgram()
        
        let vertexShader = try compileShader(source: vertexSource, type: GLenum(GL_VERTEX_SHADER))
        let fragmentShader = try compileShader(source: fragmentSource, type: GLenum(GL_FRAGMENT_SHADER))
        
        glAttachShader(programID, vertexShader)
        glAttachShader(programID, fragmentShader)
        
        // Bind attributes before linking (Convention: 0=position, 1=uv/color)
        glBindAttribLocation(programID, 0, "position")
        glBindAttribLocation(programID, 1, "uv") // or color
        
        glLinkProgram(programID)
        
        var linkStatus: GLint = 0
        glGetProgramiv(programID, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            var infoLog = [GLchar](repeating: 0, count: 512)
            glGetProgramInfoLog(programID, 512, nil, &infoLog)
            let log = String(cString: infoLog)
            glDeleteProgram(programID)
            throw NSError(domain: "GLShader", code: -2, userInfo: [NSLocalizedDescriptionKey: "Program Link Error: \(log)"])
        }
        
        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)
    }
    
    deinit {
        if programID != 0 {
            glDeleteProgram(programID)
        }
    }
    
    public func getUniformLocation(_ name: String) -> GLint {
        if let loc = uniformLocations[name] {
            return loc
        }
        let loc = glGetUniformLocation(programID, name)
        uniformLocations[name] = loc
        return loc
    }
    
    private func compileShader(source: String, type: GLenum) throws -> GLuint {
        let shader = glCreateShader(type)
        var sourceUTF8 = (source as NSString).utf8String
        glShaderSource(shader, 1, &sourceUTF8, nil)
        glCompileShader(shader)
        
        var compileStatus: GLint = 0
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compileStatus)
        if compileStatus == GL_FALSE {
            var infoLog = [GLchar](repeating: 0, count: 512)
            glGetShaderInfoLog(shader, 512, nil, &infoLog)
            let log = String(cString: infoLog)
            glDeleteShader(shader)
            throw NSError(domain: "GLShader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shader Compile Error: \(log)"])
        }
        
        return shader
    }
}
#endif
