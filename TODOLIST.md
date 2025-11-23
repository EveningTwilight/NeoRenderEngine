# 待办事项 (Todo List)

## Phase 1: 基础架构搭建 (Infrastructure)
- [ ] **项目初始化**
    - [x] Git 仓库初始化 & 配置 (.gitignore, .gitattributes)
    - [x] 文档创建 (WORKFLOW, FEATURES, TODOLIST)
    - [ ] 创建 RenderEngine SPM 包结构
- [ ] **RenderMath 模块**
    - [ ] 移植/实现 Vec3, Vec4
    - [ ] 移植/实现 Mat4
    - [ ] 单元测试覆盖
- [ ] **RenderCore 模块 (RHI 抽象)**
    - [ ] 定义 RenderDevice 协议
    - [ ] 定义 CommandBuffer/CommandQueue 协议
    - [ ] 定义 Buffer/Texture 协议
    - [ ] 定义 Pipeline/Shader 协议

## Phase 2: 渲染后端实现 (Backends)
- [ ] **RenderMetal 模块**
    - [ ] 实现 MetalDevice
    - [ ] 实现 MetalBuffer/MetalTexture
    - [ ] 实现 MetalCommandQueue
    - [ ] 实现 MetalPipeline
- [ ] **RenderGL 模块**
    - [ ] 实现 GLDevice (ES 2.0)
    - [ ] 实现 GLBuffer/GLTexture
    - [ ] 适配层实现

## Phase 3: 单元测试与稳定性 (Testing & Stability)
- [ ] **RenderMath 测试**
    - [ ] Vec2/Vec3/Vec4 单元测试
    - [ ] Mat4 单元测试
    - [ ] Quaternion 单元测试
    - [ ] Transform 单元测试
- [ ] **RenderCore 测试**
    - [ ] Logger 测试
    - [ ] 基础协议 Mock 测试

## Phase 4: 引擎封装与 Demo (Engine & Demo)
- [ ] **RenderEngine 模块**
    - [ ] 实现 Renderer (渲染循环)
    - [ ] 实现 RenderLayer (UIView/SwiftUI 桥接)
    - [ ] 资源管理器
- [ ] **Demo 工程** (暂缓)
    - [ ] 创建 SwiftUI 工程
    - [ ] 集成 RenderEngine
    - [ ] 绘制第一个三角形 (Hello Triangle)

## Phase 5: 进阶特性 (Advanced)
- [ ] 3D 模型加载 (.obj)
- [ ] 基础光照模型 (Phong/Blinn-Phong)
- [ ] 阴影贴图 (Shadow Mapping)
