import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class DropZoneWidget extends StatefulWidget {
  const DropZoneWidget({
    super.key,
    required this.onEntriesDropped,
    this.child,
    this.showHint = true,
    this.minHeight = 240,
    this.title = '拖拽图片或文件到这里开始转换',
    this.subtitle = '支持 JPG、PNG、WebP、HEIC',
    this.description = '支持批量处理整个文件夹（不含子文件夹）',
  });

  final Future<void> Function(List<String> paths) onEntriesDropped;
  final Widget? child;
  final bool showHint;
  final double minHeight;
  final String title;
  final String subtitle;
  final String? description;

  @override
  State<DropZoneWidget> createState() => _DropZoneWidgetState();
}

class _DropZoneWidgetState extends State<DropZoneWidget> {
  bool _dragging = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isHintMode = widget.child == null || widget.showHint;
    final isActive = _dragging || _hovering;
    final borderColor = _dragging
        ? const Color(0xFF1976D2)
        : (isActive ? const Color(0xFF2196F3) : const Color(0xFF9AAAC1));
    final backgroundColor = _dragging
        ? const Color(0xFFE3F2FD)
        : (isActive ? const Color(0xFFF5F9FF) : const Color(0xFFF8F9FA));
    final scale = _dragging ? 1.02 : (isActive ? 1.005 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (details) async {
          setState(() => _dragging = false);
          final paths = details.files
              .map((xFile) => xFile.path)
              .where((path) => path.isNotEmpty)
              .where(
                (path) =>
                    File(path).existsSync() || Directory(path).existsSync(),
              )
              .toList();
          if (paths.isNotEmpty) {
            await widget.onEntriesDropped(paths);
          }
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: widget.minHeight),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DottedBorder(
              color: borderColor,
              strokeWidth: _dragging ? 3 : 2.4,
              dashPattern: const [8, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: isHintMode
                      ? _buildHint(context)
                      : widget.child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHint(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 80,
            color: _dragging
                ? const Color(0xFF1976D2)
                : const Color(0xFF607D8B),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF666666),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (widget.description != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.description!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF999999),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
