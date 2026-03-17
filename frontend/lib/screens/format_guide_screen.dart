import 'package:flutter/material.dart';

class FormatGuideScreen extends StatelessWidget {
  const FormatGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('格式选择指南'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            dividerColor: Colors.transparent,
            indicatorWeight: 3,
            tabs: [
              const Tab(text: '概述'),
              const Tab(text: '格式对比'),
              const Tab(text: '场景推荐'),
              const Tab(text: '常见问题'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_OverviewTab(), _CompareTab(), _SceneTab(), _FaqTab()],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return const _Content(
      children: [
        _Title('图片格式简述'),
        _Paragraph('JPG：分享照片首选，体积和质量平衡好。'),
        _Paragraph('PNG：无损和透明支持，适合图形/设计素材。'),
        _Paragraph('WebP：现代高压缩格式，常用于网页。'),
        _Paragraph('HEIC：苹果高效存储格式，跨平台兼容性一般。'),
      ],
    );
  }
}

class _CompareTab extends StatelessWidget {
  const _CompareTab();

  @override
  Widget build(BuildContext context) {
    return const _Content(
      children: [
        _Title('格式对比'),
        _Paragraph('JPG：有损压缩，体积小，兼容性优秀。'),
        _Paragraph('PNG：无损压缩，体积大，透明支持优秀。'),
        _Paragraph('WebP：有损/无损均支持，体积更小，兼容性中上。'),
        _Paragraph('HEIC：压缩率高，主要在苹果生态常见。'),
      ],
    );
  }
}

class _SceneTab extends StatelessWidget {
  const _SceneTab();

  @override
  Widget build(BuildContext context) {
    return const _Content(
      children: [
        _Title('场景推荐'),
        _Paragraph('分享照片：JPG（质量 85-90）'),
        _Paragraph('网页优化：WebP（质量 80-85）'),
        _Paragraph('设计素材/透明背景：PNG（质量 100）'),
        _Paragraph('HEIC 转换：优先考虑 JPG 以控制体积'),
      ],
    );
  }
}

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  @override
  Widget build(BuildContext context) {
    return const _Content(
      children: [
        _Title('常见问题'),
        _Paragraph('Q: 为什么 HEIC 转 PNG 变大？'),
        _Paragraph('A: HEIC 高压缩，PNG 无损，解压后体积通常显著上升。'),
        _Paragraph('Q: JPG 质量建议？'),
        _Paragraph('A: 一般 85-90 已能兼顾清晰度和体积。'),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(18), children: children);
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(height: 1.5)),
    );
  }
}
