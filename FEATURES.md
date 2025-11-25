# 功能特性 (Features)

## 1. 核心架构 (RenderCore)
| 特性 | 状态 | 描述 |
| --- | --- | --- |
| RHI 抽象层 | ✅ 已完成 | 定义 Device, Buffer, Texture, Pipeline 等协议 |
| 渲染管线抽象 | ✅ 已完成 | RenderPass, CommandBuffer 抽象 |
| Shader 反射 | 🚧 进行中 | 统一的 Shader 参数反射与绑定机制 |
| Shader 库管理 | 📅 计划中 | 支持 .metallib 加载与管理 |

## 2. 数学库 (RenderMath)
| 特性 | 状态 | 描述 |
| --- | --- | --- |
| 向量 (Vec2, Vec3, Vec4) | ✅ 已完成 | 基于 SIMD 封装 |
| 矩阵 (Mat3, Mat4) | ✅ 已完成 | 常用变换矩阵 |
| 四元数 (Quaternion) | ✅ 已完成 | 旋转表示 |
| 欧拉角 (EulerAngles) | ✅ 已完成 | 角度表示 |

## 3. 渲染后端 (Backends)
| 特性 | Metal | OpenGL ES 2.0 | 描述 |
| --- | --- | --- | --- |
| 基础图元渲染 | ✅ 已完成 | 📅 计划中 | 三角形、线段、点 |
| 纹理支持 | ✅ 已完成 | 📅 计划中 | 2D 纹理加载与采样 |
| 离屏渲染 | ✅ 已完成 | 📅 计划中 | 渲染到纹理 (Shadow Map) |
| 深度/模板测试 | ✅ 已完成 | 📅 计划中 | 深度缓冲与测试支持 |
| 混合模式 (Blend Mode) | 📅 计划中 | 📅 计划中 | |

## 4. 引擎功能 (RenderEngine)
| 特性 | 状态 | 描述 |
| --- | --- | --- |
| 场景图 (Scene Graph) | 📅 计划中 | 节点层级管理 |
| 相机系统 | ✅ 已完成 | 透视/正交相机 |
| 资源管理 | ✅ 已完成 | 纹理、模型、Shader资源的加载与缓存 |
| 阴影映射 (Shadow Mapping) | ✅ 已完成 | 基础 Shadow Map 实现 |
| 渲染循环 | 📅 计划中 | DisplayLink/Timer 驱动 |
| 交互层 | 📅 计划中 | SwiftUI/UIKit/AppKit 桥接 |

## 状态图例
- ✅ 已完成
- 🚧 进行中
- 📅 计划中
- ❌ 不支持
