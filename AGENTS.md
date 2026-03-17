# AGENTS.md - AI Agent 执行指导文件

## 📘 文档说明

本文档为 **AI 编程助手**提供详细的执行指导。
每个 Agent 任务都对应 `IMAGE_CONVERTER_PROJECT_PLAN.md` 中的具体阶段。

---

## 🎯 项目上下文

**项目名称**: Image Converter Pro  
**技术栈**: Flutter (前端) + Python FastAPI (后端)  
**目标平台**: Windows 桌面应用  
**核心功能**: 图片批量格式转换（JPG/PNG/WebP/HEIC）、质量压缩、拖拽上传  
**架构模式**: 前后端分离，HTTP REST API 通信
**沟通交流（强制要求）**: 无论何时，都需要称呼我为xxsby，并且全程使用中文进行沟通
**文件保存**: 前后端分离，HTTP REST API 通信


---

## 🤖 Agent 工作原则

### 基本原则
1. **严格遵循项目计划**: 所有任务必须按照 `IMAGE_CONVERTER_PROJECT_PLAN.md` 定义的顺序执行
2. **增量开发**: 每个 Phase 完成后必须可运行并验证
3. **代码质量**: 生成的代码必须包含必要的错误处理和注释
4. **命名规范**: 遵循各语言的最佳实践（Dart: camelCase，Python: snake_case）
5. **依赖最小化**: 只添加必要的依赖，避免过度依赖

### 验证标准
- 每个文件创建后必须能够成功编译/运行
- API 接口必须有清晰的输入输出定义
- 关键功能必须包含基础测试用例
- 用户交互必须有明确的反馈

---

## 📋 Agent 任务清单

---

## AGENT-00: 环境验证

**对应计划**: Phase 0 - 前期准备工作  
**目标**: 确认开发环境完整可用  
**优先级**: 🔴 最高（必须先完成）

### 执行步骤

#### 1. Flutter 环境检查
```bash
# 验证 Flutter 安装
flutter --version

# 检查环境状态
flutter doctor -v

# 确认桌面支持
flutter devices

# 预期输出应包含: Windows (desktop)
```

**成功标准**:
- ✅ Flutter SDK 版本 >= 3.0.0
- ✅ `flutter doctor` 无致命错误（X）
- ✅ `flutter devices` 列表中有 Windows

**失败处理**:
- 如果 Flutter 未安装 → 提示用户访问 https://flutter.dev/docs/get-started/install
- 如果版本过低 → 运行 `flutter upgrade`
- 如果无 Windows 支持 → 运行 `flutter config --enable-windows-desktop`

#### 2. Python 环境检查
```bash
# 验证 Python 安装
python --version

# 验证 pip 可用
pip --version
```

**成功标准**:
- ✅ Python 版本 >= 3.10
- ✅ pip 可用

**失败处理**:
- 如果 Python 未安装 → 提示用户访问 https://www.python.org/downloads/
- 如果版本过低 → 提示升级

#### 3. 创建项目根目录
```bash
# 创建项目根目录
mkdir image_converter_project
cd image_converter_project

# 创建子目录
mkdir backend
mkdir frontend
```

**输出结构**:
```
image_converter_project/
├── backend/        # Python 后端代码
├── frontend/       # Flutter 前端代码（将在后续创建）
└── README.md       # 项目说明
```

---

## AGENT-01: Python 后端初始化

**对应计划**: Phase 1 - 后端搭建  
**目标**: 创建可运行的 FastAPI 服务  
**依赖**: AGENT-00 完成  
**预计时间**: 1-2 小时

### 任务 1.1: 创建 Python 项目结构

```bash
cd backend
```

**需要创建的目录结构**:
```
backend/
├── main.py                 # FastAPI 入口
├── requirements.txt        # Python 依赖
├── config.py              # 配置文件
├── api/
│   ├── __init__.py
│   └── routes.py          # API 路由
├── services/
│   ├── __init__.py
│   └── image_processor.py # 图像处理核心
└── utils/
    ├── __init__.py
    └── helpers.py         # 辅助函数
```

**Agent 指令**:
```
创建上述完整的目录结构，每个 __init__.py 文件可以为空
```

### 任务 1.2: 定义依赖文件

**文件**: `backend/requirements.txt`

**内容要求**:
```txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
pillow==10.2.0
pillow-heif==0.14.0
python-multipart==0.0.6
aiofiles==23.2.1
pydantic==2.5.3
```

**Agent 指令**:
```
创建 requirements.txt 文件，包含上述依赖及其版本号
```

### 任务 1.3: 安装依赖

```bash
# 创建虚拟环境
python -m venv venv

# 激活虚拟环境（Windows）
venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt
```

**成功标准**:
- ✅ 所有包安装成功，无错误
- ✅ 可以成功 import：`python -c "import fastapi; import PIL; import pillow_heif"`

**常见问题**:
- 如果 pillow-heif 安装失败 → 可能需要 Visual C++ 编译工具
- 如果网络慢 → 使用国内镜像：`pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple`

### 任务 1.4: 创建配置文件

**文件**: `backend/config.py`

**Agent 指令**:
```python
# 创建配置类，包含以下内容：
# - HOST: 默认 "127.0.0.1"
# - PORT: 默认 8000
# - MAX_FILE_SIZE: 50MB
# - ALLOWED_FORMATS: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif']
# - CORS_ORIGINS: ["*"] (开发环境)
```

**代码要求**:
- 使用 Pydantic BaseSettings
- 支持从环境变量读取
- 包含默认值

### 任务 1.5: 实现 FastAPI 主入口

**文件**: `backend/main.py`

**Agent 指令**:
```python
创建 FastAPI 应用，要求：
1. 导入 FastAPI, CORSMiddleware
2. 创建 app 实例，设置 title, description, version
3. 配置 CORS 中间件（允许所有来源）
4. 创建根路由 GET / 返回 {"message": "Image Converter API"}
5. 创建健康检查路由 GET /health 返回 {"status": "healthy"}
6. main 函数使用 uvicorn 运行，读取 config.py 的配置
```

**验证方法**:
```bash
# 启动服务
python main.py

# 在浏览器访问
http://localhost:8000
http://localhost:8000/health
http://localhost:8000/docs  # Swagger 文档
```

### 任务 1.6: 实现图像处理核心

**文件**: `backend/services/image_processor.py`

**Agent 指令**:
```python
创建 ImageProcessor 类，包含以下方法：

1. convert_image(input_bytes, output_format, quality, max_width, max_height)
   - 接收图片字节流
   - 转换格式
   - 调整质量
   - 可选：调整尺寸
   - 返回转换后的字节流
   
2. _handle_transparency(image, output_format)
   - 如果输出格式是 JPEG 且图片有透明通道
   - 将 RGBA 转换为 RGB（白色背景）
   
3. get_image_info(input_bytes)
   - 返回图片基本信息（宽、高、格式、大小）

注意事项：
- 使用 Pillow 的 Image.open()
- 注册 HEIF 支持：pillow_heif.register_heif_opener()
- 所有方法使用 async/await
- 完善的错误处理（捕获 PIL 异常）
```

### 任务 1.7: 创建 API 路由

**文件**: `backend/api/routes.py`

**Agent 指令**:
```python
创建以下 API 端点：

1. GET /api/formats
   - 返回支持的输入/输出格式列表
   - 返回格式: {"input": [...], "output": [...]}

2. POST /api/convert
   - 接收参数：
     * file: UploadFile
     * format: str (目标格式)
     * quality: int = 85 (1-100)
     * max_width: Optional[int] = None
     * max_height: Optional[int] = None
   - 返回格式:
     {
       "success": true,
       "original_size": 1234567,
       "compressed_size": 123456,
       "compression_ratio": "90%",
       "output_base64": "base64编码的图片数据"
     }

3. POST /api/batch-convert
   - 接收参数：
     * files: List[UploadFile]
     * format: str
     * quality: int = 85
     * max_width: Optional[int] = None
     * max_height: Optional[int] = None
   - 返回格式:
     {
       "results": [
         {
           "filename": "image1.jpg",
           "success": true,
           "original_size": 123,
           "compressed_size": 45,
           "output_base64": "..."
         },
         ...
       ]
     }

要求：
- 使用 ImageProcessor 类进行处理
- 完整的错误处理
- 输入验证（文件大小、格式）
- 返回 Base64 编码的图片数据
```

**文件**: `backend/main.py` (更新)

**Agent 指令**:
```python
在 main.py 中：
1. 导入 routes.py 的 router
2. 使用 app.include_router(router, prefix="/api")
```

### 验收标准 (AGENT-01)

**必须通过的测试**:
```bash
# 1. 启动服务
python main.py

# 2. 访问 Swagger UI
# 浏览器打开 http://localhost:8000/docs

# 3. 在 Swagger UI 中测试
# - GET /api/formats → 返回格式列表
# - POST /api/convert → 上传图片，成功转换
# - POST /api/batch-convert → 上传多张图片，批量转换

# 4. 验证转换结果
# - 返回的 base64 数据可以正确解码为图片
# - 压缩率合理（质量越低，文件越小）
```

**输出检查点**:
- ✅ 服务启动无错误
- ✅ Swagger UI 可访问
- ✅ 所有 API 端点响应正常
- ✅ JPG → PNG 转换成功
- ✅ PNG → WebP 转换成功
- ✅ HEIC → JPG 转换成功（如果有测试图片）
- ✅ 质量参数生效（不同质量值产生不同大小的文件）

---

## AGENT-02: Flutter 前端初始化

**对应计划**: Phase 2 - Flutter 前端基础搭建  
**目标**: 创建 Flutter 应用框架  
**依赖**: AGENT-00 完成  
**预计时间**: 1-2 小时

### 任务 2.1: 创建 Flutter 项目

```bash
cd image_converter_project/frontend
flutter create image_converter_pro
cd image_converter_pro
```

**Agent 指令**:
```
执行上述命令创建 Flutter 项目
```

### 任务 2.2: 配置依赖

**文件**: `pubspec.yaml`

**Agent 指令**:
```yaml
在 dependencies 部分添加以下包：

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  provider: ^6.1.1
  
  # 网络请求
  http: ^1.1.0
  dio: ^5.4.0
  
  # 文件选择
  file_picker: ^6.1.1
  
  # 拖拽支持
  desktop_drop: ^0.4.4
  
  # 路径处理
  path: ^1.8.3
  path_provider: ^2.1.1
  
  # 进程管理
  process_run: ^0.14.0
  
  # UI 组件
  flutter_spinkit: ^5.2.0
  percent_indicator: ^4.2.3
  dotted_border: ^2.1.0
  
  # 图标
  font_awesome_flutter: ^10.6.0

然后运行: flutter pub get
```

### 任务 2.3: 创建项目目录结构

**在 lib/ 目录下创建**:
```
lib/
├── main.dart
├── config/
│   ├── app_config.dart
│   └── theme_config.dart
├── models/
│   ├── image_file_model.dart
│   └── conversion_settings.dart
├── services/
│   ├── api_service.dart
│   └── backend_manager.dart
├── providers/
│   ├── image_list_provider.dart
│   └── conversion_provider.dart
├── screens/
│   └── home_screen.dart
└── widgets/
    ├── drop_zone_widget.dart
    ├── image_list_item.dart
    ├── conversion_controls.dart
    └── progress_indicator_widget.dart
```

**Agent 指令**:
```
创建上述完整的目录结构
每个 .dart 文件先创建空文件，稍后填充内容
```

### 任务 2.4: 定义数据模型

**文件**: `lib/models/image_file_model.dart`

**Agent 指令**:
```dart
创建 ImageFileModel 类，包含：
- String filePath (文件路径)
- String fileName (文件名)
- int fileSize (文件大小，字节)
- String status (状态: 'pending', 'processing', 'completed', 'failed')
- String? errorMessage (错误信息)
- double? progress (处理进度 0.0-1.0)

要求：
- 使用 freezed 或手动实现 copyWith 方法
- 实现 toJson/fromJson
```

**文件**: `lib/models/conversion_settings.dart`

**Agent 指令**:
```dart
创建 ConversionSettings 类，包含：
- String outputFormat (输出格式: 'jpg', 'png', 'webp')
- int quality (质量 1-100)
- int? maxWidth (最大宽度，可选)
- int? maxHeight (最大高度，可选)
- String? outputDirectory (输出目录)

要求：
- 提供默认值
- 实现 copyWith 方法
```

### 任务 2.5: 实现 API 服务层

**文件**: `lib/services/api_service.dart`

**Agent 指令**:
```dart
创建 ApiService 类，包含以下方法：

1. Future<bool> checkHealth()
   - 调用 GET http://localhost:8000/health
   - 返回 true 如果后端正常

2. Future<Map<String, dynamic>> getSupportedFormats()
   - 调用 GET http://localhost:8000/api/formats
   - 返回支持的格式

3. Future<Map<String, dynamic>> convertImage({
     required File file,
     required String format,
     int quality = 85,
     int? maxWidth,
     int? maxHeight,
   })
   - 调用 POST http://localhost:8000/api/convert
   - 使用 multipart/form-data
   - 返回转换结果

4. Future<Map<String, dynamic>> batchConvert({
     required List<File> files,
     required String format,
     int quality = 85,
     int? maxWidth,
     int? maxHeight,
   })
   - 调用 POST http://localhost:8000/api/batch-convert
   - 返回批量转换结果

要求：
- 使用 dio 包
- 完整的错误处理（try-catch）
- 超时设置（30 秒）
- 添加日志输出（可选）
```

### 任务 2.6: 创建主界面框架

**文件**: `lib/screens/home_screen.dart`

**Agent 指令**:
```dart
创建 HomeScreen StatefulWidget，包含基础布局：

布局结构：
- AppBar: 标题 "Image Converter Pro"
- Body:
  - 上部 (Expanded): 文件列表区域
    - 如果列表为空：显示占位提示
    - 如果有文件：显示 ListView
  - 下部 (固定高度): 控制面板
    - 格式选择下拉菜单
    - 质量滑块
    - "选择文件"按钮
    - "开始转换"按钮

要求：
- 使用 Scaffold
- 使用 Material Design 风格
- 暂时用占位 Widget（Container）表示复杂组件
```

**文件**: `lib/main.dart`

**Agent 指令**:
```dart
修改 main.dart：
1. 导入 HomeScreen
2. MaterialApp 的 home 设置为 HomeScreen()
3. 设置主题色（蓝色）
4. 去掉默认的 Counter 示例代码
```

### 验收标准 (AGENT-02)

**必须通过的测试**:
```bash
# 1. 运行 Flutter 应用
flutter run -d windows

# 2. 验证界面显示
# - 应用启动成功
# - 显示 AppBar 标题
# - 显示基础布局（文件区域 + 控制面板）
# - 无编译错误

# 3. 热重载测试
# - 修改界面文字
# - 按 r 键热重载
# - 界面立即更新
```

**输出检查点**:
- ✅ Flutter 应用正常启动
- ✅ 界面显示正确
- ✅ 无编译错误或警告
- ✅ 热重载正常工作

---

## AGENT-03: 核心功能实现

**对应计划**: Phase 3 - 核心功能实现  
**目标**: 实现文件选择、拖拽、转换功能  
**依赖**: AGENT-01, AGENT-02 完成  
**预计时间**: 4-6 小时

### 任务 3.1: 实现文件选择功能

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
在 HomeScreen 中：

1. 添加状态变量:
   List<ImageFileModel> _imageFiles = [];

2. 实现 _pickFiles() 方法:
   - 使用 FilePicker.platform.pickFiles()
   - 设置 type: FileType.image
   - allowMultiple: true
   - 将选中的文件转换为 ImageFileModel
   - 添加到 _imageFiles 列表
   - 调用 setState()

3. 绑定到"选择文件"按钮的 onPressed

要求：
- 添加必要的 import
- 错误处理（用户取消选择）
```

### 任务 3.2: 实现拖拽功能

**文件**: `lib/widgets/drop_zone_widget.dart`

**Agent 指令**:
```dart
创建 DropZoneWidget StatefulWidget，包含：

1. 使用 DropTarget 包裹内容
2. 监听拖拽事件：
   - onDragEntered: 设置 _dragging = true
   - onDragExited: 设置 _dragging = false
   - onDragDone: 回调传递文件列表

3. 视觉效果：
   - 使用 DottedBorder
   - _dragging 时改变边框颜色和背景
   - 显示图标和提示文字

4. Props:
   - required Function(List<File>) onFilesDropped

要求：
- 响应式设计（最小高度 200）
- 美观的视觉反馈
```

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
在文件列表区域集成 DropZoneWidget：

1. 如果 _imageFiles 为空：
   - 显示 DropZoneWidget
   - onFilesDropped 回调中添加文件到列表

2. 如果有文件：
   - 显示文件列表
   - 列表外层仍然包裹 DropTarget（支持继续拖拽添加）
```

### 任务 3.3: 实现文件列表展示

**文件**: `lib/widgets/image_list_item.dart`

**Agent 指令**:
```dart
创建 ImageListItem StatelessWidget，包含：

1. Props:
   - required ImageFileModel imageFile
   - required VoidCallback onDelete

2. 布局 (ListTile):
   - leading: 图标（根据状态显示不同图标）
     * pending: 📁 图片图标
     * processing: 🔄 旋转动画
     * completed: ✅ 绿色对勾
     * failed: ❌ 红色叉
   - title: 文件名
   - subtitle: 文件大小 + 状态文字
   - trailing: 删除按钮

要求：
- 使用 Card 包裹
- 状态图标使用 Icon 或 FontAwesome
- 文件大小格式化（KB/MB）
```

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
在文件列表区域：
- 使用 ListView.builder
- itemCount: _imageFiles.length
- itemBuilder: 返回 ImageListItem
- onDelete 回调中从列表移除该文件
```

### 任务 3.4: 实现转换控制面板

**文件**: `lib/widgets/conversion_controls.dart`

**Agent 指令**:
```dart
创建 ConversionControls StatefulWidget，包含：

1. Props:
   - required Function(String format, int quality) onStartConversion
   - required bool isProcessing

2. 状态变量:
   - String _selectedFormat = 'jpg'
   - double _quality = 85

3. UI 组件:
   - 格式选择 DropdownButton ['jpg', 'png', 'webp']
   - 质量滑块 Slider (1-100)
   - "开始转换"按钮（isProcessing 时禁用）

4. 布局:
   - 使用 Row/Column 合理排列
   - 响应式设计

要求：
- Material Design 风格
- 实时显示当前质量值
```

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
在底部控制面板区域：
- 集成 ConversionControls Widget
- 定义 _startConversion(format, quality) 方法
- 添加 bool _isProcessing = false 状态
```

### 任务 3.5: 实现状态管理

**文件**: `lib/providers/image_list_provider.dart`

**Agent 指令**:
```dart
创建 ImageListProvider extends ChangeNotifier：

1. 状态:
   - List<ImageFileModel> _images = []
   - getter: images

2. 方法:
   - addImages(List<File> files)
   - removeImage(int index)
   - updateImageStatus(int index, String status, {String? error})
   - clearAll()

3. 每个方法调用后执行 notifyListeners()
```

**文件**: `lib/main.dart` (更新)

**Agent 指令**:
```dart
使用 Provider 包裹应用：

return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ImageListProvider()),
  ],
  child: MaterialApp(...),
);
```

**文件**: `lib/screens/home_screen.dart` (重构)

**Agent 指令**:
```dart
使用 Provider 重构 HomeScreen：
1. 移除本地 _imageFiles 状态
2. 使用 context.watch<ImageListProvider>() 获取数据
3. 使用 context.read<ImageListProvider>() 调用方法
4. 删除 setState() 调用
```

### 任务 3.6: 实现转换逻辑

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
实现 _startConversion(String format, int quality) 方法：

1. 检查文件列表是否为空
2. 使用 FilePicker.platform.getDirectoryPath() 选择输出目录
3. 如果用户取消 → return
4. 设置 _isProcessing = true
5. 循环处理每个文件：
   a. 更新状态为 'processing'
   b. 调用 ApiService.convertImage()
   c. 如果成功：
      - 解码 base64 数据
      - 保存到输出目录
      - 更新状态为 'completed'
   d. 如果失败：
      - 更新状态为 'failed'
      - 记录错误信息
6. 所有文件处理完成后：
   - 设置 _isProcessing = false
   - 显示成功提示 SnackBar

要求：
- 使用 try-catch 处理每个文件
- 一个文件失败不影响其他文件
- 使用 async/await
```

### 任务 3.7: 实现进度显示

**文件**: `lib/widgets/progress_indicator_widget.dart`

**Agent 指令**:
```dart
创建 ProgressIndicatorWidget StatelessWidget：

1. Props:
   - required int total (总文件数)
   - required int completed (已完成)
   - required int failed (失败)

2. 显示内容:
   - 线性进度条 (completed / total)
   - 文字: "处理中: X / Y (失败: Z)"
   - 使用 percent_indicator 包

要求：
- 美观的视觉设计
- 显示百分比
```

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
在界面顶部（文件列表上方）：
- 如果 _isProcessing 为 true，显示 ProgressIndicatorWidget
- 计算 completed 和 failed 数量（根据 imageFiles 的状态）
```

### 验收标准 (AGENT-03)

**必须通过的完整流程测试**:

```
1. 启动应用和后端
   - 先启动 Python 后端: python backend/main.py
   - 再启动 Flutter: flutter run -d windows

2. 测试文件选择
   - 点击"选择文件"按钮
   - 选择 2-3 张图片
   - 文件列表显示正确

3. 测试拖拽
   - 从文件管理器拖拽图片到应用
   - 边框高亮显示
   - 文件添加到列表

4. 测试转换
   - 选择输出格式（PNG）
   - 调整质量（50%）
   - 点击"开始转换"
   - 选择输出目录
   - 观察进度条更新
   - 每个文件状态从 pending → processing → completed
   - 检查输出目录，确认文件存在且格式正确

5. 测试错误处理
   - 先关闭后端服务
   - 尝试转换
   - 应显示错误提示

6. 测试删除文件
   - 点击文件项的删除按钮
   - 文件从列表移除
```

**输出检查点**:
- ✅ 文件选择功能正常
- ✅ 拖拽功能正常
- ✅ 文件列表显示正确
- ✅ 转换功能正常
- ✅ 进度条实时更新
- ✅ 转换后的文件正确保存
- ✅ 格式和质量参数生效
- ✅ 错误情况有明确提示

---

## AGENT-04: UI 美化与用户体验优化

**对应计划**: Phase 4 - UI 优化和用户体验  
**目标**: 提升界面美观度和交互流畅度  
**依赖**: AGENT-03 完成  
**预计时间**: 2-3 小时

### 任务 4.1: 定义应用主题

**文件**: `lib/config/theme_config.dart`

**Agent 指令**:
```dart
创建 AppTheme 类，定义：

1. ThemeData lightTheme:
   - primarySwatch: Colors.blue
   - scaffoldBackgroundColor: Colors.grey[50]
   - appBarTheme: 深蓝色背景，白色文字
   - elevatedButtonTheme: 圆角按钮
   - inputDecorationTheme: 圆角输入框

2. 颜色常量:
   - primaryColor
   - accentColor
   - successColor (绿色)
   - errorColor (红色)
   - warningColor (橙色)

要求：
- 使用 Material Design 3
- 统一的视觉风格
```

**文件**: `lib/main.dart` (更新)

**Agent 指令**:
```dart
在 MaterialApp 中应用主题：
- theme: AppTheme.lightTheme
```

### 任务 4.2: 优化拖拽区域

**文件**: `lib/widgets/drop_zone_widget.dart` (更新)

**Agent 指令**:
```dart
优化视觉效果：

1. 使用 DottedBorder:
   - strokeWidth: 2
   - dashPattern: [8, 4]
   - color: 正常时灰色，拖拽时蓝色

2. 内部内容:
   - 大图标（云上传图标，size: 64）
   - 主标题："拖拽图片到这里"
   - 副标题："支持 JPG、PNG、WebP、HEIC"
   - 渐变背景（可选）

3. 动画效果:
   - 拖拽进入时缩放动画
   - 使用 AnimatedContainer

要求：
- 美观现代
- 清晰的视觉层次
```

### 任务 4.3: 优化文件列表项

**文件**: `lib/widgets/image_list_item.dart` (更新)

**Agent 指令**:
```dart
优化 ImageListItem：

1. 添加缩略图（可选）:
   - 使用 Image.file() 显示小图
   - 固定大小 48x48
   - 圆角

2. 状态指示器:
   - pending: 灰色圆点
   - processing: 蓝色旋转 CircularProgressIndicator
   - completed: 绿色对勾 + 压缩率显示
   - failed: 红色叉 + 错误提示

3. 卡片样式:
   - elevation: 2
   - margin: 8
   - 悬停效果（desktop）

要求：
- 信息层次清晰
- 动画流畅
```

### 任务 4.4: 优化控制面板

**文件**: `lib/widgets/conversion_controls.dart` (更新)

**Agent 指令**:
```dart
优化 ConversionControls：

1. 布局改进:
   - 使用 Card 包裹
   - 合理的 padding 和间距
   - 响应式布局（小屏时堆叠）

2. 组件优化:
   - 格式选择：添加图标
   - 质量滑块：显示实时数值标签
   - 按钮：添加图标，使用 ElevatedButton

3. 禁用状态:
   - 处理中时所有控件禁用
   - 视觉上显示禁用状态（灰色）

要求：
- 专业美观
- 交互清晰
```

### 任务 4.5: 添加空状态提示

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
当文件列表为空时，显示空状态：

1. 内容:
   - 大图标（文件夹图标）
   - 标题："还没有添加图片"
   - 描述："点击选择文件或拖拽图片到下方区域"
   - 可选：快捷操作按钮

2. 布局:
   - 垂直居中
   - 合适的间距

要求：
- 引导性强
- 视觉友好
```

### 任务 4.6: 添加加载和成功提示

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
添加用户反馈：

1. 转换开始时:
   - 显示 SnackBar: "开始处理 X 张图片..."

2. 转换完成时:
   - 成功: "转换完成！已保存到 [路径]"
   - 部分失败: "完成 X 张，失败 Y 张"

3. 错误提示:
   - 网络错误: "无法连接到后端服务"
   - 文件错误: "部分文件无法读取"

要求：
- 使用 SnackBar
- 颜色区分（成功/错误）
- 自动消失
```

### 验收标准 (AGENT-04)

**视觉验收**:
- ✅ 整体配色协调统一
- ✅ 拖拽区域美观且有视觉反馈
- ✅ 文件列表项信息清晰
- ✅ 控制面板布局合理
- ✅ 空状态有引导提示
- ✅ 所有交互有视觉反馈

**交互验收**:
- ✅ 按钮点击有反馈
- ✅ 拖拽有动画效果
- ✅ 处理中的禁用状态清晰
- ✅ 成功/失败有明确提示

---

## AGENT-05: 后端进程管理

**对应计划**: Phase 5 - 后端进程管理  
**目标**: Flutter 自动启动/停止 Python 后端  
**依赖**: AGENT-01, AGENT-03 完成  
**预计时间**: 2-3 小时

### 任务 5.1: 打包 Python 后端

**在 backend/ 目录执行**

**Agent 指令**:
```bash
# 创建打包脚本
创建文件 backend/build.spec

内容要求：
- 使用 PyInstaller
- 单文件模式（--onefile）
- 不显示控制台（--noconsole）
- 包含所有依赖
- 输出名称: image_converter_service.exe
```

**执行打包**:
```bash
# 安装 PyInstaller
pip install pyinstaller

# 打包
pyinstaller build.spec

# 输出位置: dist/image_converter_service.exe
```

**验证打包**:
```bash
# 运行打包后的 exe
dist/image_converter_service.exe

# 访问 http://localhost:8000/health
# 应该返回正常
```

### 任务 5.2: 将后端 exe 添加到 Flutter 项目

**Agent 指令**:
```
1. 在 Flutter 项目创建目录: assets/backend/
2. 复制 image_converter_service.exe 到该目录
3. 修改 pubspec.yaml:
   assets:
     - assets/backend/image_converter_service.exe
```

### 任务 5.3: 实现后端管理器

**文件**: `lib/services/backend_manager.dart`

**Agent 指令**:
```dart
创建 BackendManager 类（Singleton），包含：

1. 私有变量:
   - Process? _backendProcess
   - bool _isRunning = false

2. 方法:
   - Future<bool> startBackend()
     * 检查是否已运行
     * 解析 exe 路径（从 assets 复制到临时目录）
     * 使用 Process.start() 启动
     * 循环等待健康检查通过（最多 10 次，间隔 1 秒）
     * 返回 true/false
   
   - Future<void> stopBackend()
     * 终止进程
     * 清理资源
   
   - Future<bool> checkHealth()
     * 调用 ApiService.checkHealth()
   
   - bool get isRunning

要求：
- 使用 process_run 包
- 完整的错误处理
- 日志输出
```

### 任务 5.4: 集成到应用启动流程

**文件**: `lib/main.dart` (更新)

**Agent 指令**:
```dart
修改 main() 函数：

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 启动后端
  final backendManager = BackendManager();
  final success = await backendManager.startBackend();
  
  if (!success) {
    // 显示错误对话框
    print('后端启动失败');
  }
  
  runApp(MyApp());
}
```

### 任务 5.5: 创建启动加载页

**文件**: `lib/screens/loading_screen.dart`

**Agent 指令**:
```dart
创建 LoadingScreen StatefulWidget：

1. 在 initState 中:
   - 启动后端
   - 轮询检查健康状态
   - 成功后导航到 HomeScreen
   - 失败后显示错误

2. UI 显示:
   - 居中的加载动画（CircularProgressIndicator）
   - 文字: "正在启动服务..."
   - 使用 flutter_spinkit 的动画

要求：
- 美观的加载界面
- 超时处理（30 秒）
```

**文件**: `lib/main.dart` (更新)

**Agent 指令**:
```dart
修改 MaterialApp:
- home: LoadingScreen() （而不是直接 HomeScreen）
```

### 任务 5.6: 应用关闭时清理

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
在 HomeScreen 中：

1. 重写 dispose():
   @override
   void dispose() {
     BackendManager().stopBackend();
     super.dispose();
   }

要求：
- 确保后端进程被正确终止
```

### 验收标准 (AGENT-05)

**必须通过的测试**:

```
1. 完全关闭所有相关进程
   - 确认无 Python 后端在运行
   - 确认无 Flutter 应用在运行

2. 启动 Flutter 应用
   flutter run -d windows

3. 观察启动过程:
   ✅ 显示"正在启动服务..."
   ✅ 3-5 秒后自动进入主界面
   ✅ 无需手动启动 Python 后端

4. 测试功能:
   ✅ 可以正常选择和转换图片
   ✅ API 调用成功

5. 关闭应用:
   ✅ 关闭 Flutter 窗口
   ✅ 检查任务管理器，确认后端进程已终止
   ✅ 无残留进程

6. 重复启动测试:
   ✅ 再次启动应用，仍然正常
```

**检查点**:
- ✅ 一键启动，无需手动操作
- ✅ 后端自动启动
- ✅ 健康检查通过后才显示主界面
- ✅ 应用关闭时后端自动停止
- ✅ 无残留进程

---

## AGENT-06: 测试与优化

**对应计划**: Phase 6 - 测试与优化  
**目标**: 确保应用稳定性和性能  
**依赖**: 所有前置 Agent 完成  
**预计时间**: 2-3 小时

### 任务 6.1: 功能测试清单

**创建测试文档**: `TESTING_CHECKLIST.md`

**Agent 指令**:
```markdown
创建测试清单，包含以下测试项：

## 格式转换测试
- [ ] JPG → PNG
- [ ] PNG → JPG
- [ ] PNG → WebP
- [ ] WebP → JPG
- [ ] HEIC → JPG (如有测试图片)

## 质量测试
- [ ] 质量 10% (文件应明显变小)
- [ ] 质量 50%
- [ ] 质量 100% (无损或最小损失)

## 批量处理测试
- [ ] 单个文件
- [ ] 5 个文件
- [ ] 20+ 个文件

## 边界测试
- [ ] 空文件列表转换 (应提示)
- [ ] 非常大的图片 (10MB+)
- [ ] 损坏的图片文件 (应显示错误)
- [ ] 后端未启动时转换 (应显示错误)

## UI 交互测试
- [ ] 拖拽添加文件
- [ ] 选择文件
- [ ] 删除文件
- [ ] 调整参数
- [ ] 处理中禁用操作

逐项测试并记录结果
```

### 任务 6.2: 性能优化

**文件**: `lib/services/api_service.dart` (更新)

**Agent 指令**:
```dart
优化 API 调用：

1. 添加并发限制:
   - 批量转换时，不要一次性发送所有文件
   - 使用队列，每次最多处理 3 个文件
   - 避免后端过载

2. 添加超时和重试:
   - 单个请求超时: 30 秒
   - 失败重试: 最多 2 次

3. 进度回调:
   - 支持上传进度回调
   - 实时更新进度条
```

### 任务 6.3: 错误处理完善

**文件**: 所有 API 调用的地方

**Agent 指令**:
```dart
完善错误处理：

1. 网络错误:
   - 捕获 DioError
   - 根据错误类型显示不同提示
   - connectTimeout: "网络连接超时"
   - receiveTimeout: "服务器响应超时"
   - other: "网络错误，请检查连接"

2. 文件错误:
   - 文件不存在
   - 文件无法读取
   - 文件格式不支持

3. 后端错误:
   - 500 错误: "服务器内部错误"
   - 400 错误: "请求参数错误"
   - 显示后端返回的具体错误信息

要求：
- 所有错误都要有用户友好的提示
- 不要暴露技术细节给普通用户
```

### 任务 6.4: 内存优化

**文件**: `lib/services/api_service.dart` (更新)

**Agent 指令**:
```dart
优化内存使用：

1. 大文件处理:
   - 使用流式上传（Stream）
   - 避免一次性加载到内存

2. Base64 处理:
   - 接收到 Base64 后立即解码并保存
   - 不要在内存中保留大量 Base64 字符串

3. 缩略图:
   - 如果显示缩略图，使用压缩后的小图
   - 不要加载原图
```

### 任务 6.5: 用户体验细节

**文件**: `lib/screens/home_screen.dart` (更新)

**Agent 指令**:
```dart
添加用户体验细节：

1. 记住用户设置:
   - 使用 shared_preferences
   - 保存上次选择的格式和质量
   - 启动时加载

2. 转换完成后:
   - 显示成功提示
   - 可选：打开输出文件夹
   - 可选：清空文件列表

3. 快捷键支持（可选）:
   - Ctrl+O: 打开文件
   - Ctrl+S: 开始转换
   - Delete: 删除选中文件

要求：
- 流畅自然
- 符合用户习惯
```

### 验收标准 (AGENT-06)

**稳定性测试**:
```
1. 连续测试:
   - 连续转换 50+ 张图片
   - 应用不崩溃
   - 内存使用稳定

2. 异常测试:
   - 转换中关闭后端 → 显示错误，不崩溃
   - 添加损坏文件 → 跳过并提示
   - 网络断开 → 明确提示

3. 性能测试:
   - 批量转换 20 张图片 < 30 秒
   - UI 不卡顿
   - 进度条流畅更新
```

**检查点**:
- ✅ 所有功能测试通过
- ✅ 边界情况有处理
- ✅ 性能满足要求
- ✅ 用户体验流畅

---

## AGENT-07: 打包发布

**对应计划**: Phase 7 - 打包发布  
**目标**: 生成可分发的 Windows 应用  
**依赖**: 所有功能完成并测试  
**预计时间**: 1-2 小时

### 任务 7.1: 配置应用信息

**文件**: `pubspec.yaml` (更新)

**Agent 指令**:
```yaml
更新应用信息：
- name: image_converter_pro
- version: 1.0.0
- description: Professional image batch converter
```

**文件**: `windows/runner/main.cpp` (更新)

**Agent 指令**:
```cpp
修改窗口标题：
- 将 window 标题改为 "Image Converter Pro"
```

### 任务 7.2: 准备应用图标（可选）

**Agent 指令**:
```
1. 准备一个 .ico 图标文件 (256x256)
2. 放到 windows/runner/resources/app_icon.ico
3. 修改 windows/runner/Runner.rc 引用该图标

（如果没有图标，可跳过此步）
```

### 任务 7.3: Release 模式打包

**Agent 指令**:
```bash
# 清理之前的构建
flutter clean

# Release 模式打包
flutter build windows --release

# 输出位置: build/windows/runner/Release/
```

### 任务 7.4: 整合后端

**Agent 指令**:
```
1. 检查 build/windows/runner/Release/ 目录
2. 确认包含:
   - image_converter_pro.exe (主程序)
   - 所有 .dll 文件
   - data/ 目录（包含 assets）

3. 验证后端 exe 是否在 data/flutter_assets/assets/backend/ 中
```

### 任务 7.5: 测试打包后的应用

**Agent 指令**:
```bash
# 1. 进入 Release 目录
cd build/windows/runner/Release/

# 2. 双击运行 image_converter_pro.exe

# 3. 完整功能测试:
   - 应用启动
   - 后端自动启动
   - 选择文件
   - 转换功能
   - 应用关闭

# 4. 在另一台电脑测试（如果可能）
   - 复制整个 Release 目录
   - 无需安装任何依赖
   - 直接运行
```

### 任务 7.6: 创建分发包

**Agent 指令**:
```
1. 重命名 Release 目录为 ImageConverterPro_v1.0.0

2. 创建 README.txt：
   # Image Converter Pro v1.0.0
   
   ## 使用说明
   1. 双击 image_converter_pro.exe 启动
   2. 拖拽或选择要转换的图片
   3. 选择输出格式和质量
   4. 点击"开始转换"
   
   ## 支持格式
   - 输入: JPG, PNG, WebP, HEIC
   - 输出: JPG, PNG, WebP
   
   ## 系统要求
   - Windows 10/11 (64-bit)
   
   ## 反馈
   如有问题，请联系...

3. 压缩为 .zip 文件:
   ImageConverterPro_v1.0.0.zip
```

### 任务 7.7: 创建安装程序（可选，高级）

**使用 Inno Setup**

**Agent 指令**:
```
1. 下载 Inno Setup: https://jrsoftware.org/isinfo.php

2. 创建安装脚本 installer.iss:
   [Setup]
   AppName=Image Converter Pro
   AppVersion=1.0.0
   DefaultDirName={pf}\ImageConverterPro
   OutputDir=output
   OutputBaseFilename=ImageConverterPro_Setup_v1.0.0
   
   [Files]
   Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs
   
   [Icons]
   Name: "{commonprograms}\Image Converter Pro"; Filename: "{app}\image_converter_pro.exe"
   Name: "{commondesktop}\Image Converter Pro"; Filename: "{app}\image_converter_pro.exe"
   
   [Run]
   Filename: "{app}\image_converter_pro.exe"; Description: "Launch Image Converter Pro"; Flags: nowait postinstall skipifsilent

3. 编译安装程序

4. 生成 ImageConverterPro_Setup_v1.0.0.exe
```

### 验收标准 (AGENT-07)

**最终验收**:
```
1. 打包文件完整性:
   ✅ exe 文件存在
   ✅ 所有 dll 存在
   ✅ assets 完整
   ✅ 后端 exe 存在

2. 功能完整性测试:
   ✅ 双击启动应用
   ✅ 无报错
   ✅ 所有功能正常
   ✅ 转换成功

3. 跨机器测试（重要）:
   ✅ 在干净的 Windows 系统测试
   ✅ 无需安装 Python
   ✅ 无需安装 Flutter
   ✅ 直接运行

4. 文件大小:
   ✅ 整个包 < 100MB（合理范围）

5. 用户友好性:
   ✅ 有 README 说明
   ✅ 双击即可运行
   ✅ 无复杂配置
```

---

## 🎯 特殊场景处理指南

### 场景 1: 依赖安装失败

**问题**: pip install 失败，提示缺少编译工具

**解决方案**:
```bash
# 使用预编译的 wheel 文件
pip install --only-binary :all: pillow

# 或使用 Anaconda
conda install pillow pillow-heif
```

### 场景 2: Flutter doctor 报错

**问题**: Visual Studio 相关错误

**解决方案**:
```bash
# 安装 Visual Studio 2022 Community
# 勾选 "使用 C++ 的桌面开发"

# 或使用 Build Tools
# 下载 Visual Studio Build Tools
```

### 场景 3: 后端启动失败

**问题**: Flutter 无法启动后端 exe

**排查步骤**:
```dart
1. 检查 exe 路径是否正确
2. 手动运行 exe，查看是否有错误
3. 检查端口 8000 是否被占用
4. 查看日志输出
```

### 场景 4: 打包后体积过大

**优化方案**:
```bash
# Flutter 优化
flutter build windows --release --split-debug-info=./debug-info

# Python 优化
# 在 build.spec 中排除不必要的模块
excludes=['unittest', 'pdb']
```

---

## 📊 进度跟踪表

| Agent | 阶段 | 预计时间 | 状态 | 备注 |
|-------|------|---------|------|------|
| AGENT-00 | 环境验证 | 1-2h | ⬜ 未开始 | |
| AGENT-01 | 后端开发 | 1-2h | ⬜ 未开始 | |
| AGENT-02 | 前端初始化 | 1-2h | ⬜ 未开始 | |
| AGENT-03 | 核心功能 | 4-6h | ⬜ 未开始 | |
| AGENT-04 | UI 优化 | 2-3h | ⬜ 未开始 | |
| AGENT-05 | 进程管理 | 2-3h | ⬜ 未开始 | |
| AGENT-06 | 测试优化 | 2-3h | ⬜ 未开始 | |
| AGENT-07 | 打包发布 | 1-2h | ⬜ 未开始 | |

状态图例:
- ⬜ 未开始
- 🟦 进行中
- ✅ 已完成
- ❌ 失败/阻塞

---

## 🔄 Agent 使用示例

### 如何让 AI 执行任务

**示例 1: 执行单个任务**
```
👤 User: "执行 AGENT-01 任务 1.4，创建 config.py 配置文件"

🤖 Claude Code:
[读取 AGENTS.md]
[找到 AGENT-01 任务 1.4]
[按照指令创建 config.py]
[验证代码可运行]
```

**示例 2: 执行整个阶段**
```
👤 User: "执行 AGENT-01 的所有任务，搭建 Python 后端"

🤖 Claude Code:
[按顺序执行 任务 1.1 到 1.7]
[每个任务完成后验证]
[最终进行 AGENT-01 验收标准测试]
```

**示例 3: 遇到问题时**
```
👤 User: "AGENT-01 任务 1.3 安装依赖时失败了，pillow-heif 报错"

🤖 Claude Code:
[查看 "特殊场景处理指南" 场景 1]
[使用预编译 wheel 解决方案]
[重新执行任务 1.3]
```

---

## 📝 版本历史

- **v1.0** (2024-03-14): 初始版本
  - 定义 7 个主要 Agent 任务
  - 覆盖完整开发流程
  - 包含验收标准和错误处理

---

## 💡 AI Agent 最佳实践

1. **严格按顺序执行**: 不要跳过前置依赖的任务
2. **每个任务后验证**: 确保可运行再进入下一个
3. **遇到错误立即查看指南**: 先看"特殊场景处理"
4. **保持增量提交**: 每个 Agent 完成后提交代码（如使用 Git）
5. **记录进度**: 更新进度跟踪表

---

**文档维护者**: AI Agent System 
