import Foundation
import RenderCore

final class PipelineLRUCache {
    private class Node {
        let key: PipelineDescriptor
        var value: MetalPipelineState
        var prev: Node?
        var next: Node?

        init(key: PipelineDescriptor, value: MetalPipelineState) {
            self.key = key
            self.value = value
        }
    }

    private let capacity: Int
    private var map: [PipelineDescriptor: Node] = [:]
    private var head: Node?
    private var tail: Node?
    private let lock = NSLock()

    init(capacity: Int = 64) {
        self.capacity = max(1, capacity)
    }

    func get(_ key: PipelineDescriptor) -> MetalPipelineState? {
        lock.lock(); defer { lock.unlock() }
        guard let node = map[key] else { return nil }
        moveToTail(node)
        return node.value
    }

    func insert(_ key: PipelineDescriptor, value: MetalPipelineState) {
        lock.lock(); defer { lock.unlock() }

        if let node = map[key] {
            node.value = value
            moveToTail(node)
            return
        }

        let node = Node(key: key, value: value)
        map[key] = node
        appendToTail(node)

        if map.count > capacity {
            evictHead()
        }
    }

    private func appendToTail(_ node: Node) {
        if tail == nil {
            head = node
            tail = node
            return
        }
        tail?.next = node
        node.prev = tail
        tail = node
    }

    private func moveToTail(_ node: Node) {
        guard tail !== node else { return }
        let prev = node.prev
        let next = node.next
        if let prev = prev { prev.next = next } else { head = next }
        if let next = next { next.prev = prev } else { tail = prev }
        node.prev = tail
        node.next = nil
        tail?.next = node
        tail = node
    }

    private func evictHead() {
        guard let node = head else { return }
        map.removeValue(forKey: node.key)
        let next = node.next
        next?.prev = nil
        head = next
        if head == nil { tail = nil }
    }
}
