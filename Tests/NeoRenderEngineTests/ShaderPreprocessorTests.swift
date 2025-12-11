import XCTest
@testable import NeoRenderEngine

final class ShaderPreprocessorTests: XCTestCase {
    
    func testBasicInclude() throws {
        let files: [String: String] = [
            "main.metal": """
            #include "common.metal"
            void main() {}
            """,
            "common.metal": """
            float commonFunc() { return 1.0; }
            """
        ]
        
        let preprocessor = ShaderPreprocessor { name in
            guard let content = files[name] else {
                throw NSError(domain: "Test", code: 404)
            }
            return content
        }
        
        let result = try preprocessor.process(source: files["main.metal"]!, currentFile: "main.metal")
        
        XCTAssertTrue(result.contains("float commonFunc() { return 1.0; }"))
        XCTAssertTrue(result.contains("void main() {}"))
        XCTAssertFalse(result.contains("#include"))
    }
    
    func testNestedInclude() throws {
        let files: [String: String] = [
            "main.metal": """
            #include "level1.metal"
            """,
            "level1.metal": """
            // Level 1
            #include "level2.metal"
            """,
            "level2.metal": """
            // Level 2
            """
        ]
        
        let preprocessor = ShaderPreprocessor { name in
            guard let content = files[name] else {
                throw NSError(domain: "Test", code: 404)
            }
            return content
        }
        
        let result = try preprocessor.process(source: files["main.metal"]!, currentFile: "main.metal")
        
        XCTAssertTrue(result.contains("// Level 1"))
        XCTAssertTrue(result.contains("// Level 2"))
    }
    
    func testCircularDependency() {
        let files: [String: String] = [
            "A.metal": """
            #include "B.metal"
            """,
            "B.metal": """
            #include "A.metal"
            """
        ]
        
        let preprocessor = ShaderPreprocessor { name in
            guard let content = files[name] else {
                throw NSError(domain: "Test", code: 404)
            }
            return content
        }
        
        XCTAssertThrowsError(try preprocessor.process(source: files["A.metal"]!, currentFile: "A.metal")) { error in
            guard let ppError = error as? ShaderPreprocessorError else {
                XCTFail("Unexpected error type")
                return
            }
            
            if case .circularDependency(let chain) = ppError {
                XCTAssertEqual(chain, ["A.metal", "B.metal", "A.metal"])
            } else {
                XCTFail("Expected circularDependency error")
            }
        }
    }
    
    func testFileNotFound() {
        let source = """
        #include "missing.metal"
        """
        
        let preprocessor = ShaderPreprocessor { _ in
            throw NSError(domain: "Test", code: 404)
        }
        
        XCTAssertThrowsError(try preprocessor.process(source: source, currentFile: "main.metal")) { error in
            guard let ppError = error as? ShaderPreprocessorError else {
                XCTFail("Unexpected error type")
                return
            }
            
            if case .fileNotFound(let file, let from) = ppError {
                XCTAssertEqual(file, "missing.metal")
                XCTAssertEqual(from, "main.metal")
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }
}
