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
    - [x] 限制 OpenGL ES 2.0 仅支持 iOS (移除 macOS 支持)

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
- [x] **RenderEngine 测试**
    - [x] Backend 初始化测试 (Metal/GL)
    - [x] 跨平台编译修复 (macOS/iOS)

## Phase 4: 引擎封装与 Demo (Engine & Demo)
- [x] **RenderEngine 模块**
    - [x] 实现 Mesh 和 Material 抽象
    - [x] 实现 OBJ 模型加载器
    - [x] 实现 Renderer (GraphicEngine 渲染循环)
    - [x] 实现 RenderLayer (RenderView 桥接)
    - [x] 资源管理器 (ResourceManager)
- [x] **Demo 工程**
    - [x] 创建 SwiftUI 工程
    - [x] 集成 RenderEngine
    - [x] 绘制第一个三角形 (Hello Triangle)
    - [x] 绘制 3D 立方体 (Hello Cube)
    - [x] 集成 OBJ 加载演示

## Phase 5: 进阶特性 (Advanced)
- [x] 3D 模型加载 (.obj)
- [x] 基础光照模型 (Phong/Blinn-Phong)
- [x] 交互系统 (Input Handling)
- [x] 摄像机控制 (Camera Controller)
- [x] 阴影贴图 (Shadow Mapping)

## Phase 6: 优化与扩展 (Optimization & Extension)
- [ ] **Shader 系统增强**
    - [x] Shader 反射与自动化绑定 (Reflection & Auto-binding)
    - [x] Shader 库加载 (.metallib) 支持
    - [x] Shader 包含机制 (#include)
- [ ] **渲染质量优化**
    - [x] PCF 柔化阴影
    - [x] 阴影 Bias 自适应
- [x] **场景管理**
    - [x] 场景图 (Scene Graph) 基础节点
    - [x] 组件化架构 (Component System)

