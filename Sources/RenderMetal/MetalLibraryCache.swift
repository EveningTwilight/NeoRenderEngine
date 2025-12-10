import Foundation
import Metal

public final class MetalLibraryCache {
    private let device: MTLDevice
    private var cache: [URL: MTLLibrary] = [:]
    private let lock = NSLock()

    public init(device: MTLDevice) {
        self.device = device
    }

    public func loadLibrary(from url: URL) throws -> MTLLibrary {
        lock.lock(); defer { lock.unlock() }
        if let existing = cache[url] { return existing }
        let lib = try device.makeLibrary(URL: url)
        cache[url] = lib
        return lib
    }
}
