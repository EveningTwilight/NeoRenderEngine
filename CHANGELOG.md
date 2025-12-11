# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-12

### Added
- Initial release of NeoRenderEngine.
- Core RHI abstraction (`RenderCore`).
- Metal backend implementation (`RenderMetal`).
- Basic OpenGL ES 2.0 stub (`RenderGL`).
- Math library (`RenderMath`).
- Scene graph and basic rendering loop.
- Post-processing support.
- Swift Package Manager support.

### Fixed
- Resolved SPM dependency resolution conflicts where Demo/Package.swift interfered with package graph when added as remote dependency.
- Fixed "unexpectedly did not find the new dependency in the package graph" error in Xcode.
- Demo subdirectory can still be used independently while not affecting remote dependency resolution.

### Changed
- Renamed package from `RenderEngine` to `NeoRenderEngine`.
- Restructured repository for root-level SPM support.
