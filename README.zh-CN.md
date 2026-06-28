[English](./README.md) | 简体中文

# Local Llama API Launcher

一个用于启动本地 `llama-server` API 的轻量 Windows 启动器，面向 Intel oneAPI / SYCL 版 `llama.cpp`。

它适合这样的桌面使用方式：

- 选择本地 GGUF 模型
- 选择要运行的服务构建版本
- 选择上下文长度和端口
- 自动加载 Visual Studio 和 oneAPI 环境
- 启动本地 OpenAI 兼容 API

## 特点

- 单文件启动器：`start-llama-api.bat`
- 菜单式选择模型和运行时
- 支持本地 `build-f16` 与 `build` 服务二进制
- 本地存在草稿模型时可选 speculative decoding
- 启动前显示最终解析后的命令

## 快速开始

运行：

```bat
start-llama-api.bat
```

然后依次选择：

1. 服务构建版本
2. 模型
3. 上下文长度
4. 端口
5. 是否启用 speculative decoding

## 运行前提

- Windows
- Visual Studio 2022 C++ 工具链
- Intel oneAPI
- 可用的 SYCL 版 `llama.cpp`
- 本地 GGUF 模型文件

## 仓库内容

```text
start-llama-api.bat
tests/start-llama-api-smoke.ps1
docs/superpowers/specs/
docs/superpowers/plans/
```

## 验证

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\start-llama-api-smoke.ps1
```

## 说明

- 大模型文件属于本地运行资源，不纳入版本控制。
- 这个仓库聚焦于启动器本身，不包含 `llama.cpp` 源码或模型权重。
