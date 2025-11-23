import Foundation

public struct AABB: Equatable {
    public var min: Vec3
    public var max: Vec3
    
    public static let zero = AABB(
        min: .zero,
        max: .zero
    )
    
    public init(min: Vec3, max: Vec3) {
        self.min = min
        self.max = max
    }
    
    public var center: Vec3 {
        return (min + max) * 0.5
    }
    
    public var size: Vec3 {
        return max - min
    }
    
    public static func fromPoints(_ points: [Vec3]) -> AABB {
        guard !points.isEmpty else { return .zero }
        
        var minPoint = points[0]
        var maxPoint = points[0]
        
        for point in points {
            minPoint.x = Swift.min(minPoint.x, point.x)
            minPoint.y = Swift.min(minPoint.y, point.y)
            minPoint.z = Swift.min(minPoint.z, point.z)
            
            maxPoint.x = Swift.max(maxPoint.x, point.x)
            maxPoint.y = Swift.max(maxPoint.y, point.y)
            maxPoint.z = Swift.max(maxPoint.z, point.z)
        }
        
        return AABB(min: minPoint, max: maxPoint)
    }
}
