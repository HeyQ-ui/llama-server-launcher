English | [简体中文](./README.zh-CN.md)

# Local Llama API Launcher

A small Windows launcher for running a local `llama-server` API with Intel oneAPI / SYCL builds of `llama.cpp`.

It is built for a simple desktop workflow:

- choose a local GGUF model
- choose the server build to run
- choose context length and port
- load Visual Studio and oneAPI automatically
- launch a local OpenAI-compatible API

## Highlights

- Single-file launcher: `start-llama-api.bat`
- Menu-based model and runtime selection
- Works with local `build-f16` and `build` server binaries
- Supports optional speculative decoding when a draft model is available
- Prints the resolved launch command before startup

## Quick Start

Run:

```bat
start-llama-api.bat
```

Then choose:

1. server build
2. model
3. context length
4. port
5. whether to enable speculative decoding

## Requirements

- Windows
- Visual Studio 2022 C++ tools
- Intel oneAPI
- a working SYCL build of `llama.cpp`
- local GGUF model files

## Included Files

```text
start-llama-api.bat
tests/start-llama-api-smoke.ps1
docs/superpowers/specs/
docs/superpowers/plans/
```

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\start-llama-api-smoke.ps1
```

## Notes

- Large model files are local runtime assets and are excluded from version control.
- This repository focuses on the launcher itself, not on bundling `llama.cpp` or model weights.
