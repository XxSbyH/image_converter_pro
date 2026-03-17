import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../screens/home_screen.dart';
import '../services/backend_manager.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _statusText = '正在启动服务...';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _errorText = null;
      _statusText = '正在启动服务...';
    });

    final success = await Future.any<bool>([
      BackendManager().startBackend(),
      Future<bool>.delayed(const Duration(seconds: 30), () => false),
    ]);

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() => _statusText = '服务已就绪，正在进入主界面...');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
      return;
    }

    setState(() {
      _errorText = '后端启动失败，请检查后端资源或端口占用后重试。';
      _statusText = '启动失败';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF2FF), Color(0xFFFDFEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpinKitFadingCircle(
                      color: Color(0xFF0D3B66),
                      size: 44,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFC62828)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _bootstrap,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('重试启动'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
