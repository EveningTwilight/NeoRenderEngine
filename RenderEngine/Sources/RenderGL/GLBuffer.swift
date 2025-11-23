import Foundation
import RenderCore

public class GLBuffer: Buffer {
    public let length: Int
    
    init(length: Int) {
        self.length = length
    }
}
