# 图片批量压缩/格式转换工具 - 项目实施计划

## 📋 项目基本信息

**项目名称**: Image Converter Pro  
**技术栈**: Flutter + Python FastAPI  
**目标平台**: Windows 桌面应用（首发），Mac OS（后续）  
**开发方式**: AI 辅助编程（Claude Code）  
**预计工作量**: 3-5 天  
**最终交付物**: Windows 可执行程序 (.exe)

---

## 🎯 核心功能需求

### 必须实现的功能（MVP）
- [x] 支持 JPG/PNG/WebP/HEIC 格式互相转换
- [x] 图片质量可调节（1-100%）
- [x] 批量处理多个文件
- [x] 实时进度条显示
- [x] 拖拽添加文件
- [x] 转换历史记录
- [x] 批量重命名
- [x] 预设配置保存
- [x] 图片尺寸调整

---

## 📐 技术架构边界

### 前端（Flutter）职责范围
- UI 界面展示
- 文件选择和拖拽
- 用户交互逻辑
- 向后端发送 HTTP 请求
- 接收并展示处理结果
- 进度条更新

### 后端（Python FastAPI）职责范围
- 图像格式转换
- 图像质量压缩
- 批量处理任务
- 返回处理结果（Base64 或文件）
- 错误处理和异常返回

### 通信协议
- 前后端通过 HTTP REST API 通信
- 后端运行在 localhost:8000
- 数据格式：JSON + Base64 编码图片

---

## 🗓️ 实施步骤（分阶段）

---

## Phase 0: 前期准备工作

**目标**: 确保开发环境就绪  
**预计时间**: 1-2 小时

### Step 0.1: 环境检查清单
- [ ] 确认 Windows 操作系统版本（Windows 10/11）
- [ ] 检查磁盘空间（至少 3GB 可用）
- [ ] 确保网络连接正常（需要下载依赖）

### Step 0.2: Flutter 环境安装
- [ ] 下载 Flutter SDK（官网 flutter.dev）
- [ ] 解压到指定目录（如 C:\flutter）
- [ ] 添加 Flutter 到系统 PATH 环境变量
- [ ] 运行 `flutter doctor` 检查环境
- [ ] 启用 Windows 桌面支持：`flutter config --enable-windows-desktop`
- [ ] 验证桌面支持：`flutter devices` 应该看到 Windows

### Step 0.3: Python 环境安装
- [ ] 下载并安装 Python 3.10 或更高版本
- [ ] 确认 pip 可用：`pip --version`
- [ ] 确认 Python 已添加到 PATH

### Step 0.5: 创建项目工作目录
```
image_converter_project/
├── frontend/          # Flutter 项目
└── backend/           # Python 后端
```

**完成标志**: 运行 `flutter doctor` 全部绿色勾，Python 可正常运行

---

## Phase 1: 后端搭建

**目标**: 构建可运行的图像处理 API 服务  
**预计时间**: 半天（4 小时）

### Step 1.1: 创建 Python 项目结构
- [ ] 创建 `backend/` 目录
- [ ] 创建虚拟环境：`python -m venv venv`
- [ ] 激活虚拟环境（Windows: `venv\Scripts\activate`）

### Step 1.2: 定义项目依赖
- [ ] 创建 `requirements.txt` 文件
- [ ] 列出核心依赖：
  - fastapi
  - uvicorn
  - pillow
  - pillow-heif（HEIC 支持）
  - python-multipart
  - aiofiles

### Step 1.3: 安装 Python 依赖
- [ ] 运行 `pip install -r requirements.txt`
- [ ] 验证关键库导入成功：
  ```python
  import fastapi
  import PIL
  import pillow_heif
  ```

### Step 1.4: 创建基础 API 结构
- [ ] 创建 `main.py` 主入口文件
- [ ] 设置 FastAPI 应用实例
- [ ] 配置 CORS（允许跨域）
- [ ] 创建健康检查接口 `/health`

### Step 1.5: 实现图像处理核心逻辑
- [ ] 创建 `image_processor.py` 模块
- [ ] 实现单张图片格式转换功能
- [ ] 实现质量压缩功能
- [ ] 处理 RGBA 转 RGB（JPEG 不支持透明）
- [ ] 错误处理（不支持的格式、损坏的图片）

### Step 1.6: 创建 API 接口
- [ ] `/api/formats` - 返回支持的格式列表
- [ ] `/api/convert` - 单张图片转换（接收 UploadFile）
- [ ] `/api/batch-convert` - 批量转换（接收多个文件）
- [ ] 定义清晰的请求/响应数据结构

### Step 1.7: 本地测试后端
- [ ] 启动 API 服务：`uvicorn main:app --reload`
- [ ] 浏览器访问 `http://localhost:8000/docs`（查看自动生成的 API 文档）
- [ ] 使用 Swagger UI 测试接口
- [ ] 确认图片转换功能正常

**完成标志**: 后端 API 正常运行，可以通过 Swagger UI 上传图片并成功转换

---

## Phase 2: Flutter 前端基础搭建

**目标**: 创建 Flutter 应用框架和基础 UI  
**预计时间**: 半天（4 小时）

### Step 2.1: 创建 Flutter 项目
- [ ] 运行 `flutter create image_converter_pro`
- [ ] 进入项目目录：`cd image_converter_pro`
- [ ] 删除默认示例代码

### Step 2.2: 配置项目依赖
- [ ] 编辑 `pubspec.yaml`
- [ ] 添加必要的包：
  - provider（状态管理）
  - http 或 dio（网络请求）
  - file_picker（文件选择）
  - desktop_drop（拖拽支持）
  - path_provider（路径）
- [ ] 运行 `flutter pub get` 安装依赖

### Step 2.3: 创建项目目录结构
```
lib/
├── main.dart
├── models/          # 数据模型
├── services/        # 业务逻辑（API调用）
├── providers/       # 状态管理
├── screens/         # 页面
└── widgets/         # 可复用组件
```

### Step 2.4: 定义数据模型
- [ ] 创建 `ImageFileModel` 类
  - 属性：文件路径、文件名、大小、状态（待处理/处理中/完成/失败）
- [ ] 创建 `ConversionSettings` 类
  - 属性：目标格式、质量、输出路径

### Step 2.5: 实现 API 服务层
- [ ] 创建 `ApiService` 类
- [ ] 实现 `checkHealth()` 方法
- [ ] 实现 `getSupportedFormats()` 方法
- [ ] 实现 `convertImage()` 方法（单张）
- [ ] 实现 `batchConvert()` 方法（批量）
- [ ] 错误处理和超时机制

### Step 2.6: 搭建主界面框架
- [ ] 创建 `HomeScreen` 页面
- [ ] 设计基本布局：
  - 顶部：标题栏和设置按钮
  - 中间：文件列表区域
  - 底部：控制面板（格式选择、质量调节、开始按钮）

### Step 2.7: 验证运行
- [ ] 运行 `flutter run -d windows`
- [ ] 确认应用可以正常启动
- [ ] 查看基础界面

**完成标志**: Flutter 应用可以在 Windows 上启动，显示基础 UI 框架

---

## Phase 3: 核心功能实现

**目标**: 实现文件选择、转换、进度显示等核心功能  
**预计时间**: 1 天

### Step 3.1: 文件选择功能
- [ ] 使用 `file_picker` 实现"选择文件"按钮
- [ ] 支持多选
- [ ] 过滤只显示图片文件（jpg、png、webp、heic）
- [ ] 将选中的文件添加到列表

### Step 3.2: 拖拽功能实现
- [ ] 使用 `desktop_drop` 包
- [ ] 创建拖拽区域组件 `DropZoneWidget`
- [ ] 监听 onDragEntered、onDragExited、onDragDone 事件
- [ ] 拖拽时显示视觉反馈（边框高亮）
- [ ] 拖拽完成后添加文件到列表

### Step 3.3: 文件列表展示
- [ ] 创建 `ImageListItem` 组件
- [ ] 显示文件名、大小、状态
- [ ] 添加删除按钮
- [ ] 显示缩略图（可选）

### Step 3.4: 转换控制面板
- [ ] 创建格式选择下拉菜单（JPG/PNG/WebP）
- [ ] 创建质量滑块（1-100）
- [ ] 实时显示当前选择的参数
- [ ] "开始转换"按钮

### Step 3.5: 状态管理集成
- [ ] 创建 `ImageListProvider`
- [ ] 管理文件列表状态
- [ ] 管理转换设置状态
- [ ] 管理转换进度状态

### Step 3.6: 实现转换逻辑
- [ ] 点击"开始转换"触发
- [ ] 弹出文件夹选择器（选择输出目录）
- [ ] 循环处理每个文件：
  1. 更新状态为"处理中"
  2. 调用后端 API
  3. 接收返回的 Base64 数据
  4. 解码并保存到输出目录
  5. 更新状态为"完成"或"失败"
- [ ] 错误处理和重试机制

### Step 3.7: 进度显示
- [ ] 创建总体进度条（已完成/总数）
- [ ] 每个文件项显示单独的状态图标
- [ ] 显示预计剩余时间（可选）
- [ ] 转换完成后显示成功提示

**完成标志**: 可以选择/拖拽图片，设置参数，点击转换，成功生成转换后的图片

---

## Phase 4: UI 优化和用户体验

**目标**: 提升界面美观度和交互体验  
**预计时间**: 半天（4 小时）

### Step 4.1: 视觉设计优化
- [ ] 定义应用主题色（Material Theme）
- [ ] 统一按钮样式
- [ ] 优化字体大小和间距
- [ ] 添加图标（使用 FontAwesome 或自定义）
- [ ] 空状态提示（无文件时显示引导）

### Step 4.2: 拖拽区域美化
- [ ] 使用虚线边框（dotted_border 包）
- [ ] 拖拽悬停时改变背景色
- [ ] 添加图标和提示文字
- [ ] 响应式布局适配不同窗口大小

### Step 4.3: 加载动画
- [ ] 处理中显示 Spinner（flutter_spinkit）
- [ ] 平滑的状态切换动画
- [ ] 进度条使用圆形百分比显示器（percent_indicator）

### Step 4.4: 交互反馈
- [ ] 添加按钮点击波纹效果
- [ ] 文件删除时显示确认对话框
- [ ] 成功/失败时显示 SnackBar 提示
- [ ] 禁用处理中的操作（防止重复点击）

### Step 4.5: 响应式布局
- [ ] 支持窗口缩放
- [ ] 最小窗口尺寸限制
- [ ] 列表项在窄屏下自适应

**完成标志**: 应用界面美观、交互流畅，用户体验良好

---

## Phase 5: 后端进程管理

**目标**: 实现前端自动启动后端服务  
**预计时间**: 半天（3-4 小时）

### Step 5.1: Python 后端打包
- [ ] 安装 PyInstaller：`pip install pyinstaller`
- [ ] 创建打包配置文件 `build.spec`
- [ ] 打包成单文件可执行程序：`pyinstaller --onefile main.py`
- [ ] 测试打包后的 exe 是否正常运行
- [ ] 将 exe 放到 Flutter 项目的 `assets/` 目录

### Step 5.2: Flutter 中集成后端
- [ ] 使用 `process_run` 包启动后端进程
- [ ] 创建 `BackendManager` 类
- [ ] 实现 `startBackend()` 方法
- [ ] 实现 `stopBackend()` 方法
- [ ] 应用启动时自动启动后端
- [ ] 应用关闭时自动停止后端

### Step 5.3: 健康检查机制
- [ ] 启动后端后轮询 `/health` 接口
- [ ] 等待后端就绪后再显示主界面
- [ ] 显示"正在启动服务..."加载界面
- [ ] 如果后端启动失败，显示错误提示

### Step 5.4: 资源清理
- [ ] 监听 Flutter 应用关闭事件
- [ ] 确保后端进程被正确终止
- [ ] 清理临时文件

**完成标志**: Flutter 应用启动时自动启动后端，关闭时自动停止，无需手动操作

---

## Phase 6: 测试与优化

**目标**: 确保应用稳定性和性能  
**预计时间**: 半天（3-4 小时）

### Step 6.1: 功能测试
- [ ] 测试所有格式互转（JPG→PNG、PNG→WebP 等）
- [ ] 测试不同质量参数（10%、50%、100%）
- [ ] 测试批量处理（10+ 文件）
- [ ] 测试大文件处理（10MB+ 图片）
- [ ] 测试 HEIC 格式转换

### Step 6.2: 边界测试
- [ ] 测试空文件列表的处理
- [ ] 测试无效图片文件
- [ ] 测试后端服务未启动的情况
- [ ] 测试网络超时
- [ ] 测试磁盘空间不足

### Step 6.3: 性能优化
- [ ] 优化大图片处理速度
- [ ] 批量处理使用异步并发（限制并发数）
- [ ] 减少不必要的 UI 重建
- [ ] 优化内存使用

### Step 6.4: 错误处理完善
- [ ] 所有 API 调用添加 try-catch
- [ ] 显示用户友好的错误信息
- [ ] 记录错误日志（可选）

### Step 6.5: 用户体验细节
- [ ] 长时间处理时防止界面卡顿
- [ ] 支持取消正在进行的转换
- [ ] 记住用户上次的设置
- [ ] 添加快捷键支持（可选）

**完成标志**: 应用稳定运行，各种异常情况都有合理处理

---

## Phase 7: 打包发布

**目标**: 生成可分发的 Windows 可执行程序  
**预计时间**: 2-3 小时

### Step 7.1: Flutter 应用打包准备
- [ ] 修改 `pubspec.yaml` 中的版本号
- [ ] 设置应用名称和描述
- [ ] 准备应用图标（.ico 格式）
- [ ] 配置 Windows 应用属性（windows/runner/）

### Step 7.2: 打包 Flutter 应用
- [ ] 运行 `flutter build windows --release`
- [ ] 检查 `build/windows/runner/Release/` 目录
- [ ] 确认所有 DLL 文件都存在
- [ ] 测试打包后的应用是否正常运行

### Step 7.3: 整合后端可执行文件
- [ ] 将 Python 后端 exe 复制到 Flutter 输出目录
- [ ] 确保 Flutter 能找到后端 exe
- [ ] 测试整体运行

### Step 7.4: 创建安装程序（可选）
- [ ] 使用 Inno Setup 或 NSIS
- [ ] 创建安装向导
- [ ] 设置开始菜单快捷方式
- [ ] 设置卸载程序

### Step 7.5: 最终测试
- [ ] 在干净的 Windows 系统上测试
- [ ] 确认无需安装额外依赖
- [ ] 测试所有功能正常

**完成标志**: 生成可独立运行的 Windows 应用程序，双击即可使用

---

## 📦 最终交付清单

### 开发阶段交付物
- [x] 可运行的 Python 后端服务
- [x] 可运行的 Flutter 桌面应用
- [x] 完整的源代码（前端 + 后端）

### 最终用户交付物
- [ ] Windows 可执行程序（.exe）
- [ ] 用户使用说明（README）
- [ ] 可选：安装包程序

---

## 🚨 风险和注意事项

### 技术风险
1. **HEIC 格式支持**: pillow-heif 在 Windows 上可能需要额外的编译工具
   - **解决方案**: 提前测试，必要时使用预编译的 wheel 文件

2. **后端进程管理**: Flutter 启动/停止外部进程可能不稳定
   - **解决方案**: 使用端口检测确认后端状态，添加重试机制

3. **打包体积**: Flutter Windows 应用 + Python 后端可能较大（50MB+）
   - **解决方案**: 可接受，这是桌面应用的正常大小

### 开发风险
1. **依赖安装失败**: 某些 Python 包可能需要 C++ 编译器
   - **解决方案**: 使用 Anaconda 或预编译 wheel

2. **Flutter 环境配置复杂**: 首次配置可能遇到问题
   - **解决方案**: 严格按照官方文档操作，使用 flutter doctor 诊断

---

## 📊 时间估算总结

| 阶段 | 预计时间 | 关键里程碑 |
|------|---------|-----------|
| Phase 0: 环境准备 | 1-2 小时 | Flutter doctor 通过 |
| Phase 1: 后端搭建 | 4 小时 | API 正常运行 |
| Phase 2: 前端基础 | 4 小时 | UI 框架完成 |
| Phase 3: 核心功能 | 8 小时 | 转换功能可用 |
| Phase 4: UI 优化 | 4 小时 | 界面美化完成 |
| Phase 5: 进程管理 | 3-4 小时 | 一键启动 |
| Phase 6: 测试优化 | 3-4 小时 | 稳定运行 |
| Phase 7: 打包发布 | 2-3 小时 | 生成 exe |
| **总计** | **3-5 天** | **可发布应用** |

---

## ✅ 阶段性验收标准

### Phase 1 验收
- [ ] 可以通过 Swagger UI 上传图片并转换成功
- [ ] 支持至少 3 种格式互转（JPG、PNG、WebP）

### Phase 3 验收
- [ ] 可以通过 UI 选择/拖拽图片
- [ ] 点击"开始转换"后能正确调用后端
- [ ] 转换后的图片保存到指定目录

### Phase 5 验收
- [ ] 启动 Flutter 应用后，后端自动启动
- [ ] 无需手动运行 Python 脚本

### Phase 7 验收
- [ ] 在其他电脑上可以直接运行 exe
- [ ] 所有功能正常工作

---

## 🎓 学习资源（参考）

### Flutter 官方文档
- https://docs.flutter.dev/desktop

### FastAPI 官方文档
- https://fastapi.tiangolo.com/

### Pillow 文档
- https://pillow.readthedocs.io/

---

## 📝 备注

- 本计划采用**增量开发**方式，每个 Phase 完成后都有可运行的阶段性成果
- 使用 **AI 辅助编程**时，建议每个 Step 完成后立即测试验证
- 遇到问题时，优先查看错误日志，然后搜索 GitHub Issues
- 建议使用 Git 进行版本控制，每个 Phase 完成后提交一次

---

**文档版本**: v1.0  
