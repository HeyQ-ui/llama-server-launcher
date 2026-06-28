[English](./README.md) | 简体中文

# Local Llama API Launcher

一个轻量的 Windows 批处理启动器，用于通过 Intel oneAPI / SYCL 版 `llama.cpp` 启动本地 `llama-server` API。

它面向这样的本地使用场景：

- 从本地 `.gguf` 文件中选择模型
- 选择要运行的 `llama-server` 构建版本
- 选择上下文长度和端口
- 自动加载 Visual Studio 和 oneAPI 环境
- 在启动前显示最终命令

## 功能

主入口文件：

`start-llama-api.bat`

脚本会自动检测：

- `llama.cpp\\build-f16\\bin\\llama-server.exe`
- `llama.cpp\\build\\bin\\llama-server.exe`
- 项目根目录中的本地 `.gguf` 模型

对于本地 SYCL 构建，它会自动加载：

- Visual Studio Developer 环境
- Intel oneAPI `setvars.bat`

如果本地存在对应文件，也支持可选的 speculative decoding 草稿模型参数。

## 项目结构

```text
start-llama-api.bat
tests/start-llama-api-smoke.ps1
docs/superpowers/specs/
llama.cpp/
```

## 用法

在当前目录打开终端，或直接双击：

```bat
start-llama-api.bat
```

然后按菜单选择：

1. 可执行构建版本
2. 模型
3. 上下文长度
4. 端口
5. 是否启用 speculative decoding

脚本会在启动 `llama-server` 之前打印最终解析后的命令。

## 默认运行前提

这个项目默认面向一台已经准备好以下环境的 Windows 机器：

- Visual Studio 2022 C++ 工具链
- Intel oneAPI
- 已编译完成的 SYCL 版 `llama.cpp`
- 已放在本地的 GGUF 模型文件

## 验证

Smoke test：

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\start-llama-api-smoke.ps1
```

测试会验证：

- dry-run 命令解析
- 交互式菜单流程
- speculative decoding 命令构造
- 环境初始化路径

## 说明

- 大模型文件属于本地运行资源，不建议提交到 GitHub。
- 启动器刻意保持为单文件批处理脚本，不额外拆分配置文件。
