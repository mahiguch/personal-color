import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// デバッグ用のカメラ権限チェックウィジェット
class DebugCameraPermission extends StatefulWidget {
  const DebugCameraPermission({super.key});

  @override
  State<DebugCameraPermission> createState() => _DebugCameraPermissionState();
}

class _DebugCameraPermissionState extends State<DebugCameraPermission> {
  PermissionStatus? _permissionStatus;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _permissionStatus = status;
      _log += 'Current permission status: $status\n';
    });
  }

  Future<void> _requestPermission() async {
    setState(() {
      _log += 'Requesting camera permission...\n';
    });
    
    final status = await Permission.camera.request();
    
    setState(() {
      _permissionStatus = status;
      _log += 'Permission request result: $status\n';
    });

    if (status.isPermanentlyDenied) {
      setState(() {
        _log += 'Opening app settings...\n';
      });
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カメラ権限デバッグ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '現在の権限状態',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _permissionStatus?.toString() ?? '未確認',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermission,
              child: const Text('権限状態を確認'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _requestPermission,
              child: const Text('カメラ権限を要求'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: const Text('設定画面を開く'),
            ),
            const SizedBox(height: 16),
            const Text(
              'ログ:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty ? 'ログなし' : _log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_permissionStatus) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.red;
      case PermissionStatus.limited:
        return Colors.blue;
      case PermissionStatus.provisional:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}