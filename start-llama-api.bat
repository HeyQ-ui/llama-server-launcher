@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "DRY_RUN=0"
set "MENU_TEST=0"
set "ENV_TEST=0"
if /I "%~1"=="--dry-run" set "DRY_RUN=1"
if /I "%~1"=="--menu-test" set "MENU_TEST=1"
if /I "%~1"=="--env-test" set "ENV_TEST=1"

set "HOST=127.0.0.1"
set "PORT=8080"
set "GPU_LAYERS=99"
set "ONEAPI_SETVARS=C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
set "VSWHERE=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"

call :discover_servers
if errorlevel 1 goto :no_servers

call :discover_models
if errorlevel 1 goto :no_models

:restart
cls
echo ==========================================
echo Local Llama API Launcher
echo Root: %ROOT%
echo ==========================================
echo.

call :choose_server
if errorlevel 1 goto :done

call :choose_model
if errorlevel 1 goto :done

call :choose_context
if errorlevel 1 goto :done

call :choose_port
if errorlevel 1 goto :done

call :choose_speculative
if errorlevel 1 goto :done

call :resolve_environment_paths
call :build_command
call :print_summary

if "%DRY_RUN%"=="1" (
    echo DRY_RUN_OK
    goto :done
)

if "%MENU_TEST%"=="1" (
    echo MENU_TEST_OK
    goto :done
)

call :load_environment
if errorlevel 1 (
    echo.
    echo Environment initialization failed. Returning to menu...
    pause
    goto :restart
)

if "%ENV_TEST%"=="1" (
    echo ENV_TEST_OK
    goto :done
)

echo.
echo Starting llama-server...
echo.
"%SERVER_PATH%" %COMMAND_ARGS%
set "RUN_EXIT=%ERRORLEVEL%"
echo.
echo llama-server exited with code %RUN_EXIT%.
if not "%RUN_EXIT%"=="0" (
    echo.
    echo Startup failed. Review the llama-server log above.
    if "%RUN_EXIT%"=="-1073741819" (
        echo Windows exception: 0xC0000005 access violation.
        echo This usually means the llama-server process crashed inside the backend, driver, or memory allocation path.
        echo Try N for speculative decoding first, then a smaller context such as 4096, then the non-FP16 build.
    )
    if "%SPECULATIVE%"=="1" (
        echo Speculative decoding is enabled; if the draft model tokenizer or build is incompatible, try again and answer N at that prompt.
    )
)
set "PAUSED_ON_EXIT=1"
pause
goto :done

:discover_servers
set "SERVER_COUNT=0"
set "DEFAULT_SERVER_INDEX="

call :add_server "llama.cpp build-f16 (recommended)" "%ROOT%\llama.cpp\build-f16\bin\llama-server.exe" "sycl" "-fa on" "16384"
call :add_server "llama.cpp build" "%ROOT%\llama.cpp\build\bin\llama-server.exe" "sycl" "" "8192"

for /d %%D in ("%ROOT%\llama-cpp-ipex-llm*") do (
    if exist "%%~fD\llama-server.exe" (
        call :add_server "IPEX-LLM runtime (%%~nxD)" "%%~fD\llama-server.exe" "ipex" "" "8192"
    )
)

if not defined DEFAULT_SERVER_INDEX if %SERVER_COUNT% GTR 0 set "DEFAULT_SERVER_INDEX=1"
if %SERVER_COUNT% GTR 0 exit /b 0
exit /b 1

:add_server
set "ADD_NAME=%~1"
set "ADD_PATH=%~2"
set "ADD_KIND=%~3"
set "ADD_EXTRA=%~4"
set "ADD_CTX=%~5"
if not exist "%ADD_PATH%" exit /b 0
set /a SERVER_COUNT+=1
set "SERVER_NAME_!SERVER_COUNT!=%ADD_NAME%"
set "SERVER_PATH_!SERVER_COUNT!=%ADD_PATH%"
set "SERVER_KIND_!SERVER_COUNT!=%ADD_KIND%"
set "SERVER_EXTRA_!SERVER_COUNT!=%ADD_EXTRA%"
set "SERVER_CTX_!SERVER_COUNT!=%ADD_CTX%"
if not defined DEFAULT_SERVER_INDEX set "DEFAULT_SERVER_INDEX=!SERVER_COUNT!"
exit /b 0

:discover_models
set "MODEL_COUNT=0"
set "DEFAULT_MODEL_INDEX="
set "DRAFT_MODEL="

if not exist "%ROOT%\*.gguf" exit /b 1

for %%F in ("%ROOT%\*.gguf") do (
    if exist "%%~fF" (
        set /a MODEL_COUNT+=1
        set "MODEL_NAME_!MODEL_COUNT!=%%~nxF"
        set "MODEL_PATH_!MODEL_COUNT!=%%~fF"
        if /I "%%~nxF"=="Qwen3-0.6B-Q8_0.gguf" set "DRAFT_MODEL=%%~fF"
    )
)

if %MODEL_COUNT% LEQ 0 exit /b 1

for /l %%I in (1,1,%MODEL_COUNT%) do (
    call set "CUR_MODEL=%%MODEL_NAME_%%I%%"
    if not defined DEFAULT_MODEL_INDEX if /I not "%%CUR_MODEL%%"=="Qwen3-0.6B-Q8_0.gguf" set "DEFAULT_MODEL_INDEX=%%I"
)

for /l %%I in (1,1,%MODEL_COUNT%) do (
    call set "CUR_MODEL=%%MODEL_NAME_%%I%%"
    echo %%CUR_MODEL%% | findstr /I /C:"IQ4_NL" >nul
    if not errorlevel 1 set "DEFAULT_MODEL_INDEX=%%I"
)

if not defined DEFAULT_MODEL_INDEX set "DEFAULT_MODEL_INDEX=1"
exit /b 0

:choose_server
if "%DRY_RUN%"=="1" (
    set "SERVER_INDEX=%DEFAULT_SERVER_INDEX%"
    call :apply_server_selection
    exit /b 0
)

:choose_server_prompt
echo Executable:
for /l %%I in (1,1,%SERVER_COUNT%) do (
    call set "SHOW_NAME=%%SERVER_NAME_%%I%%"
    if "%%I"=="%DEFAULT_SERVER_INDEX%" (
        echo   %%I. !SHOW_NAME! [default]
    ) else (
        echo   %%I. !SHOW_NAME!
    )
)
echo   0. Exit
set "SERVER_CHOICE="
set /p "SERVER_CHOICE=Choose executable [%DEFAULT_SERVER_INDEX%]: "
if not defined SERVER_CHOICE set "SERVER_CHOICE=%DEFAULT_SERVER_INDEX%"
if "!SERVER_CHOICE!"=="0" exit /b 1
set "SERVER_NUM="
for /l %%N in (1,1,%SERVER_COUNT%) do if "!SERVER_CHOICE!"=="%%N" set "SERVER_NUM=%%N"
if not defined SERVER_NUM (
    echo Invalid selection.
    echo.
    goto :choose_server_prompt
)
set "SERVER_INDEX=!SERVER_NUM!"
call :apply_server_selection
exit /b 0

:apply_server_selection
call set "SERVER_NAME=%%SERVER_NAME_%SERVER_INDEX%%%"
call set "SERVER_PATH=%%SERVER_PATH_%SERVER_INDEX%%%"
call set "SERVER_KIND=%%SERVER_KIND_%SERVER_INDEX%%%"
call set "SERVER_EXTRA=%%SERVER_EXTRA_%SERVER_INDEX%%%"
call set "DEFAULT_CONTEXT=%%SERVER_CTX_%SERVER_INDEX%%%"
exit /b 0

:choose_model
if "%DRY_RUN%"=="1" (
    set "MODEL_INDEX=%DEFAULT_MODEL_INDEX%"
    call :apply_model_selection
    exit /b 0
)

:choose_model_prompt
echo.
echo Model:
for /l %%I in (1,1,%MODEL_COUNT%) do (
    call set "SHOW_MODEL=%%MODEL_NAME_%%I%%"
    if "%%I"=="%DEFAULT_MODEL_INDEX%" (
        echo   %%I. !SHOW_MODEL! [default]
    ) else (
        echo   %%I. !SHOW_MODEL!
    )
)
echo   0. Exit
set "MODEL_CHOICE="
set /p "MODEL_CHOICE=Choose model [%DEFAULT_MODEL_INDEX%]: "
if not defined MODEL_CHOICE set "MODEL_CHOICE=%DEFAULT_MODEL_INDEX%"
if "!MODEL_CHOICE!"=="0" exit /b 1
set "MODEL_NUM="
for /l %%N in (1,1,%MODEL_COUNT%) do if "!MODEL_CHOICE!"=="%%N" set "MODEL_NUM=%%N"
if not defined MODEL_NUM (
    echo Invalid selection.
    echo.
    goto :choose_model_prompt
)
set "MODEL_INDEX=!MODEL_NUM!"
call :apply_model_selection
exit /b 0

:apply_model_selection
call set "MODEL_NAME=%%MODEL_NAME_%MODEL_INDEX%%%"
call set "MODEL_PATH=%%MODEL_PATH_%MODEL_INDEX%%%"
exit /b 0

:choose_context
if "%DRY_RUN%"=="1" (
    set "CONTEXT=%DEFAULT_CONTEXT%"
    exit /b 0
)

:choose_context_prompt
echo.
echo Context length:
echo   1. 4096
if "%DEFAULT_CONTEXT%"=="8192" (
    echo   2. 8192 [default]
) else (
    echo   2. 8192
)
if "%DEFAULT_CONTEXT%"=="16384" (
    echo   3. 16384 [default]
) else (
    echo   3. 16384
)
echo   4. Custom
echo   0. Exit
set "CTX_CHOICE="
if not defined DEFAULT_CONTEXT set "DEFAULT_CONTEXT=8192"
set /p "CTX_CHOICE=Choose context [%DEFAULT_CONTEXT%]: "
if not defined CTX_CHOICE set "CONTEXT=%DEFAULT_CONTEXT%" & exit /b 0
if "!CTX_CHOICE!"=="0" exit /b 1
if "!CTX_CHOICE!"=="1" set "CONTEXT=4096" & exit /b 0
if "!CTX_CHOICE!"=="2" set "CONTEXT=8192" & exit /b 0
if "!CTX_CHOICE!"=="3" set "CONTEXT=16384" & exit /b 0
if "!CTX_CHOICE!"=="4" (
    set "CUSTOM_CONTEXT="
    set /p "CUSTOM_CONTEXT=Enter custom context length: "
    set "CUSTOM_CONTEXT_NUM="
    set /a CUSTOM_CONTEXT_NUM=!CUSTOM_CONTEXT! >nul 2>nul
    if errorlevel 1 (
        echo Invalid context.
        echo.
        goto :choose_context_prompt
    )
    if "!CUSTOM_CONTEXT_NUM!"=="0" (
        echo Invalid context.
        echo.
        goto :choose_context_prompt
    )
    set "CONTEXT=!CUSTOM_CONTEXT_NUM!"
    exit /b 0
)
echo Invalid selection.
echo.
goto :choose_context_prompt

:choose_port
if "%DRY_RUN%"=="1" (
    set "PORT=8080"
    exit /b 0
)

:choose_port_prompt
echo.
set "PORT_INPUT="
set /p "PORT_INPUT=Port [%PORT%]: "
if not defined PORT_INPUT exit /b 0
set "PORT_NUM="
set /a PORT_NUM=!PORT_INPUT! >nul 2>nul
if errorlevel 1 (
    echo Invalid port.
    goto :choose_port_prompt
)
if "!PORT_NUM!"=="0" (
    echo Invalid port.
    goto :choose_port_prompt
)
set "PORT=!PORT_NUM!"
exit /b 0

:choose_speculative
set "SPECULATIVE=0"
set "SPEC_ARGS="
if not defined DRAFT_MODEL exit /b 0
if /I "%MODEL_PATH%"=="%DRAFT_MODEL%" exit /b 0
if "%DRY_RUN%"=="1" exit /b 0

:choose_spec_prompt
echo.
echo Speculative decoding draft model available:
echo   %DRAFT_MODEL%
set "SPEC_CHOICE="
set /p "SPEC_CHOICE=Enable speculative decoding? [y/N]: "
if not defined SPEC_CHOICE exit /b 0
if /I "!SPEC_CHOICE!"=="N" exit /b 0
if /I "!SPEC_CHOICE!"=="NO" exit /b 0
if /I "!SPEC_CHOICE!"=="Y" set "SPECULATIVE=1" & goto :spec_selected
if /I "!SPEC_CHOICE!"=="YES" set "SPECULATIVE=1" & goto :spec_selected
echo Invalid selection.
goto :choose_spec_prompt

:spec_selected
set "SPEC_ARGS=-md ^"!DRAFT_MODEL!^" -ngld %GPU_LAYERS% --spec-draft-n-max 16 --spec-draft-n-min 1 --spec-draft-p-min 0.8"
exit /b 0

:resolve_environment_paths
set "VSCODE_BIN="
set "VSCODE_SOURCE=not found"
set "VSDEVCMD_PATH="
set "VSDEVCMD_SOURCE=not needed"

call :resolve_vscode_bin

if /I "%SERVER_KIND%"=="ipex" exit /b 0

if exist "%VSWHERE%" (
    for /f "usebackq delims=" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        if exist "%%~fI\Common7\Tools\VsDevCmd.bat" (
            set "VSDEVCMD_PATH=%%~fI\Common7\Tools\VsDevCmd.bat"
            set "VSDEVCMD_SOURCE=vswhere"
        )
    )
)

if not defined VSDEVCMD_PATH if exist "D:\Visual studio\GenAnZhuang\Common7\Tools\VsDevCmd.bat" (
    set "VSDEVCMD_PATH=D:\Visual studio\GenAnZhuang\Common7\Tools\VsDevCmd.bat"
    set "VSDEVCMD_SOURCE=fallback"
)

if not defined VSDEVCMD_PATH if exist "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" (
    set "VSDEVCMD_PATH=C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
    set "VSDEVCMD_SOURCE=fallback"
)

if not defined VSDEVCMD_PATH set "VSDEVCMD_SOURCE=missing"
exit /b 0

:resolve_vscode_bin
if exist "%LocalAppData%\Programs\Microsoft VS Code\bin\code.cmd" (
    set "VSCODE_BIN=%LocalAppData%\Programs\Microsoft VS Code\bin"
    set "VSCODE_SOURCE=user"
    exit /b 0
)
if exist "C:\Program Files\Microsoft VS Code\bin\code.cmd" (
    set "VSCODE_BIN=C:\Program Files\Microsoft VS Code\bin"
    set "VSCODE_SOURCE=machine"
    exit /b 0
)
if exist "C:\Program Files (x86)\Microsoft VS Code\bin\code.cmd" (
    set "VSCODE_BIN=C:\Program Files (x86)\Microsoft VS Code\bin"
    set "VSCODE_SOURCE=machine-x86"
    exit /b 0
)
for /f "delims=" %%I in ('where code 2^>nul') do (
    for %%J in ("%%~dpI..") do set "VSCODE_BIN=%%~fJ"
    set "VSCODE_SOURCE=path"
    exit /b 0
)
exit /b 0

:build_command
set "COMMAND_ARGS=-m ^"%MODEL_PATH%^" -ngl %GPU_LAYERS%"
if defined SERVER_EXTRA set "COMMAND_ARGS=%COMMAND_ARGS% %SERVER_EXTRA%"
set "COMMAND_ARGS=%COMMAND_ARGS% -c %CONTEXT% --host %HOST% --port %PORT%"
if defined SPEC_ARGS set "COMMAND_ARGS=%COMMAND_ARGS% %SPEC_ARGS%"
exit /b 0

:print_summary
echo.
echo ------------------------------------------
echo Resolved server: %SERVER_PATH%
echo Resolved model: %MODEL_PATH%
echo Resolved context: %CONTEXT%
echo Resolved port: %PORT%
echo Host: %HOST%
echo GPU layers: %GPU_LAYERS%
if /I "%SERVER_KIND%"=="ipex" (
    echo Runtime mode: IPEX-LLM
    echo oneAPI init: skipped for portable runtime
    echo VS DevCmd: not needed
) else (
    echo Runtime mode: local SYCL build
    echo VS DevCmd: !VSDEVCMD_PATH!
    echo oneAPI setvars: !ONEAPI_SETVARS!
)
if defined VSCODE_BIN (
    echo VS Code bin: !VSCODE_BIN! [!VSCODE_SOURCE!]
) else (
    echo VS Code bin: not found
)
if defined SPEC_ARGS (
    echo Speculative decoding: enabled
    echo Draft model: !DRAFT_MODEL!
)
echo Resolved command:
echo   "%SERVER_PATH%" %COMMAND_ARGS%
echo ------------------------------------------
exit /b 0

:load_environment
if defined VSCODE_BIN set "PATH=%VSCODE_BIN%;%PATH%"

if /I "%SERVER_KIND%"=="ipex" (
    set "SYCL_CACHE_PERSISTENT=1"
    exit /b 0
)

if not defined VSDEVCMD_PATH (
    echo Visual Studio developer environment was not found.
    exit /b 1
)

if not exist "!ONEAPI_SETVARS!" (
    echo oneAPI setvars.bat was not found:
    echo   !ONEAPI_SETVARS!
    exit /b 1
)

echo Loading Visual Studio developer environment...
call "!VSDEVCMD_PATH!" -arch=x64 -host_arch=x64 >nul
if errorlevel 1 (
    echo Failed to load VsDevCmd.bat
    exit /b 1
)

echo Loading Intel oneAPI environment...
call "!ONEAPI_SETVARS!" >nul
if errorlevel 1 (
    echo Failed to load oneAPI setvars.bat
    exit /b 1
)

exit /b 0

:no_servers
echo No supported llama-server executable was found under:
echo   %ROOT%
echo Expected one of:
echo   %ROOT%\llama.cpp\build-f16\bin\llama-server.exe
echo   %ROOT%\llama.cpp\build\bin\llama-server.exe
echo   %ROOT%\llama-cpp-ipex-llm*\llama-server.exe
if "%DRY_RUN%"=="1" exit /b 1
pause
goto :done

:no_models
echo No GGUF models were found under:
echo   %ROOT%
if "%DRY_RUN%"=="1" exit /b 1
pause

:done
if "%DRY_RUN%"=="0" if "%MENU_TEST%"=="0" if "%ENV_TEST%"=="0" if not "%PAUSED_ON_EXIT%"=="1" (
    echo.
    echo Script finished before starting llama-server.
    echo Review the messages above, then press any key to close.
    pause >nul
)
endlocal
exit /b
