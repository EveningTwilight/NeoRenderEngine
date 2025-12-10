import Foundation

public enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }
}

public struct Logger {
    public static var minLevel: LogLevel = .debug
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    public static func debug(_ message: String, tag: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, tag: tag, file: file, function: function, line: line)
    }
    
    public static func info(_ message: String, tag: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, tag: tag, file: file, function: function, line: line)
    }
    
    public static func warning(_ message: String, tag: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, tag: tag, file: file, function: function, line: line)
    }
    
    public static func error(_ message: String, tag: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, tag: tag, file: file, function: function, line: line)
    }
    
    private static func log(_ message: String, level: LogLevel, tag: String?, file: String, function: String, line: Int) {
        guard level >= minLevel else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let threadName = Thread.isMainThread ? "main" : (Thread.current.name ?? String(format: "%p", Thread.current))
        let tagStr = tag != nil ? "[\(tag!)] " : ""
        
        let timestamp = dateFormatter.string(from: Date())
        
        // Format: [TIME] [LEVEL] [Thread] [File:Line] [Tag] Message
        let logMessage = "[\(timestamp)] [\(level.label)] [\(threadName)] [\(fileName):\(line)] \(tagStr)\(message)"
        
        print(logMessage)
    }
}
