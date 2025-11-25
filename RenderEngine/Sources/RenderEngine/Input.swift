import Foundation
import RenderMath

public enum InputEvent {
    case touchBegan(position: Vec2)
    case touchMoved(position: Vec2, delta: Vec2)
    case touchEnded(position: Vec2)
    case touchCancelled(position: Vec2)
    
    case mouseBegan(position: Vec2)
    case mouseMoved(position: Vec2, delta: Vec2)
    case mouseEnded(position: Vec2)
    case scroll(delta: Vec2)
}

public protocol InputDelegate: AnyObject {
    func handleInput(_ event: InputEvent)
}
