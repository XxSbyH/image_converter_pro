# Image Converter Pro v2.0 - 新功能实施计划

## 📋 文档说明

本文档为 Image Converter Pro 的下一个大版本（v2.0）规划了 8 个核心新功能的详细实施方案。每个功能都包含完整的设计思路、实施步骤和验收标准。

---

## 🎯 功能总览

| 功能 | 优先级 | 工作量 | 技术难度 | 用户价值 |
|------|--------|--------|---------|---------|
| 1. 拖拽排序 | 🔴 高 | 2-3h | ⭐⭐ | ⭐⭐⭐⭐ |
| 2. 失败重试 | 🔴 高 | 2-3h | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| 3. 智能压缩 | 🟡 中 | 4-6h | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 4. 批量优化 | 🔴 高 | 3-5h | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 5. 内存管理 | 🔴 高 | 3-4h | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 6. 水印功能 | 🟡 中 | 5-7h | ⭐⭐⭐ | ⭐⭐⭐ |
| 7. 元数据处理 | 🟢 低 | 3-4h | ⭐⭐⭐ | ⭐⭐⭐ |
| 8. 预设配置 | 🟡 中 | 3-4h | ⭐⭐ | ⭐⭐⭐⭐ |

**总工作量**：25-36 小时  
**推荐开发顺序**：2 → 4 → 5 → 1 → 8 → 3 → 6 → 7

---

## 功能 1: 拖拽排序

### 需求描述

**用户场景**：
```
用户添加了 10 张图片到列表
但希望先转换重要的前 3 张
后面 7 张可以慢慢处理

需求：
- 可以拖动文件项调整顺序
- 只在"待处理"状态下可拖动
- 拖动时有视觉反馈
```

---

### 功能设计

#### UI 设计

**文件列表项增强**：

```
当前设计：
┌────────────────────────────────────┐
│ [图] 文件名.jpg              [删除] │
│     1.2 MB · 待处理                │
└────────────────────────────────────┘

新设计：
┌────────────────────────────────────┐
│ ≡≡ [图] 文件名.jpg           [删除] │
│     1.2 MB · 待处理                │
└────────────────────────────────────┘
  ↑
  拖动手柄（只在待处理状态显示）
```

**拖动状态**：

```
正常状态：
- 白色背景
- 完整显示

拖动中：
- 半透明（opacity: 0.5）
- 轻微放大（scale: 1.02）
- 阴影加深

拖动目标位置：
- 显示蓝色插入线
- 动画提示可放置
```

---

### 实施步骤

#### 步骤 1.1: 添加拖拽手柄图标

**位置**：`lib/widgets/image_list_item.dart`

**实现思路**：
```dart
在 ListTile 最左侧添加拖动手柄

Widget build(BuildContext context) {
  return ListTile(
    // 左侧添加拖动手柄
    leading: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 拖动手柄（只在待处理时显示）
        if (file.status == 'pending')
          Icon(
            Icons.drag_indicator,
            color: Colors.grey,
            size: 20,
          ),
        // 缩略图
        Image.file(...),
      ],
    ),
    title: Text(file.name),
    ...
  );
}
```

---

#### 步骤 1.2: 实现拖拽功能

**使用组件**：`ReorderableListView`

**修改文件列表结构**：

**当前**：
```dart
ListView.builder(
  itemCount: files.length,
  itemBuilder: (context, index) => ImageListItem(...),
)
```

**改为**：
```dart
ReorderableListView.builder(
  itemCount: files.length,
  onReorder: (oldIndex, newIndex) {
    _handleReorder(oldIndex, newIndex);
  },
  itemBuilder: (context, index) {
    final file = files[index];
    
    // 只有待处理的文件才能拖动
    return ImageListItem(
      key: ValueKey(file.id),  // 必须提供唯一 key
      file: file,
      canDrag: file.status == 'pending',
    );
  },
)
```

---

#### 步骤 1.3: 实现排序逻辑

**位置**：`lib/providers/image_list_provider.dart`

**实现思路**：
```dart
void reorderFiles(int oldIndex, int newIndex) {
  // 调整索引（Flutter ReorderableList 的特性）
  if (newIndex > oldIndex) {
    newIndex -= 1;
  }
  
  // 移动文件
  final file = _files.removeAt(oldIndex);
  _files.insert(newIndex, file);
  
  // 通知更新
  notifyListeners();
  
  // 保存排序（可选）
  _saveOrder();
}
```

---

#### 步骤 1.4: 添加拖动视觉反馈

**实现思路**：

**方案 A：自定义拖动代理（推荐）**
```dart
ReorderableListView.builder(
  proxyDecorator: (child, index, animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double scale = lerpDouble(1, 1.02, animation.value)!;
        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: 6,  // 增加阴影
            child: Opacity(
              opacity: 0.8,  // 半透明
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  },
  ...
)
```

---

#### 步骤 1.5: 限制拖动条件

**实现思路**：

**方案 A：禁用非待处理项的拖动**
```dart
Widget buildListItem(FileModel file) {
  if (file.status != 'pending') {
    // 非待处理状态：不可拖动
    return ListTile(...);
  } else {
    // 待处理状态：可拖动
    return ReorderableDragStartListener(
      index: index,
      child: ListTile(...),
    );
  }
}
```

**方案 B：隐藏拖动手柄**
```dart
leading: Row(
  children: [
    // 只在待处理时显示拖动手柄
    if (file.status == 'pending')
      Icon(Icons.drag_indicator)
    else
      SizedBox(width: 20),  // 占位，保持对齐
    ...
  ],
)
```

---

### 验收标准

**功能验收**：
- [ ] 待处理的文件可以拖动
- [ ] 处理中/已完成的文件不可拖动
- [ ] 拖动时有明显的视觉反馈
- [ ] 松手后文件顺序正确更新
- [ ] 拖动手柄只在待处理时显示

**视觉验收**：
- [ ] 拖动手柄样式协调
- [ ] 拖动时半透明效果流畅
- [ ] 插入位置指示清晰
- [ ] 与整体设计风格一致

**交互验收**：
- [ ] 拖动响应灵敏
- [ ] 长按即可拖动
- [ ] 滚动列表时拖动正常
- [ ] 触摸屏和鼠标都支持

---

## 功能 2: 失败重试机制

### 需求描述

**用户场景**：
```
用户批量转换 50 张图片
其中 3 张因网络波动失败
第 5 张因文件损坏失败

期望：
- 失败的文件自动跳过，不影响其他
- 全部完成后，可以选择重试失败的文件
- 可以单独重试某个失败的文件
```

---

### 功能设计

#### UI 设计

**失败文件项显示**：

```
┌────────────────────────────────────────┐
│ ❌ [图] IMG_001.HEIC               [×] │
│     1.30 MB · 处理失败                 │
│     处理超时 - 文件可能过大            │
│     [🔄 重试] [ℹ️ 详情]                │
└────────────────────────────────────────┘
```

**批量重试按钮**：

```
顶部批量操作栏（失败文件存在时显示）：

┌────────────────────────────────────────┐
│ 批量操作  [🔄 重试失败项] [🗑️ 清除失败项] [🔄 清空全部] │
└────────────────────────────────────────┘
  ↑
  检测到 3 个失败文件时自动显示
```

**转换完成提示**：

```
全部转换完成时弹出摘要：

┌────────────────────────────┐
│ ✅ 转换完成                 │
│                            │
│ 总计：50 张                │
│ 成功：47 张                │
│ 失败：3 张                 │
│                            │
│ [查看失败项] [重试失败项]   │
│ [打开输出文件夹] [关闭]     │
└────────────────────────────┘
```

---

### 实施步骤

#### 步骤 2.1: 修改转换逻辑为跳过模式

**位置**：`lib/providers/image_list_provider.dart`

**当前逻辑**（可能）：
```dart
// 错误：一个失败就停止
for (var file in files) {
  await convertFile(file);  // 失败会抛出异常
}
```

**改为跳过模式**：
```dart
Future<void> startConversion() async {
  int successCount = 0;
  int failCount = 0;
  
  for (var file in files) {
    if (file.status != 'pending') continue;
    
    try {
      // 更新状态：处理中
      file.status = 'processing';
      notifyListeners();
      
      // 调用 API 转换
      final result = await apiService.convertImage(file);
      
      // 成功
      file.status = 'completed';
      file.outputPath = result.outputPath;
      successCount++;
      
    } catch (error) {
      // 失败：标记但不停止
      file.status = 'failed';
      file.errorMessage = _getFriendlyErrorMessage(error);
      file.originalError = error.toString();  // 保存原始错误
      failCount++;
      
      // 记录日志
      print('[转换失败] ${file.name}: $error');
    }
    
    notifyListeners();
  }
  
  // 全部处理完成，显示摘要
  _showCompletionSummary(successCount, failCount);
}
```

---

#### 步骤 2.2: 添加单个文件重试功能

**位置**：`lib/widgets/image_list_item.dart`

**为失败项添加重试按钮**：
```dart
if (file.status == 'failed') {
  Row(
    children: [
      // 重试按钮
      TextButton.icon(
        icon: Icon(Icons.refresh, size: 16),
        label: Text('重试'),
        onPressed: () => _retryFile(file),
      ),
      SizedBox(width: 8),
      // 详情按钮
      TextButton.icon(
        icon: Icon(Icons.info_outline, size: 16),
        label: Text('详情'),
        onPressed: () => _showErrorDetail(file),
      ),
    ],
  )
}
```

**重试逻辑**：
```dart
Future<void> _retryFile(FileModel file) async {
  try {
    // 重置状态
    file.status = 'processing';
    file.errorMessage = null;
    notifyListeners();
    
    // 重新转换
    final result = await apiService.convertImage(file);
    
    // 成功
    file.status = 'completed';
    file.outputPath = result.outputPath;
    
    // 提示
    showSnackBar('重试成功');
    
  } catch (error) {
    // 再次失败
    file.status = 'failed';
    file.errorMessage = _getFriendlyErrorMessage(error);
    
    showSnackBar('重试失败: ${file.errorMessage}');
  }
  
  notifyListeners();
}
```

---

#### 步骤 2.3: 批量重试失败文件

**位置**：`lib/screens/home_screen.dart`

**添加批量重试按钮**：
```dart
// 在顶部批量操作栏
AppBar(
  actions: [
    // 只在有失败文件时显示
    if (provider.hasFailedFiles)
      TextButton.icon(
        icon: Icon(Icons.refresh),
        label: Text('重试失败项 (${provider.failedCount})'),
        onPressed: () => _retryAllFailed(),
      ),
  ],
)
```

**批量重试逻辑**：
```dart
Future<void> _retryAllFailed() async {
  final failedFiles = files.where((f) => f.status == 'failed').toList();
  
  if (failedFiles.isEmpty) return;
  
  // 确认对话框
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('重试失败项'),
      content: Text('确定要重试 ${failedFiles.length} 个失败的文件吗？'),
      actions: [
        TextButton(
          child: Text('取消'),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          child: Text('重试'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  // 逐个重试
  int successCount = 0;
  int stillFailedCount = 0;
  
  for (var file in failedFiles) {
    try {
      file.status = 'processing';
      notifyListeners();
      
      final result = await apiService.convertImage(file);
      
      file.status = 'completed';
      file.outputPath = result.outputPath;
      successCount++;
      
    } catch (error) {
      file.status = 'failed';
      file.errorMessage = _getFriendlyErrorMessage(error);
      stillFailedCount++;
    }
    
    notifyListeners();
  }
  
  // 显示结果
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('重试完成'),
      content: Text(
        '成功：$successCount\n'
        '仍失败：$stillFailedCount'
      ),
      actions: [
        TextButton(
          child: Text('确定'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

---

#### 步骤 2.4: 显示错误详情

**创建错误详情对话框**：

**位置**：`lib/widgets/error_detail_dialog.dart`

```dart
class ErrorDetailDialog extends StatelessWidget {
  final FileModel file;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('错误详情'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文件信息
            _buildInfoRow('文件名', file.name),
            _buildInfoRow('文件大小', formatFileSize(file.size)),
            _buildInfoRow('目标格式', file.targetFormat),
            
            Divider(),
            
            // 错误信息
            Text(
              '错误信息',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                file.errorMessage ?? '未知错误',
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 解决建议
            Text(
              '解决建议',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            ..._getSuggestions(file.errorMessage).map(
              (suggestion) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(suggestion)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 原始错误（可展开）
            ExpansionTile(
              title: Text('技术详情'),
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    file.originalError ?? '无详细信息',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('关闭'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.refresh),
          label: Text('重试'),
          onPressed: () {
            Navigator.pop(context);
            _retryFile(file);
          },
        ),
      ],
    );
  }
  
  List<String> _getSuggestions(String? errorMessage) {
    if (errorMessage == null) return ['请重试'];
    
    if (errorMessage.contains('超时')) {
      return [
        '尝试降低输出质量',
        '如果文件很大，考虑改用 JPG 格式',
        '检查后端服务是否正常运行',
      ];
    }
    
    if (errorMessage.contains('损坏')) {
      return [
        '使用其他工具重新导出该图片',
        '检查原文件是否完整',
      ];
    }
    
    if (errorMessage.contains('服务')) {
      return [
        '检查后端服务是否启动',
        '查看后端日志获取更多信息',
        '重启应用试试',
      ];
    }
    
    return ['请重试，或联系支持'];
  }
}
```

---

#### 步骤 2.5: 添加转换完成摘要

**位置**：`lib/widgets/conversion_summary_dialog.dart`

```dart
void _showCompletionSummary(int successCount, int failCount) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            failCount == 0 ? Icons.check_circle : Icons.warning,
            color: failCount == 0 ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 8),
          Text('转换完成'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 统计信息
          _buildStatRow('总计', '${successCount + failCount} 张'),
          _buildStatRow('成功', '$successCount 张', Colors.green),
          if (failCount > 0)
            _buildStatRow('失败', '$failCount 张', Colors.red),
          
          if (failCount > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '部分文件转换失败，你可以查看失败项并重试',
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (failCount > 0)
          TextButton(
            child: Text('查看失败项'),
            onPressed: () {
              Navigator.pop(context);
              _scrollToFirstFailed();
            },
          ),
        if (failCount > 0)
          TextButton(
            child: Text('重试失败项'),
            onPressed: () {
              Navigator.pop(context);
              _retryAllFailed();
            },
          ),
        TextButton(
          child: Text('打开输出文件夹'),
          onPressed: () {
            Navigator.pop(context);
            _openOutputFolder();
          },
        ),
        ElevatedButton(
          child: Text('完成'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

---

### 验收标准

**功能验收**：
- [ ] 单个文件失败不影响其他文件
- [ ] 失败文件显示友好的错误信息
- [ ] 可以单独重试失败的文件
- [ ] 可以批量重试所有失败文件
- [ ] 转换完成后显示摘要

**错误处理验收**：
- [ ] 网络超时 - 正确捕获并提示
- [ ] 文件损坏 - 正确捕获并提示
- [ ] 服务未启动 - 正确捕获并提示
- [ ] 未知错误 - 有通用提示

**UI 验收**：
- [ ] 失败项有明显的视觉标识
- [ ] 重试按钮易于发现
- [ ] 错误详情对话框信息完整
- [ ] 转换摘要清晰易懂

---

## 功能 3: 智能压缩

### 需求描述

**用户场景**：
```
用户不知道应该选择什么质量参数
希望应用能根据图片内容自动推荐

场景 1：照片（风景、人物）
→ 推荐 JPG 质量 85-90

场景 2：截图、文字图
→ 推荐 PNG 无损

场景 3：简单图形
→ 推荐 PNG 或 WebP 高质量
```

---

### 功能设计

#### UI 设计

**智能分析按钮**：

```
底部控制栏新增：

┌─────────────────────────────────────────┐
│ [输出格式: JPG ▼] [质量: 90 ━━●━]       │
│                                          │
│ [🧠 智能分析]  ← 新增按钮                 │
│ 根据图片内容推荐最佳质量                  │
└─────────────────────────────────────────┘
```

**分析结果显示**：

```
点击智能分析后弹出：

┌────────────────────────────────────────┐
│ 🧠 智能分析结果                         │
│                                        │
│ 图片类型：摄影照片（风景）              │
│ 主要内容：自然景观、细节丰富            │
│ 当前大小：总计 45.2 MB                 │
│                                        │
│ 💡 推荐配置                            │
│ ┌──────────────────────────┐          │
│ │ 格式：JPG                 │          │
│ │ 质量：85                  │          │
│ │ 预估：约 15 MB (-67%)     │          │
│ │                          │          │
│ │ 理由：                    │          │
│ │ • 照片压缩 JPG 最优       │          │
│ │ • 质量 85 肉眼无差别      │          │
│ │ • 文件大小明显减少        │          │
│ └──────────────────────────┘          │
│                                        │
│ 其他选项：                              │
│ ○ JPG 质量 90 (约 18 MB, -60%)        │
│ ○ WebP 质量 85 (约 12 MB, -73%)       │
│                                        │
│ [应用推荐] [自定义] [取消]              │
└────────────────────────────────────────┘
```

---

### 实施步骤

#### 步骤 3.1: 图片内容分析（后端）

**位置**：`backend/services/image_analyzer.py`

**创建分析服务**：

```python
from PIL import Image
import numpy as np
from typing import Dict, Tuple

class ImageAnalyzer:
    """图片智能分析器"""
    
    def analyze_image(self, image_path: str) -> Dict:
        """分析图片并返回推荐配置"""
        img = Image.open(image_path)
        
        # 1. 基础信息
        width, height = img.size
        format_name = img.format
        file_size = os.path.getsize(image_path)
        
        # 2. 内容分析
        image_type = self._detect_image_type(img)
        complexity = self._calculate_complexity(img)
        has_transparency = self._check_transparency(img)
        
        # 3. 生成推荐
        recommendation = self._generate_recommendation(
            image_type=image_type,
            complexity=complexity,
            has_transparency=has_transparency,
            current_format=format_name,
            file_size=file_size
        )
        
        return {
            'image_type': image_type,
            'complexity': complexity,
            'has_transparency': has_transparency,
            'recommendation': recommendation,
            'alternative_options': self._get_alternatives(recommendation)
        }
    
    def _detect_image_type(self, img: Image) -> str:
        """检测图片类型"""
        # 转换为 RGB 分析
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # 转为 numpy 数组
        img_array = np.array(img)
        
        # 计算颜色分布
        unique_colors = len(np.unique(img_array.reshape(-1, 3), axis=0))
        total_pixels = img.width * img.height
        color_ratio = unique_colors / total_pixels
        
        # 计算边缘密度
        edges = self._detect_edges(img_array)
        edge_density = np.sum(edges) / total_pixels
        
        # 判断类型
        if color_ratio > 0.1 and edge_density < 0.05:
            return 'photo'  # 摄影照片
        elif edge_density > 0.15:
            return 'screenshot'  # 截图/文字图
        elif color_ratio < 0.01:
            return 'graphic'  # 简单图形/logo
        else:
            return 'mixed'  # 混合类型
    
    def _calculate_complexity(self, img: Image) -> float:
        """计算图片复杂度 (0-1)"""
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        img_array = np.array(img)
        
        # 计算标准差（代表细节丰富程度）
        std_dev = np.std(img_array)
        
        # 归一化到 0-1
        complexity = min(std_dev / 50, 1.0)
        
        return complexity
    
    def _check_transparency(self, img: Image) -> bool:
        """检查是否有透明通道"""
        return img.mode in ('RGBA', 'LA') or 'transparency' in img.info
    
    def _detect_edges(self, img_array: np.ndarray) -> np.ndarray:
        """简单的边缘检测"""
        from scipy import ndimage
        
        # 转灰度
        gray = np.mean(img_array, axis=2)
        
        # Sobel 边缘检测
        sx = ndimage.sobel(gray, axis=0)
        sy = ndimage.sobel(gray, axis=1)
        edges = np.hypot(sx, sy)
        
        # 二值化
        threshold = np.mean(edges) * 2
        edges = edges > threshold
        
        return edges
    
    def _generate_recommendation(
        self,
        image_type: str,
        complexity: float,
        has_transparency: bool,
        current_format: str,
        file_size: int
    ) -> Dict:
        """生成推荐配置"""
        
        # 如果有透明通道，必须 PNG 或 WebP
        if has_transparency:
            return {
                'format': 'PNG',
                'quality': 100,
                'reason': [
                    '图片包含透明通道',
                    'PNG 是唯一广泛支持的无损透明格式'
                ]
            }
        
        # 根据类型推荐
        if image_type == 'photo':
            # 照片：JPG 最优
            if complexity > 0.5:
                # 复杂照片：质量 85-90
                quality = 90 if file_size > 5 * 1024 * 1024 else 85
            else:
                # 简单照片：质量 80
                quality = 80
            
            return {
                'format': 'JPG',
                'quality': quality,
                'reason': [
                    '摄影照片使用 JPG 最优',
                    f'质量 {quality} 肉眼无差别',
                    '文件大小明显减少'
                ]
            }
        
        elif image_type == 'screenshot':
            # 截图/文字图：PNG 或高质量 WebP
            return {
                'format': 'PNG',
                'quality': 100,
                'reason': [
                    '截图和文字图使用 PNG 保持清晰',
                    '无损压缩保留所有细节',
                    '文字边缘不会模糊'
                ]
            }
        
        elif image_type == 'graphic':
            # 简单图形：PNG
            return {
                'format': 'PNG',
                'quality': 100,
                'reason': [
                    '简单图形/Logo 使用 PNG',
                    '色彩数量少，PNG 压缩率高',
                    '边缘锐利清晰'
                ]
            }
        
        else:
            # 混合类型：JPG 85
            return {
                'format': 'JPG',
                'quality': 85,
                'reason': [
                    '混合内容使用 JPG 平衡质量和大小',
                    '质量 85 是常用推荐值'
                ]
            }
    
    def _get_alternatives(self, recommendation: Dict) -> List[Dict]:
        """获取替代选项"""
        alternatives = []
        
        base_format = recommendation['format']
        base_quality = recommendation['quality']
        
        # 选项 1：更高质量
        if base_format == 'JPG' and base_quality < 95:
            alternatives.append({
                'format': 'JPG',
                'quality': min(base_quality + 10, 95),
                'description': '更高质量（文件稍大）'
            })
        
        # 选项 2：WebP
        if base_format == 'JPG':
            alternatives.append({
                'format': 'WebP',
                'quality': base_quality,
                'description': '现代格式（文件更小）'
            })
        
        # 选项 3：更低质量（更小文件）
        if base_format == 'JPG' and base_quality > 75:
            alternatives.append({
                'format': 'JPG',
                'quality': max(base_quality - 10, 75),
                'description': '更小文件（质量略降）'
            })
        
        return alternatives
```

---

#### 步骤 3.2: 添加分析 API 端点

**位置**：`backend/api/analyze.py`

```python
from fastapi import APIRouter, UploadFile, File
from services.image_analyzer import ImageAnalyzer

router = APIRouter()
analyzer = ImageAnalyzer()

@router.post("/api/analyze")
async def analyze_images(files: List[UploadFile] = File(...)):
    """分析图片并返回推荐配置"""
    
    results = []
    
    for file in files:
        # 保存临时文件
        temp_path = f"/tmp/{file.filename}"
        with open(temp_path, "wb") as f:
            f.write(await file.read())
        
        try:
            # 分析
            analysis = analyzer.analyze_image(temp_path)
            
            results.append({
                'filename': file.filename,
                'success': True,
                'analysis': analysis
            })
        
        except Exception as e:
            results.append({
                'filename': file.filename,
                'success': False,
                'error': str(e)
            })
        
        finally:
            # 清理临时文件
            if os.path.exists(temp_path):
                os.remove(temp_path)
    
    # 生成综合推荐
    overall_recommendation = _generate_overall_recommendation(results)
    
    return {
        'individual_results': results,
        'overall_recommendation': overall_recommendation
    }

def _generate_overall_recommendation(results: List[Dict]) -> Dict:
    """基于所有图片生成综合推荐"""
    
    # 统计类型
    types = [r['analysis']['image_type'] for r in results if r['success']]
    type_counts = {}
    for t in types:
        type_counts[t] = type_counts.get(t, 0) + 1
    
    # 最常见的类型
    most_common_type = max(type_counts, key=type_counts.get)
    
    # 基于最常见类型生成推荐
    if most_common_type == 'photo':
        return {
            'format': 'JPG',
            'quality': 85,
            'reason': f'{type_counts["photo"]} 张照片，推荐 JPG 格式'
        }
    elif most_common_type == 'screenshot':
        return {
            'format': 'PNG',
            'quality': 100,
            'reason': f'{type_counts["screenshot"]} 张截图，推荐 PNG 格式'
        }
    else:
        return {
            'format': 'JPG',
            'quality': 85,
            'reason': '混合内容，推荐通用配置'
        }
```

---

#### 步骤 3.3: 前端智能分析按钮

**位置**：`lib/screens/home_screen.dart`

**添加智能分析按钮**：

```dart
// 在底部控制栏添加
Row(
  children: [
    // 现有控件...
    
    SizedBox(width: 16),
    
    // 智能分析按钮
    OutlinedButton.icon(
      icon: Icon(Icons.psychology),  // 大脑图标
      label: Text('智能分析'),
      onPressed: _files.isEmpty ? null : _analyzeImages,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
      ),
    ),
  ],
)
```

---

#### 步骤 3.4: 调用分析 API

**位置**：`lib/services/api_service.dart`

```dart
Future<AnalysisResult> analyzeImages(List<File> files) async {
  final formData = FormData();
  
  // 添加文件
  for (var file in files) {
    formData.files.add(
      MapEntry(
        'files',
        await MultipartFile.fromFile(file.path),
      ),
    );
  }
  
  try {
    final response = await dio.post(
      '/api/analyze',
      data: formData,
    );
    
    return AnalysisResult.fromJson(response.data);
    
  } catch (e) {
    throw Exception('分析失败: $e');
  }
}
```

---

#### 步骤 3.5: 显示分析结果对话框

**位置**：`lib/widgets/analysis_result_dialog.dart`

```dart
class AnalysisResultDialog extends StatelessWidget {
  final AnalysisResult result;
  
  @override
  Widget build(BuildContext context) {
    final recommendation = result.overallRecommendation;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.psychology, color: Colors.blue),
          SizedBox(width: 8),
          Text('智能分析结果'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片类型统计
            _buildSection(
              '图片类型',
              _buildTypeStatistics(result.individualResults),
            ),
            
            Divider(),
            
            // 推荐配置
            _buildSection(
              '💡 推荐配置',
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '格式：',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          recommendation.format,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          '质量：',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${recommendation.quality}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '预估大小：约 ${_estimateSize()} (减少 ${_estimateReduction()}%)',
                      style: TextStyle(color: Colors.green),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '理由：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...recommendation.reasons.map(
                      (reason) => Padding(
                        padding: EdgeInsets.only(left: 8, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• '),
                            Expanded(child: Text(reason)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 其他选项
            if (recommendation.alternatives.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildSection(
                '其他选项',
                Column(
                  children: recommendation.alternatives.map((alt) {
                    return RadioListTile<String>(
                      title: Text(
                        '${alt.format} 质量 ${alt.quality}',
                      ),
                      subtitle: Text(alt.description),
                      value: alt.id,
                      groupValue: _selectedAlternative,
                      onChanged: (value) {
                        setState(() => _selectedAlternative = value);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text('自定义'),
          onPressed: () {
            Navigator.pop(context);
            // 打开高级设置
          },
        ),
        ElevatedButton(
          child: Text('应用推荐'),
          onPressed: () {
            // 应用推荐的配置
            _applyRecommendation(recommendation);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
```

---

### 验收标准

**分析准确性**：
- [ ] 照片类型识别准确率 > 85%
- [ ] 截图类型识别准确率 > 90%
- [ ] 图形类型识别准确率 > 80%
- [ ] 推荐配置合理

**功能验收**：
- [ ] 智能分析按钮可用
- [ ] 分析结果显示完整
- [ ] 推荐理由清晰
- [ ] 可以应用推荐配置
- [ ] 可以选择替代方案

**性能验收**：
- [ ] 单张图片分析 < 2 秒
- [ ] 批量分析（10 张）< 10 秒
- [ ] 大图片（> 10MB）分析不卡顿

---



