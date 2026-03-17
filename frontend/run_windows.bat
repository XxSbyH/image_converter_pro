@echo off
setlocal

cd /d "%~dp0"

echo [1/2] 正在同步依赖...
call flutter pub get
if errorlevel 1 goto :error

echo.
echo [2/2] 正在启动 Windows 桌面应用...
call flutter run -d windows
if errorlevel 1 goto :error

goto :end

:error
echo.
echo 启动失败，请检查 flutter 环境或项目依赖。
pause
exit /b 1

:end
endlocal
