import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/image_file_model.dart';

class ImageListItem extends StatefulWidget {
  const ImageListItem({
    super.key,
    required this.imageFile,
    required this.onDelete,
  });

  final ImageFileModel imageFile;
  final VoidCallback onDelete;

  @override
  State<ImageListItem> createState() => _ImageListItemState();
}

class _ImageListItemState extends State<ImageListItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.imageFile.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovering ? -1 : 0, 0),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: _hovering ? 4 : 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: _buildThumbnail(),
            title: Text(
              widget.imageFile.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: _buildSubtitle(statusColor),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIndicator(),
                IconButton(
                  tooltip: '删除',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.file(
          File(widget.imageFile.filePath),
          fit: BoxFit.cover,
          cacheWidth: 96,
          cacheHeight: 96,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF0F3F8),
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    switch (widget.imageFile.status) {
      case 'processing':
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        );
      case 'completed':
        return const Icon(Icons.check_circle, color: Color(0xFF2E7D32));
      case 'failed':
        return const FaIcon(
          FontAwesomeIcons.circleXmark,
          color: Color(0xFFC62828),
        );
      default:
        return const Icon(Icons.circle, size: 12, color: Color(0xFF8E9AAC));
    }
  }

  Widget _buildSubtitle(Color statusColor) {
    final imageFile = widget.imageFile;
    final sizeText = _formatBytes(imageFile.fileSize);

    switch (imageFile.status) {
      case 'processing':
        final progress = (imageFile.progress ?? 0.0).clamp(0.0, 0.95);
        final progressText = (progress * 100).toStringAsFixed(0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$sizeText · 处理中 $progressText%',
              style: TextStyle(color: statusColor),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: progress.toDouble(),
                color: const Color(0xFF1565C0),
                backgroundColor: const Color(0xFFD9E1EE),
              ),
            ),
          ],
        );
      case 'completed':
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _buildCompletedSizeText(imageFile),
              style: TextStyle(color: statusColor),
            ),
            if (_buildChangeBadge(imageFile) case final badge?)
              _changeBadge(badge.$1, badge.$2),
          ],
        );
      case 'failed':
        return Text(
          '$sizeText · 处理失败: ${imageFile.errorMessage ?? '请重试'}',
          style: TextStyle(color: statusColor),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      default:
        final estimatedSize = imageFile.estimatedOutputSize;
        final ratio = imageFile.estimatedChangeRatio;
        if (estimatedSize == null || ratio == null) {
          return Text('$sizeText · 待处理', style: TextStyle(color: statusColor));
        }
        final isGrowing = ratio > 1.0;
        final ratioText = ratio.toStringAsFixed(ratio >= 10 ? 0 : 1);
        final warnColor = ratio >= 5
            ? const Color(0xFFC62828)
            : const Color(0xFFEF6C00);
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('$sizeText · 待处理', style: TextStyle(color: statusColor)),
            Text(
              '预估 ${_formatBytes(estimatedSize)}',
              style: const TextStyle(color: Color(0xFF3F4E63)),
            ),
            Text(
              isGrowing
                  ? '约 $ratioText 倍'
                  : '约 ${(1 / ratio).toStringAsFixed(1)} 倍压缩',
              style: TextStyle(
                color: isGrowing ? warnColor : const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (ratio >= 3)
              Icon(Icons.warning_amber_rounded, size: 16, color: warnColor),
          ],
        );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  String _buildCompletedSizeText(ImageFileModel imageFile) {
    if (imageFile.outputFileSize == null || imageFile.outputFileSize! <= 0) {
      return '${_formatBytes(imageFile.fileSize)} · 已完成';
    }
    return '${_formatBytes(imageFile.fileSize)} → ${_formatBytes(imageFile.outputFileSize!)}';
  }

  (String, bool)? _buildChangeBadge(ImageFileModel imageFile) {
    if (imageFile.outputFileSize == null || imageFile.outputFileSize! <= 0) {
      if (imageFile.compressionRatio == null ||
          imageFile.compressionRatio!.isEmpty) {
        return null;
      }
      return ('压缩 ${imageFile.compressionRatio}', true);
    }
    final original = imageFile.fileSize;
    final output = imageFile.outputFileSize!;
    if (original <= 0 || output <= 0) {
      return null;
    }

    final delta = output - original;
    if (delta == 0) {
      return ('无变化', true);
    }
    final ratio = (delta.abs() / math.max(1, original) * 100).toStringAsFixed(
      0,
    );
    if (delta < 0) {
      return ('压缩 $ratio%', true);
    }
    return ('增大 $ratio%', false);
  }

  Widget _changeBadge(String text, bool isCompressed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isCompressed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isCompressed
              ? const Color(0xFF2E7D32)
              : const Color(0xFFEF6C00),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'completed' => const Color(0xFF2E7D32),
      'failed' => const Color(0xFFC62828),
      'processing' => const Color(0xFF1565C0),
      _ => const Color(0xFF607089),
    };
  }
}
