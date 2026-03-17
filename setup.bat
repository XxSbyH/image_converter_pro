@echo off
REM ==========================================
REM Image Converter Pro - Windows Setup Script
REM ==========================================

echo.
echo ==========================================
echo   Image Converter Pro - 环境设置
echo ==========================================
echo.

REM 检查 Python 是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到 Python，请先安装 Python 3.10 或更高版本
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM 检查 Flutter 是否安装
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到 Flutter，请先安装 Flutter 3.0 或更高版本
    echo 安装指南: https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

echo [✓] Python 和 Flutter 检测通过
echo.

REM ==========================================
REM 设置后端
REM ==========================================

echo [1/4] 设置后端环境...
echo.

cd backend

REM 检查是否已有虚拟环境
if exist "venv\" (
    echo [提示] 检测到已存在的虚拟环境
    choice /C YN /M "是否删除并重新创建"
    if errorlevel 2 (
        echo [跳过] 保留现有虚拟环境
        goto :activate_venv
    )
    echo [执行] 删除旧的虚拟环境...
    rmdir /s /q venv
)

echo [执行] 创建 Python 虚拟环境...
python -m venv venv
if errorlevel 1 (
    echo [错误] 虚拟环境创建失败
    cd ..
    pause
    exit /b 1
)

:activate_venv
echo [执行] 激活虚拟环境...
call venv\Scripts\activate
if errorlevel 1 (
    echo [错误] 虚拟环境激活失败
    cd ..
    pause
    exit /b 1
)

echo [执行] 安装 Python 依赖包...
pip install --upgrade pip
pip install -r requirements.txt
if errorlevel 1 (
    echo [错误] 依赖包安装失败
    cd ..
    pause
    exit /b 1
)

echo [✓] 后端环境设置完成
echo.

cd ..

REM ==========================================
REM 设置前端
REM ==========================================

echo [2/4] 设置前端环境...
echo.

cd frontend

REM 清理之前的构建
if exist "build\" (
    echo [清理] 删除旧的构建文件...
    rmdir /s /q build
)

if exist ".dart_tool\" (
    echo [清理] 删除 .dart_tool...
    rmdir /s /q .dart_tool
)

echo [执行] 获取 Flutter 依赖...
flutter pub get
if errorlevel 1 (
    echo [错误] Flutter 依赖获取失败
    cd ..
    pause
    exit /b 1
)

echo [✓] 前端环境设置完成
echo.

cd ..

REM ==========================================
REM 验证安装
REM ==========================================

echo [3/4] 验证安装...
echo.

REM 验证后端
echo [检查] 后端依赖...
cd backend
call venv\Scripts\activate
python -c "import fastapi, PIL, pillow_heif; print('[✓] 后端核心依赖已安装')" 2>nul
if errorlevel 1 (
    echo [警告] 部分后端依赖可能未正确安装
)
cd ..

REM 验证前端
echo [检查] 前端配置...
cd frontend
flutter doctor >nul 2>&1
if errorlevel 1 (
    echo [警告] Flutter 环境可能存在问题，建议运行 'flutter doctor' 查看详情
) else (
    echo [✓] 前端环境正常
)
cd ..

echo.

REM ==========================================
REM 创建启动脚本
REM ==========================================

echo [4/4] 创建启动脚本...
echo.

REM 创建后端启动脚本
echo @echo off > start_backend.bat
echo cd backend >> start_backend.bat
echo call venv\Scripts\activate >> start_backend.bat
echo python main.py >> start_backend.bat
echo pause >> start_backend.bat

echo [✓] 后端启动脚本: start_backend.bat

REM 创建前端启动脚本
echo @echo off > start_frontend.bat
echo cd frontend >> start_frontend.bat
echo flutter run -d windows >> start_frontend.bat
echo pause >> start_frontend.bat

echo [✓] 前端启动脚本: start_frontend.bat

REM 创建一键启动脚本
echo @echo off > start.bat
echo echo 正在启动 Image Converter Pro... >> start.bat
echo echo. >> start.bat
echo start /B cmd /c start_backend.bat >> start.bat
echo timeout /t 3 /nobreak ^>nul >> start.bat
echo start cmd /c start_frontend.bat >> start.bat

echo [✓] 一键启动脚本: start.bat

echo.

REM ==========================================
REM 完成
REM ==========================================

echo ==========================================
echo   安装完成！
echo ==========================================
echo.
echo 项目已成功设置，你可以通过以下方式运行：
echo.
echo 方式 1: 一键启动（推荐）
echo   双击运行: start.bat
echo.
echo 方式 2: 分别启动
echo   步骤 1: 双击运行 start_backend.bat 启动后端
echo   步骤 2: 双击运行 start_frontend.bat 启动前端
echo.
echo 方式 3: 手动启动
echo   终端 1: cd backend ^&^& venv\Scripts\activate ^&^& python main.py
echo   终端 2: cd frontend ^&^& flutter run -d windows
echo.
echo ==========================================
echo   开发提示
echo ==========================================
echo.
echo - 后端 API 地址: http://localhost:8000
echo - 后端 API 文档: http://localhost:8000/docs
echo - 查看 README.md 了解更多信息
echo.

pause
