import SwiftUI
import RenderEngine

@main
struct RenderDemoApp: App {
    init() {
        // Check for headless argument
        if CommandLine.arguments.contains("--headless") {
            print("Running in headless mode...")
            runHeadlessTest()
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
