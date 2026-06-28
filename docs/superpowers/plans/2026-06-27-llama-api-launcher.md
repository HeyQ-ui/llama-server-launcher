# Llama API Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight batch launcher that discovers local llama-server builds and GGUF models, loads the correct Windows environments, and starts a local API server with simple menu-driven choices.

**Architecture:** Keep the runtime behavior in a single batch file. Add one small PowerShell smoke test that exercises a hidden non-interactive dry-run path so the launcher can be verified without starting the real server.

**Tech Stack:** Windows batch, PowerShell, Visual Studio `vswhere`, Intel oneAPI `setvars.bat`

---

### Task 1: Write dry-run verification first

**Files:**
- Create: `D:\HEY.Q\models\tests\start-llama-api-smoke.ps1`
- Test: `D:\HEY.Q\models\tests\start-llama-api-smoke.ps1`

- [ ] **Step 1: Write the failing smoke test**

```powershell
$script = Join-Path $PSScriptRoot '..\start-llama-api.bat'
if (-not (Test-Path $script)) {
    throw "Launcher script not found: $script"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File D:\HEY.Q\models\tests\start-llama-api-smoke.ps1`
Expected: FAIL with `Launcher script not found`

- [ ] **Step 3: Expand the smoke test to call dry-run mode**

```powershell
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $script
$psi.Arguments = '--dry-run'
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
```

- [ ] **Step 4: Run test again after implementation**

Run: `powershell -ExecutionPolicy Bypass -File D:\HEY.Q\models\tests\start-llama-api-smoke.ps1`
Expected: PASS and output contains `DRY_RUN_OK`

- [ ] **Step 5: Do not commit**

This workspace is not being committed in this task.

### Task 2: Implement the batch launcher

**Files:**
- Create: `D:\HEY.Q\models\start-llama-api.bat`
- Modify: `D:\HEY.Q\models\tests\start-llama-api-smoke.ps1`

- [ ] **Step 1: Implement path discovery**

Add batch logic that discovers:
- local `build-f16` server
- local `build` server
- optional IPEX server paths
- all `*.gguf` models in `D:\HEY.Q\models`

- [ ] **Step 2: Implement menu selections**

Add numeric prompts for:
- executable variant
- model
- context length
- port
- optional speculative decoding

- [ ] **Step 3: Implement environment bootstrapping**

For SYCL builds:
- resolve `vswhere.exe`
- resolve `VsDevCmd.bat`
- call `VsDevCmd.bat`
- call `setvars.bat`

For IPEX:
- skip external oneAPI initialization

- [ ] **Step 4: Implement dry-run mode**

Add `--dry-run` handling that:
- auto-selects available defaults
- prints resolved command and environment summary
- exits without starting `llama-server`
- emits `DRY_RUN_OK`

- [ ] **Step 5: Run smoke verification**

Run: `powershell -ExecutionPolicy Bypass -File D:\HEY.Q\models\tests\start-llama-api-smoke.ps1`
Expected: PASS with `DRY_RUN_OK`

### Task 3: Review and final verification

**Files:**
- Modify: `D:\HEY.Q\models\start-llama-api.bat`
- Modify: `D:\HEY.Q\models\tests\start-llama-api-smoke.ps1`
- Modify: `D:\HEY.Q\models\docs\superpowers\specs\2026-06-27-llama-api-launcher-design.md`

- [ ] **Step 1: Re-read the spec and compare behavior**

Check that the launcher:
- stays single-file for normal use
- discovers models dynamically
- loads VS Code and oneAPI environment for SYCL builds
- avoids external oneAPI for IPEX

- [ ] **Step 2: Run final verification**

Run: `powershell -ExecutionPolicy Bypass -File D:\HEY.Q\models\tests\start-llama-api-smoke.ps1`
Expected: PASS

- [ ] **Step 3: Record any remaining limitation**

Document that interactive menu flow was smoke-tested through dry-run automation, not by launching the full server process.

- [ ] **Step 4: Do not commit**

This workspace is not being committed in this task.
