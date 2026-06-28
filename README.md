# Local Llama API Launcher

A lightweight Windows batch launcher for starting a local `llama-server` API with Intel oneAPI / SYCL builds of `llama.cpp`.

It is designed for a local workflow where we want to:

- choose a model from local `.gguf` files
- choose the `llama-server` build to run
- choose context length and port
- load Visual Studio and oneAPI environments automatically
- keep the final launch command visible before startup

## What It Does

The main entry point is:

`start-llama-api.bat`

The script auto-detects:

- `llama.cpp\\build-f16\\bin\\llama-server.exe`
- `llama.cpp\\build\\bin\\llama-server.exe`
- local `.gguf` models in the project root

For local SYCL builds it loads:

- Visual Studio developer environment
- Intel oneAPI `setvars.bat`

It also supports an optional draft model path for speculative decoding when the required files are present.

## Project Layout

```text
start-llama-api.bat
tests/start-llama-api-smoke.ps1
docs/superpowers/specs/
llama.cpp/
```

## Usage

Open a terminal in this folder or double-click:

```bat
start-llama-api.bat
```

Then choose:

1. executable build
2. model
3. context length
4. port
5. whether to enable speculative decoding

The script prints the resolved command before launching `llama-server`.

## Default Runtime Assumptions

This project targets a local Windows machine with:

- Visual Studio 2022 C++ tools
- Intel oneAPI installed
- a SYCL-capable `llama.cpp` build already compiled
- local GGUF model files already present

## Validation

Smoke test:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\start-llama-api-smoke.ps1
```

The test verifies:

- dry-run command resolution
- interactive menu flow
- speculative decoding command construction
- environment initialization path

## Notes

- Large model files are local runtime assets and are not intended to be committed to GitHub.
- The launcher is intentionally batch-only and keeps configuration in a single script.
