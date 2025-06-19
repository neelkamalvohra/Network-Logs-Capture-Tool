import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../services/packet_capture_service.dart';

class PacketCaptureScreen extends StatefulWidget {
  final String url;
  final String diagnosticLog;

  const PacketCaptureScreen({
    super.key,
    required this.url,
    required this.diagnosticLog,
  });

  @override
  State<PacketCaptureScreen> createState() => _PacketCaptureScreenState();
}

class _PacketCaptureScreenState extends State<PacketCaptureScreen> {
  final PacketCaptureService _captureService = PacketCaptureService();
  bool _isCapturing = false;
  bool _isCompleted = false;
  String _status = 'Preparing capture...';
  String _errorMessage = '';
  String? _resultFilePath;
  int _secondsRemaining = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCapture();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startCapture() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _status = 'Initializing packet capture...';
      _secondsRemaining = 10;
    });

    try {
      // Start countdown timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
            _status = 'Capturing network traffic... ($_secondsRemaining seconds remaining)';
          } else {
            timer.cancel();
          }
        });
      });

      // Start capture process
      final resultPath = await _captureService.startCapture(
        widget.url,
        widget.diagnosticLog,
      );

      setState(() {
        _isCapturing = false;
        _isCompleted = true;
        _resultFilePath = resultPath;
        _status = 'Capture completed successfully!';
      });

      _timer?.cancel();
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _errorMessage = e.toString();
        _status = 'Capture failed';
      });

      _timer?.cancel();
    }
  }

  void _openResultFile() {
    if (_resultFilePath != null) {
      final file = File(_resultFilePath!);
      if (file.existsSync()) {
        // TODO: Implement file opening or sharing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved at: $_resultFilePath')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Packet Capture'),
        centerTitle: true,
      ),
      body: Screenshot(
        controller: _captureService.screenshotController,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.network_check,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_isCapturing) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Capturing packets and screenshots for ${widget.url}...',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait $_secondsRemaining seconds',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              if (_isCompleted && _resultFilePath != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Capture Results Saved',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'File saved at:\n$_resultFilePath',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openResultFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open File Location'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
