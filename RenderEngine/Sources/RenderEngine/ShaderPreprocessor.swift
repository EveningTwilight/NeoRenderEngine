import Foundation

public enum ShaderPreprocessorError: Error, Equatable {
    case fileNotFound(String, includedFrom: String)
    case circularDependency(chain: [String])
    case loaderError(String)
    
    public static func == (lhs: ShaderPreprocessorError, rhs: ShaderPreprocessorError) -> Bool {
        switch (lhs, rhs) {
        case (.fileNotFound(let f1, let i1), .fileNotFound(let f2, let i2)):
            return f1 == f2 && i1 == i2
        case (.circularDependency(let c1), .circularDependency(let c2)):
            return c1 == c2
        case (.loaderError(let e1), .loaderError(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

public class ShaderPreprocessor {
    /// Closure to load the content of an included file.
    /// Returns the content string or throws an error.
    public typealias IncludeLoader = (_ fileName: String) throws -> String
    
    private let loader: IncludeLoader
    
    public init(loader: @escaping IncludeLoader) {
        self.loader = loader
    }
    
    public func process(source: String, currentFile: String) throws -> String {
        return try processRecursive(source: source, currentFile: currentFile, visited: [currentFile])
    }
    
    private func processRecursive(source: String, currentFile: String, visited: [String]) throws -> String {
        var processedSource = source
        let includePattern = #"^\s*#include\s+"([^"]+)""#
        let regex = try NSRegularExpression(pattern: includePattern, options: [.anchorsMatchLines])
        
        // We need to process matches in reverse order to not mess up ranges when replacing
        let matches = regex.matches(in: source, options: [], range: NSRange(location: 0, length: source.utf16.count))
        
        for match in matches.reversed() {
            if let range = Range(match.range, in: source),
               let pathRange = Range(match.range(at: 1), in: source) {
                
                let includeFile = String(source[pathRange])
                
                // Check for circular dependency
                if visited.contains(includeFile) {
                    var chain = visited
                    chain.append(includeFile)
                    throw ShaderPreprocessorError.circularDependency(chain: chain)
                }
                
                // Load included content
                let includedContent: String
                do {
                    includedContent = try loader(includeFile)
                } catch {
                    throw ShaderPreprocessorError.fileNotFound(includeFile, includedFrom: currentFile)
                }
                
                // Recursively process the included content
                var newVisited = visited
                newVisited.append(includeFile)
                let processedIncludedContent = try processRecursive(source: includedContent, currentFile: includeFile, visited: newVisited)
                
                // Replace the #include line with the processed content
                // We wrap it in newlines to ensure safety
                processedSource.replaceSubrange(range, with: "\n" + processedIncludedContent + "\n")
            }
        }
        
        return processedSource
    }
}
