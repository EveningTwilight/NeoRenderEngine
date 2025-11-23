# 待办事项 (Todo List)

## Phase 1: 基础架构搭建 (Infrastructure)
- [x] **项目初始化**
    - [x] Git 仓库初始化 & 配置 (.gitignore, .gitattributes)
    - [x] 文档创建 (WORKFLOW, FEATURES, TODOLIST)
    - [x] 创建 RenderEngine SPM 包结构
- [x] **RenderMath 模块**
    - [x] 移植/实现 Vec3, Vec4
    - [x] 移植/实现 Mat4
    - [x] 单元测试覆盖
- [x] **RenderCore 模块 (RHI 抽象)**
    - [x] 定义 RenderDevice 协议
    - [x] 定义 CommandBuffer/CommandQueue 协议
    - [x] 定义 Buffer/Texture 协议
    - [x] 定义 Pipeline/Shader 协议

## Phase 2: 渲染后端实现 (Backends)
- [x] **RenderMetal 模块**
    - [x] 实现 MetalDevice
    - [x] 实现 MetalBuffer/MetalTexture
    - [x] 实现 MetalCommandQueue
    - [x] 实现 MetalPipeline
    - [x] 实现 MetalDepthStencilState
    - [x] 实现 Uniform Buffer 绑定 (setFragmentBuffer)
- [x] **RenderGL 模块**
    - [x] 实现 GLDevice (ES 2.0)
    - [x] 实现 GLBuffer/GLTexture
    - [x] 适配层实现

## Phase 3: 单元测试与稳定性 (Testing & Stability)
- [x] **RenderMath 测试**
    - [x] Vec2/Vec3/Vec4 单元测试
    - [x] Mat4 单元测试
    - [x] Quaternion 单元测试
    - [x] Transform 单元测试
- [x] **RenderCore 测试**
    - [x] Logger 测试
    - [x] 基础协议 Mock 测试
    - [x] DepthStencilState 测试

## Phase 4: 引擎封装与 Demo (Engine & Demo)
- [ ] **RenderEngine 模块**
    - [ ] 实现 Renderer (渲染循环)
    - [ ] 实现 RenderLayer (UIView/SwiftUI 桥接)
    - [ ] 资源管理器
- [x] **Demo 工程**
    - [x] 创建 SwiftUI 工程
    - [x] 集成 RenderEngine
    - [x] 绘制第一个三角形 (Hello Triangle)
    - [x] 绘制 3D 立方体 (Hello Cube)

## Phase 5: 进阶特性 (Advanced)
- [ ] 3D 模型加载 (.obj)
- [ ] 基础光照模型 (Phong/Blinn-Phong)
- [ ] 阴影贴图 (Shadow Mapping)
