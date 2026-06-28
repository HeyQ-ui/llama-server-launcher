# Local Llama API Launcher Design

## Goal

Create a lightweight Windows batch launcher at `D:\HEY.Q\models\start-llama-api.bat` for starting a local `llama-server` API with menu-based selection of executable variant, model, context length, port, and optional draft model.

## Constraints

- Keep the solution to a single primary `.bat` file for day-to-day use.
- Use information from the Notion page `llama.cpp 完整部署指南 · Intel Core Ultra 核显版`.
- Load Visual Studio C++ environment and Intel oneAPI environment for local SYCL builds.
- Avoid loading external oneAPI runtime when using an IPEX-LLM portable runtime.
- Auto-discover local `.gguf` models in `D:\HEY.Q\models`.
- Prefer existing local builds:
  - `D:\HEY.Q\models\llama.cpp\build-f16\bin\llama-server.exe`
  - `D:\HEY.Q\models\llama.cpp\build\bin\llama-server.exe`
- Only expose options that are actually available on disk.

## User Experience

- Double-click friendly.
- Numeric menus only.
- Safe defaults:
  - host: `127.0.0.1`
  - port: `8080`
  - gpu layers: `99`
  - contexts: `4096`, `8192`, `16384`
- Print the final resolved command before execution.
- Keep the window open on validation failures.

## Execution Rules

### SYCL local builds

- Resolve Visual Studio environment through `vswhere.exe` when possible.
- Call `VsDevCmd.bat` before `setvars.bat`.
- Set:
  - `ONEAPI_DEVICE_SELECTOR=level_zero:gpu`
  - `SYCL_CACHE_PERSISTENT=1`

### IPEX-LLM runtime

- Set:
  - `SYCL_CACHE_PERSISTENT=1`
- Do not call external `setvars.bat`.

## Optional Features

- Expose speculative decoding only when a draft model exists locally.
- Support a hidden `--dry-run` mode for automated validation without changing the interactive day-to-day workflow.

## Non-Goals

- No separate config file.
- No benchmark-based recommendation engine.
- No free-form advanced parameter builder.
- No dependency on PowerShell UI libraries.

## Verification Note

- Interactive menu behavior is verified through the hidden `--dry-run` path and local smoke test.
- Full runtime validation against a live `llama-server` process is intentionally left as a manual final check, because the launcher is meant to start a long-running local service.
