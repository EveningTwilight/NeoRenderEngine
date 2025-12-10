# Testing on iOS

Since the OpenGL ES 2.0 backend is now restricted to iOS, you must run the unit tests on an iOS Simulator or a physical iOS device to verify the OpenGL functionality.

## Prerequisites

- Xcode installed on your Mac.
- An iOS Simulator (e.g., iPhone 15) or a connected iOS device.

## Running Tests via Command Line (xcodebuild)

You can use `xcodebuild` to run tests on a simulator.

1. **List available destinations:**

    ```bash
    xcodebuild -scheme RenderEngine -showdestinations
    ```

    Look for a destination that matches an iOS Simulator, for example: `platform=iOS Simulator,name=iPhone 15,OS=17.0`.

2. **Run the tests:**

    Replace the `destination` string with one found in the previous step.

    ```bash
    xcodebuild test \
        -scheme RenderEngine \
        -destination 'platform=iOS Simulator,name=iPhone 15'
    ```

## Running Tests via Xcode

1. Open the `RenderEngine` folder in Xcode (or open `Package.swift`).
2. Select the `RenderEngine` scheme.
3. Select an iOS Simulator or Device as the run destination.
4. Press `Cmd+U` to run the tests.

## Verifying OpenGL Support

The `GraphicEngineTests.swift` file contains a test `testGLInitialization`.

- On **macOS**, this test expects initialization to **fail** (throw an error).
- On **iOS**, this test expects initialization to **succeed**.

If you run the tests on iOS and `testGLInitialization` fails, it means the OpenGL context could not be created or the conditional compilation flags are not working as expected.
