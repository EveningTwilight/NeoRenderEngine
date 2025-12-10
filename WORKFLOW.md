# 开发工作流规范 (Development Workflow)

为了保证 NeoRenderEngine 的代码质量和版本稳定性，所有贡献者请遵循以下工作流规范。

## 1. 分支管理策略 (Branching Model)

本项目采用 **GitHub Flow** 的变体，适应版本发布需求。

### 1.1 核心分支
- **`main`**: 主分支，始终保持**稳定**和**可发布**状态。所有合入 `main` 的代码必须经过测试并通过 Code Review。
- **`develop`**: (可选) 暂不启用。目前采用 Feature Branch -> Main 的轻量级模式。

### 1.2 临时分支
- **`feat/<feature-name>`**: 新功能开发分支。
  - 示例: `feat/bloom-effect`, `feat/video-texture`
- **`fix/<issue-id-or-desc>`**: Bug 修复分支。
  - 示例: `fix/crash-on-ios-15`, `fix/shadow-acne`
- **`docs/<desc>`**: 文档更新分支。

## 2. 开发流程

1.  **拉取分支**:
    ```bash
    git checkout main
    git pull origin main
    git checkout -b feat/my-new-feature
    ```

2.  **提交代码**:
    - **必须**遵循提交信息规范，由 Copilot 辅助生成的提交必须包含标识。
    - 格式: `[Copilot] <type>(<scope>): <description>`
    - 示例: `[Copilot] feat(render): add support for rgba16float textures`

3.  **运行测试**:
    - 在提交 Pull Request 前，必须在本地运行所有单元测试。
    - `swift test`

4.  **提交 Pull Request (PR)**:
    - 将分支推送到远程仓库。
    - 在 GitHub 上创建 PR，目标分支为 `main`。
    - 填写 PR 模板，关联相关的 Issue。
    - 等待 CI 通过（如有）和 Code Review。

5.  **合并**:
    - Review 通过后，使用 "Squash and Merge" 合并到 `main`，保持提交历史整洁。

## 3. 版本发布流程 (Release Process)

当 `main` 分支积累了足够的功能或修复后，进行版本发布。

1.  **准备发布**:
    - 创建 `release/v1.x.x` 分支。
    - 更新 `Package.swift` 中的版本号（如有必要）。
    - 更新 `CHANGELOG.md`。

2.  **打标签 (Tagging)**:
    - 合并 release 分支到 `main`。
    - 打上语义化版本标签:
      ```bash
      git tag -a v1.0.0 -m "Release version 1.0.0"
      git push origin v1.0.0
      ```

3.  **GitHub Release**:
    - 在 GitHub Releases 页面草拟新版本。
    - 选择刚才推送的 Tag。
    - 自动生成 Release Notes。
    - (可选) 上传编译好的 XCFramework 二进制包，供非 SPM 用户使用。

## 4. 持续集成 (CI) 规划

未来将集成 GitHub Actions 自动化以下任务：
- **Build & Test**: 每次 Push 和 PR 时自动编译并运行 `swift test`。
- **Lint**: 使用 SwiftLint 检查代码风格。
- **Release**: 推送 Tag 时自动打包 XCFramework 并发布到 GitHub Releases。

## 5. 问题追踪 (Issue Tracking)
- 使用 GitHub Issues 追踪 Bug 和 Feature Request。
- 使用 Labels 分类 (e.g., `bug`, `enhancement`, `documentation`).
