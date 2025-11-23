import XCTest
@testable import RenderCore

final class LoggerTests: XCTestCase {
    func testLogLevelComparison() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
    }
    
    func testLoggerAPI() {
        // Just ensure these don't crash
        Logger.minLevel = .debug
        Logger.debug("Debug message")
        Logger.info("Info message")
        Logger.warning("Warning message")
        Logger.error("Error message")
        
        Logger.minLevel = .error
        Logger.debug("Should not print")
        Logger.error("Should print")
    }
}
