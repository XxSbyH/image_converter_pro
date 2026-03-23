# Image Converter Pro 🖼️

> 一个强大的本地图片格式批量转换工具，支持 JPG、PNG、WebP、HEIC 等格式互转

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/Python-3.10%2B-green.svg)](https://www.python.org/)

[English](README_EN.md) | 简体中文

## ✨ 特性

- 🚀 **批量转换** - 支持单个文件或整个文件夹批量处理
- 🎨 **格式丰富** - 支持 JPG、PNG、WebP、HEIC 格式互转
- 📊 **智能预估** - 实时显示转换后文件大小预估
- 🎯 **格式建议** - 智能推荐最适合的输出格式
- 🔧 **质量可调** - 灵活调整输出质量（1-100）
- 💻 **桌面应用** - 原生 Windows 桌面应用
- 🔒 **隐私保护** - 完全本地处理，不上传任何数据
- ⚡ **高性能** - 基于 FastAPI 后端，处理快速高效

## 🏗️ 技术栈

### 前端
- **Framework**: Flutter 3.0+
- **Platform**: Windows Desktop
- **UI Components**: Material Design 3
- **State Management**: Provider

### 后端
- **Framework**: FastAPI
- **Image Processing**: Pillow, pillow-heif
- **Language**: Python 3.10+

## 📦 快速开始

### 方式 1: 使用预编译版本（推荐给普通用户）

1. 前往 [Releases](https://github.com/你的用户名/image-converter-pro/releases) 页面
2. 下载最新版本的 `.zip` 文件
3. 解压到任意目录
4. 运行 `image_converter_pro.exe`

### 方式 2: 从源码构建（推荐给开发者）

#### 前置要求

确保你的系统已安装以下软件：

- **Git** - [下载地址](https://git-scm.com/)
- **Flutter 3.0+** - [安装指南](https://docs.flutter.dev/get-started/install)
- **Python 3.10+** - [下载地址](https://www.python.org/downloads/)
- **Visual Studio 2022** - C++ 桌面开发组件（Flutter Windows 桌面开发必需）

#### 安装步骤

**1. 克隆项目**

```bash
git clone https://github.com/XxSbyH/image_converter_pro.git
cd image-converter-pro
```

**2. 自动安装（推荐）**

**Windows 用户**：
```bash
# 双击运行或命令行执行
setup.bat
```

**3. 手动安装（可选）**

如果自动安装失败，可以手动执行：

**后端设置**：
```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/macOS
pip install -r requirements.txt
cd ..
```

**前端设置**：
```bash
cd frontend
flutter pub get
cd ..
```

## 🚀 运行项目

### 开发模式

需要同时运行前端和后端：

**终端 1 - 启动后端**：
```bash
cd backend
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/macOS
python main.py
```

后端将在 `http://localhost:8000` 启动

**终端 2 - 启动前端**：
```bash
cd frontend
flutter run -d windows
```

### 生产模式

**构建可执行文件**：

```bash
cd frontend
flutter build windows --release
```

构建产物位于 `frontend/build/windows/runner/Release/`

## 🧪 运行测试

### 后端测试

```bash
cd backend
venv\Scripts\activate
pytest
```

### 前端测试

```bash
cd frontend
flutter test
```

## 📦 打包发布

### Windows 应用打包

**1. 构建 Release 版本**

```bash
cd frontend
flutter build windows --release
```

**2. 准备发布文件**

创建一个发布文件夹，包含以下内容：

```
image-converter-pro-v1.0.0/
├── image_converter_pro.exe     # 前端可执行文件
├── data/                       # Flutter 资源文件
├── backend/                    # 后端目录
│   ├── main.py
│   ├── requirements.txt
│   ├── api/
│   ├── services/
│   └── utils/
├── start.bat                   # 启动脚本
└── README.txt                  # 用户说明
```

**3. 创建启动脚本**

创建 `start.bat`：
```batch
@echo off
echo 正在启动 Image Converter Pro...

REM 检查后端虚拟环境
if not exist "backend\venv\" (
    echo 首次运行，正在设置环境...
    cd backend
    python -m venv venv
    call venv\Scripts\activate
    pip install -r requirements.txt
    cd ..
)

REM 启动后端
start /B cmd /c "cd backend && venv\Scripts\activate && python main.py"

REM 等待后端启动
timeout /t 3 /nobreak >nul

REM 启动前端
start image_converter_pro.exe
```

**4. 打包为 ZIP**

使用 7-Zip 或 WinRAR 将整个文件夹压缩为 `image-converter-pro-v1.0.0-windows.zip`

### 使用 GitHub Actions 自动发布

项目已配置 GitHub Actions，每次推送 tag 时自动构建和发布：

```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions 将自动：
1. 构建 Windows 应用
2. 打包后端
3. 创建 Release
4. 上传构建产物

## 📁 项目结构

```
image-converter-pro/
├── frontend/                   # Flutter 前端
│   ├── lib/                   # 源代码
│   │   ├── models/           # 数据模型
│   │   ├── providers/        # 状态管理
│   │   ├── screens/          # 页面
│   │   ├── services/         # API 服务
│   │   ├── widgets/          # 自定义组件
│   │   └── utils/            # 工具函数
│   ├── windows/              # Windows 平台配置
│   ├── pubspec.yaml          # Flutter 依赖
│   └── README.md             # 前端说明
│
├── backend/                   # Python 后端
│   ├── api/                  # API 路由
│   ├── services/             # 业务逻辑
│   ├── utils/                # 工具函数
│   ├── main.py               # 入口文件
│   ├── requirements.txt      # Python 依赖
│   └── README.md             # 后端说明
│
├── docs/                      # 文档
│   ├── 安装指南.md
│   ├── 使用说明.md
│   └── 开发指南.md
│
├── screenshot/                # 应用截图
├── .github/                   # GitHub 配置
│   └── workflows/            # CI/CD 工作流
├── .gitignore                # Git 忽略文件
├── setup.bat                 # Windows 安装脚本
├── setup.sh                  # Linux/macOS 安装脚本
├── LICENSE                   # 开源协议
├── README.md                 # 项目说明（本文件）
└── AGENTS.md                 # AI Agent 开发指南
```

## 🔧 配置说明

### 后端配置

后端配置文件位于 `backend/config.py`，可配置：

- **端口号**: 默认 `8000`
- **文件大小限制**: 默认 `50 MB`
- **输出目录**: 默认 `用户文档/ImageConverterPro/output`

### 前端配置

前端 API 地址配置位于 `frontend/lib/services/api_service.dart`：

```dart
static const String baseUrl = 'http://localhost:8000';
```

## 🤝 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 开发规范

- 遵循 [Flutter 代码规范](https://dart.dev/guides/language/effective-dart)
- 遵循 [PEP 8](https://www.python.org/dev/peps/pep-0008/) Python 代码规范
- 提交信息遵循 [约定式提交](https://www.conventionalcommits.org/zh-hans/)
- 所有 PR 必须通过 CI/CD 检查

## 📝 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解版本更新历史。

## 🐛 问题反馈

遇到问题？请提交 [Issue](https://github.com/你的用户名/image-converter-pro/issues)

提交 Issue 时，请包含：
- 操作系统版本
- 应用版本
- 详细的问题描述
- 复现步骤
- 错误截图（如有）

## 📄 开源协议

本项目采用 [MIT 协议](LICENSE) 开源。

简单来说，你可以：
- ✅ 商业使用
- ✅ 修改源码
- ✅ 分发
- ✅ 私人使用

但需要：
- 📋 包含原许可证
- 📋 包含版权声明

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [FastAPI](https://fastapi.tiangolo.com/) - 现代 Python Web 框架
- [Pillow](https://python-pillow.org/) - Python 图像处理库
- [pillow-heif](https://github.com/bigcat88/pillow_heif) - HEIC 格式支持

---

**Star ⭐ 这个项目如果它对你有帮助！**
