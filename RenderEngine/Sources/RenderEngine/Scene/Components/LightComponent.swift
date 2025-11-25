import Foundation
import RenderMath

public enum LightType {
    case directional
    case point
    case spot
}

public class LightComponent: Component {
    public var type: LightType
    public var color: Vec3
    public var intensity: Float
    
    // Point/Spot specific
    public var range: Float = 10.0
    
    // Spot specific
    public var innerConeAngle: Float = 0.0
    public var outerConeAngle: Float = 0.0
    
    public init(type: LightType, color: Vec3 = Vec3(1, 1, 1), intensity: Float = 1.0) {
        self.type = type
        self.color = color
        self.intensity = intensity
        super.init()
    }
}
