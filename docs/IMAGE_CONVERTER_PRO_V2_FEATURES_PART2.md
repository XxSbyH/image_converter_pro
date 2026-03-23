# Image Converter Pro v2.0 - 新功能实施计划（续）

## 功能 4: 批量处理优化（多线程/异步）

### 需求描述

**当前问题**：
```
场景：用户批量转换 100 张图片
当前：逐个处理，总耗时 10 分钟

问题：
- 处理速度慢
- CPU 利用率低（只用单核）
- 用户等待时间长
```

**优化目标**：
```
改为：并发处理 3-5 张
预期：总耗时 3-4 分钟
提升：50-60% 性能提升
```

---

### 功能设计

#### 架构设计

**当前架构**（串行）：
```
Frontend → Backend → 处理图片 1 → 返回
        → Backend → 处理图片 2 → 返回
        → Backend → 处理图片 3 → 返回
        ...
```

**优化后架构**（并发）：
```
Frontend → Backend → ┌─ 处理图片 1 → 返回
                     ├─ 处理图片 2 → 返回
                     ├─ 处理图片 3 → 返回
                     └─ 处理图片 4 → 返回
         → Backend → ┌─ 处理图片 5 → 返回
                     ├─ 处理图片 6 → 返回
                     ...
```

---

### 实施步骤

#### 步骤 4.1: 后端添加异步处理

**位置**：`backend/services/image_processor.py`

**改造为异步**：

```python
import asyncio
from concurrent.futures import ProcessPoolExecutor
from typing import List, Dict

class ImageProcessor:
    def __init__(self, max_workers: int = 3):
        """
        max_workers: 最大并发数（建议 3-5）
        """
        self.max_workers = max_workers
        self.executor = ProcessPoolExecutor(max_workers=max_workers)
    
    async def process_batch(
        self,
        files: List[Dict],
        output_format: str,
        quality: int
    ) -> List[Dict]:
        """批量异步处理图片"""
        
        # 创建任务
        tasks = []
        for file_info in files:
            task = self._process_single_async(
                file_info=file_info,
                output_format=output_format,
                quality=quality
            )
            tasks.append(task)
        
        # 并发执行（限制并发数）
        results = []
        for i in range(0, len(tasks), self.max_workers):
            batch = tasks[i:i + self.max_workers]
            batch_results = await asyncio.gather(*batch, return_exceptions=True)
            results.extend(batch_results)
        
        return results
    
    async def _process_single_async(
        self,
        file_info: Dict,
        output_format: str,
        quality: int
    ) -> Dict:
        """异步处理单个图片"""
        
        loop = asyncio.get_event_loop()
        
        try:
            # 在进程池中执行 CPU 密集型任务
            result = await loop.run_in_executor(
                self.executor,
                self._process_single_sync,
                file_info,
                output_format,
                quality
            )
            
            return {
                'success': True,
                'filename': file_info['filename'],
                'output_path': result['output_path'],
                'output_size': result['output_size']
            }
        
        except Exception as e:
            return {
                'success': False,
                'filename': file_info['filename'],
                'error': str(e)
            }
    
    def _process_single_sync(
        self,
        file_info: Dict,
        output_format: str,
        quality: int
    ) -> Dict:
        """同步处理单个图片（在子进程中执行）"""
        
        from PIL import Image
        import pillow_heif
        
        # 注册 HEIF 支持
        pillow_heif.register_heif_opener()
        
        # 打开图片
        img = Image.open(file_info['input_path'])
        
        # 转换格式
        output_path = self._generate_output_path(
            file_info['filename'],
            output_format
        )
        
        # 保存
        if output_format.upper() == 'JPG':
            img.convert('RGB').save(
                output_path,
                'JPEG',
                quality=quality,
                optimize=True
            )
        elif output_format.upper() == 'PNG':
            img.save(
                output_path,
                'PNG',
                optimize=True
            )
        elif output_format.upper() == 'WEBP':
            img.save(
                output_path,
                'WEBP',
                quality=quality
            )
        
        # 获取输出文件大小
        output_size = os.path.getsize(output_path)
        
        return {
            'output_path': output_path,
            'output_size': output_size
        }
```

---

#### 步骤 4.2: FastAPI 异步端点

**位置**：`backend/api/convert.py`

```python
from fastapi import APIRouter, UploadFile, File, BackgroundTasks
from typing import List
import asyncio

router = APIRouter()
processor = ImageProcessor(max_workers=3)

@router.post("/api/batch-convert")
async def batch_convert(
    files: List[UploadFile] = File(...),
    output_format: str = 'jpg',
    quality: int = 85
):
    """批量转换（异步并发）"""
    
    # 保存上传的文件
    file_infos = []
    for file in files:
        temp_path = f"/tmp/uploads/{file.filename}"
        os.makedirs(os.path.dirname(temp_path), exist_ok=True)
        
        with open(temp_path, "wb") as f:
            f.write(await file.read())
        
        file_infos.append({
            'filename': file.filename,
            'input_path': temp_path
        })
    
    # 异步批量处理
    results = await processor.process_batch(
        files=file_infos,
        output_format=output_format,
        quality=quality
    )
    
    # 清理临时文件
    for file_info in file_infos:
        if os.path.exists(file_info['input_path']):
            os.remove(file_info['input_path'])
    
    return {
        'success': True,
        'results': results
    }
```

---

#### 步骤 4.3: 前端使用批量 API

**位置**：`lib/providers/image_list_provider.dart`

**改用批量 API**：

```dart
Future<void> startConversionOptimized() async {
  final pendingFiles = files.where((f) => f.status == 'pending').toList();
  
  if (pendingFiles.isEmpty) return;
  
  // 分批处理（每批 10 个文件）
  const batchSize = 10;
  
  for (int i = 0; i < pendingFiles.length; i += batchSize) {
    final end = min(i + batchSize, pendingFiles.length);
    final batch = pendingFiles.sublist(i, end);
    
    // 标记为处理中
    for (var file in batch) {
      file.status = 'processing';
    }
    notifyListeners();
    
    try {
      // 调用批量 API
      final results = await apiService.batchConvert(
        files: batch,
        format: selectedFormat,
        quality: quality,
      );
      
      // 更新结果
      for (int j = 0; j < batch.length; j++) {
        final file = batch[j];
        final result = results[j];
        
        if (result.success) {
          file.status = 'completed';
          file.outputPath = result.outputPath;
        } else {
          file.status = 'failed';
          file.errorMessage = result.error;
        }
      }
      
    } catch (error) {
      // 批量失败，标记所有
      for (var file in batch) {
        file.status = 'failed';
        file.errorMessage = '批量处理失败: $error';
      }
    }
    
    notifyListeners();
  }
  
  // 显示完成摘要
  _showCompletionSummary();
}
```

---

#### 步骤 4.4: 添加并发数配置

**位置**：`lib/screens/settings_screen.dart`

**添加性能设置**：

```dart
// 设置页面添加
ListTile(
  title: Text('并发处理数'),
  subtitle: Text('同时处理的图片数量（建议 3-5）'),
  trailing: DropdownButton<int>(
    value: settings.concurrency,
    items: [1, 2, 3, 4, 5].map((value) {
      return DropdownMenuItem(
        value: value,
        child: Text('$value 个'),
      );
    }).toList(),
    onChanged: (value) {
      settings.concurrency = value!;
      settings.save();
    },
  ),
)
```

---

### 验收标准

**性能提升**：
- [ ] 100 张图片处理时间减少 > 40%
- [ ] CPU 利用率提升（多核利用）
- [ ] 不影响其他应用性能

**稳定性**：
- [ ] 大批量处理（200+ 张）不崩溃
- [ ] 内存使用稳定
- [ ] 并发错误正确处理

**用户体验**：
- [ ] UI 不卡顿
- [ ] 进度更新及时
- [ ] 可以配置并发数

---

## 功能 5: 内存管理优化

### 需求描述

**当前问题**：
```
场景：转换单个 50MB 的 HEIC 文件
当前：一次性加载到内存
问题：内存占用可能超过 200MB

场景：批量转换 10 个大文件
问题：可能内存溢出，应用崩溃
```

**优化目标**：
```
实现：分块读取和处理
内存占用：< 100MB（无论文件多大）
支持：任意大小文件
```

---

### 功能设计

#### 策略设计

**分块处理策略**：

```
小文件（< 10MB）：
→ 直接加载全部到内存
→ 处理速度最快

中等文件（10-50MB）：
→ 按需加载，及时释放
→ 平衡速度和内存

大文件（> 50MB）：
→ 分块读取（每块 10MB）
→ 流式处理
→ 内存占用最小
```

---

### 实施步骤

#### 步骤 5.1: 后端分块处理

**位置**：`backend/services/large_file_processor.py`

```python
from PIL import Image
import io
from typing import Generator

class LargeFileProcessor:
    """大文件专用处理器"""
    
    CHUNK_SIZE = 10 * 1024 * 1024  # 10MB
    MEMORY_LIMIT = 100 * 1024 * 1024  # 100MB
    
    def process_large_file(
        self,
        input_path: str,
        output_path: str,
        output_format: str,
        quality: int
    ):
        """处理大文件（分块）"""
        
        # 获取文件大小
        file_size = os.path.getsize(input_path)
        
        if file_size < 10 * 1024 * 1024:
            # 小文件：直接处理
            return self._process_normal(
                input_path, output_path, output_format, quality
            )
        else:
            # 大文件：分块处理
            return self._process_chunked(
                input_path, output_path, output_format, quality
            )
    
    def _process_chunked(
        self,
        input_path: str,
        output_path: str,
        output_format: str,
        quality: int
    ):
        """分块处理大文件"""
        
        # 对于图片，我们不能真正"分块"读取
        # 但可以：
        # 1. 使用低内存模式打开
        # 2. 及时释放中间数据
        # 3. 使用生成器避免一次性加载
        
        # Pillow 的 Image.open 是惰性加载
        img = Image.open(input_path)
        
        # 如果图片过大，先缩小后处理
        max_dimension = 10000  # 最大边长
        if max(img.size) > max_dimension:
            ratio = max_dimension / max(img.size)
            new_size = (
                int(img.width * ratio),
                int(img.height * ratio)
            )
            img = img.resize(new_size, Image.LANCZOS)
        
        # 转换模式（如果需要）
        if output_format.upper() == 'JPG' and img.mode != 'RGB':
            img = img.convert('RGB')
        
        # 保存（使用优化选项减少内存）
        img.save(
            output_path,
            output_format.upper(),
            quality=quality,
            optimize=True,
            progressive=True  # 渐进式保存，减少内存峰值
        )
        
        # 立即关闭释放内存
        img.close()
        
        return {
            'success': True,
            'output_path': output_path
        }
```

---

#### 步骤 5.2: 前端内存监控

**位置**：`lib/utils/memory_monitor.dart`

```dart
class MemoryMonitor {
  /// 检查当前内存使用情况
  static Future<MemoryInfo> getMemoryInfo() async {
    if (Platform.isWindows) {
      // Windows: 使用 tasklist
      final result = await Process.run(
        'tasklist',
        ['/FI', 'PID eq ${pid.toString()}', '/FO', 'CSV', '/NH'],
      );
      
      // 解析内存使用
      final output = result.stdout as String;
      final memory = _parseMemoryFromTasklist(output);
      
      return MemoryInfo(
        usedMemory: memory,
        isWarning: memory > 500 * 1024 * 1024,  // > 500MB 警告
        isCritical: memory > 1000 * 1024 * 1024,  // > 1GB 严重
      );
    }
    
    return MemoryInfo(usedMemory: 0);
  }
  
  /// 触发垃圾回收（Dart）
  static void forceGC() {
    // Dart 没有直接的 GC API
    // 但可以通过清空引用来帮助 GC
    // 主要在代码中及时释放大对象
  }
}

class MemoryInfo {
  final int usedMemory;
  final bool isWarning;
  final bool isCritical;
  
  MemoryInfo({
    required this.usedMemory,
    this.isWarning = false,
    this.isCritical = false,
  });
}
```

---

#### 步骤 5.3: 文件大小限制和警告

**位置**：`lib/providers/image_list_provider.dart`

```dart
Future<void> addFiles(List<File> files) async {
  final List<File> tooLarge = [];
  final List<File> acceptable = [];
  
  for (var file in files) {
    final size = await file.length();
    
    if (size > 100 * 1024 * 1024) {  // > 100MB
      tooLarge.add(file);
    } else {
      acceptable.add(file);
    }
  }
  
  // 添加可接受的文件
  for (var file in acceptable) {
    _files.add(FileModel.fromFile(file));
  }
  
  notifyListeners();
  
  // 警告过大的文件
  if (tooLarge.isNotEmpty) {
    _showLargeFileWarning(tooLarge);
  }
}

void _showLargeFileWarning(List<File> files) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('文件过大警告'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('检测到 ${files.length} 个超大文件（> 100MB）：'),
          SizedBox(height: 8),
          ...files.map((f) => Text(
            '• ${path.basename(f.path)} (${formatFileSize(f.lengthSync())})',
            style: TextStyle(fontSize: 12),
          )),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '超大文件可能导致：\n'
              '• 处理时间很长\n'
              '• 内存占用过高\n'
              '• 应用可能卡顿\n\n'
              '建议：\n'
              '• 先用其他工具压缩\n'
              '• 或分批处理',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('仍要添加'),
          onPressed: () {
            // 强制添加
            for (var file in files) {
              _files.add(FileModel.fromFile(file));
            }
            Navigator.pop(context);
            notifyListeners();
          },
        ),
        ElevatedButton(
          child: Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

---

### 验收标准

**内存控制**：
- [ ] 单个 100MB 文件处理时内存 < 200MB
- [ ] 批量处理时内存稳定
- [ ] 无内存泄漏
- [ ] 处理完成后内存回落

**大文件支持**：
- [ ] 支持 100MB+ 文件
- [ ] 支持 200MB+ 文件（警告但能处理）
- [ ] 超大文件有明确提示

**稳定性**：
- [ ] 长时间运行不崩溃
- [ ] 内存不足时优雅降级
- [ ] 有明确的错误提示

---

## 功能 6-8 概要说明

由于文档已经很长，剩余功能我提供简化版本：

### 功能 6: 水印功能

**核心步骤**：
1. 后端使用 Pillow 的 ImageDraw 添加文字水印
2. 使用 Image.alpha_composite 添加图片水印
3. 前端提供水印配置UI（位置、透明度、文字、图片）
4. 支持批量添加相同水印

**关键代码位置**：
- `backend/services/watermark_service.py`
- `lib/widgets/watermark_config_dialog.dart`
- `lib/models/watermark_config.dart`

---

### 功能 7: 元数据处理

**核心步骤**：
1. 使用 piexif 库读取和修改 EXIF 数据
2. 提供"清除所有元数据"选项（隐私保护）
3. 提供"批量修改"选项（作者、版权等）
4. 前端显示元数据查看器

**关键代码位置**：
- `backend/services/metadata_service.py`
- `lib/widgets/metadata_viewer.dart`
- `lib/widgets/metadata_editor.dart`

---

### 功能 8: 预设配置

**核心步骤**：
1. 定义配置模型（格式、质量、水印等）
2. 使用 shared_preferences 存储预设
3. 提供预设管理界面（添加、编辑、删除）
4. 内置常用预设（社交媒体、网页优化等）

**关键代码位置**：
- `lib/models/conversion_preset.dart`
- `lib/services/preset_service.dart`
- `lib/widgets/preset_selector.dart`
- `lib/screens/preset_manager_screen.dart`

---

## 完整实施计划总结

### 推荐实施顺序

**第 1 阶段**（1-2 周，核心优化）：
1. ✅ 功能 2：失败重试（2-3h）
2. ✅ 功能 4：批量优化（3-5h）
3. ✅ 功能 5：内存管理（3-4h）

**第 2 阶段**（1 周，用户体验）：
4. ✅ 功能 1：拖拽排序（2-3h）
5. ✅ 功能 8：预设配置（3-4h）

**第 3 阶段**（1-2 周，高级功能）：
6. ✅ 功能 3：智能压缩（4-6h）
7. ✅ 功能 6：水印功能（5-7h）
8. ✅ 功能 7：元数据处理（3-4h）

---

### 总工作量估算

- **核心优化**：8-12 小时
- **用户体验**：5-7 小时  
- **高级功能**：12-17 小时
- **总计**：25-36 小时

---

### 版本发布建议

**v2.0-beta1**：功能 1、2、4、5  
**v2.0-beta2**：+ 功能 8  
**v2.0-RC**：+ 功能 3  
**v2.0-final**：+ 功能 6、7

