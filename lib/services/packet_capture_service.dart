import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';

class PacketCaptureService {
  bool _isCapturing = false;
  final List<File> _screenshots = [];
  File? _pcapFile;
  String? _diagnosticLog;
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // Singleton pattern
  static final PacketCaptureService _instance = PacketCaptureService._internal();
  factory PacketCaptureService() => _instance;
  PacketCaptureService._internal();
  
  // Public getters
  bool get isCapturing => _isCapturing;
  ScreenshotController get screenshotController => _screenshotController;
  
  // Method to start packet capture and browser automation
  Future<void> startCapture(String url, String diagnosticLog) async {
    if (_isCapturing) return;
    
    _isCapturing = true;
    _diagnosticLog = diagnosticLog;
    _screenshots.clear();
    _pcapFile = null;
    
    try {
      // Step 1: Initialize packet capture
      await _initializePacketCapture();
      
      // Step 2: Launch browser with the URL
      await _launchBrowser(url);
      
      // Step 3: Start screenshot capture loop
      await _captureScreenshots(10); // 10 seconds
      
      // Step 4: Stop packet capture
      await _stopPacketCapture();
      
      // Step 5: Package results
      final zipFile = await _packageResults();
      
      _isCapturing = false;
      
      // Return the path to the ZIP file
      return zipFile;
    } catch (e) {
      _isCapturing = false;
      rethrow;
    }
  }
  
  // Initialize packet capture
  Future<void> _initializePacketCapture() async {
    // TODO: Implement packet capture mechanism
    // For v1.1, we'll need to choose between:
    // 1. VPN-based packet capture
    // 2. External tool integration
    // 3. Native code integration
    
    // Placeholder for now - we'll implement the actual packet capture later
    print('Packet capture initialized');
  }
  
  // Launch browser with the URL
  Future<void> _launchBrowser(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      throw 'Failed to open browser: $e';
    }
  }
  
  // Capture screenshots at 1-second intervals
  Future<void> _captureScreenshots(int seconds) async {
    final directory = await getTemporaryDirectory();
    final screenshotDir = Directory('${directory.path}/screenshots');
    
    if (!await screenshotDir.exists()) {
      await screenshotDir.create(recursive: true);
    }
    
    // Take screenshots every second
    for (int i = 0; i < seconds; i++) {
      if (!_isCapturing) break;
      
      try {
        // NOTE: Screenshot package has limitations on Android
        // It captures the app's screen, not the browser
        // We'll need to find an alternative solution for actual browser screenshots
        final image = await _screenshotController.capture();
        
        if (image != null) {
          final file = File('${screenshotDir.path}/screenshot_$i.png');
          await file.writeAsBytes(image);
          _screenshots.add(file);
        }
      } catch (e) {
        print('Error capturing screenshot: $e');
      }
      
      // Wait 1 second before next screenshot
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  
  // Stop packet capture
  Future<void> _stopPacketCapture() async {
    // TODO: Implement stop packet capture
    // This will depend on the approach chosen for packet capture
    
    // Placeholder for now
    print('Packet capture stopped');
  }
  
  // Package results into a ZIP file
  Future<String> _packageResults() async {
    final directory = await getExternalStorageDirectory() ?? 
                      await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFilePath = '${directory.path}/network_logs_$timestamp.zip';
    
    try {
      // Create a ZIP encoder
      final archive = Archive();
      
      // Add diagnostic log
      if (_diagnosticLog != null) {
        final diagnosticFile = File('${directory.path}/diagnostic_log.txt');
        await diagnosticFile.writeAsString(_diagnosticLog!);
        
        final bytes = await diagnosticFile.readAsBytes();
        final archiveFile = ArchiveFile(
          'diagnostic_log.txt',
          bytes.length,
          bytes,
        );
        archive.addFile(archiveFile);
        
        // Clean up temporary file
        await diagnosticFile.delete();
      }
      
      // Add screenshots
      for (int i = 0; i < _screenshots.length; i++) {
        final file = _screenshots[i];
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final archiveFile = ArchiveFile(
            'screenshots/screenshot_$i.png',
            bytes.length,
            bytes,
          );
          archive.addFile(archiveFile);
        }
      }
      
      // Add pcap file if available
      if (_pcapFile != null && await _pcapFile!.exists()) {
        final bytes = await _pcapFile!.readAsBytes();
        final archiveFile = ArchiveFile(
          'packet_capture.pcap',
          bytes.length,
          bytes,
        );
        archive.addFile(archiveFile);
      }
      
      // Encode the archive to a ZIP file
      final zipData = ZipEncoder().encode(archive);
      
      final zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(zipData);
      return zipFilePath;
        } catch (e) {
      print('Error packaging results: $e');
      throw 'Failed to package results: $e';
    }
  }
}
