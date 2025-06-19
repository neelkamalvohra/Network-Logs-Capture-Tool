import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../services/network_service.dart';
import '../widgets/connectivity_status.dart';
import '../widgets/console_output.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // DNS servers with default values
  final List<String> _dnsServers = ['8.8.8.8', '8.8.4.4', '1.1.1.1', '9.9.9.9'];
  final List<bool> _dnsServersEnabled = [true, true, true, true];
  // TextEditingControllers for DNS servers
  late final List<TextEditingController> _dnsControllers;
  
  bool _isCapturing = false;
  bool _hasOutput = false;
  String _consoleOutput = '';
  ConnectivityResult _connectionType = ConnectivityResult.none;
  bool _isConnected = false;
  Map<String, String?> _publicIPs = {'ipv4': null, 'ipv6': null};
  bool _isLoadingIPs = true;
  
  final NetworkService _networkService = NetworkService();  @override
  void initState() {
    super.initState();
    // Initialize DNS controllers with default values
    _dnsControllers = List.generate(
      _dnsServers.length,
      (index) => TextEditingController(text: _dnsServers[index])
    );
    _checkConnectivity();
    _fetchPublicIPs();
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    // Dispose DNS controllers
    for (var controller in _dnsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Fetch public IP addresses
  Future<void> _fetchPublicIPs() async {
    setState(() => _isLoadingIPs = true);
    try {
      final ips = await _networkService.getPublicIPs();
      setState(() {
        _publicIPs = ips;
        _isLoadingIPs = false;
      });
    } catch (e) {
      setState(() => _isLoadingIPs = false);
      print('Error fetching IPs: $e');
    }
  }

  // Check initial connectivity
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = await InternetConnectionChecker().hasConnection;
    
    setState(() {
      _connectionType = connectivityResult;
      _isConnected = isConnected;
    });
  }

  // Update connection status when it changes
  void _updateConnectionStatus(ConnectivityResult result) async {
    final isConnected = await InternetConnectionChecker().hasConnection;
    setState(() {
      _connectionType = result;
      _isConnected = isConnected;
    });
  }  // Start capturing logs
  void _startCapture() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a website URL')),
      );
      return;
    }

    final targetUrl = _urlController.text.trim();

    setState(() {
      _isCapturing = true;
      _consoleOutput = '';
      _hasOutput = true;
    });

    try {
      // Add timestamp and target URL
      final now = DateTime.now();
      final formattedDate = DateFormat('M/d/yyyy, h:mm:ss a').format(now);
      _appendToConsole('DIAGNOSTIC RUN: $formattedDate\n');
      _appendToConsole('Target URL: $targetUrl\n\n');
      
      // Step 1: Get public IP addresses
      final publicIPs = await _networkService.getPublicIPs();
      setState(() => _publicIPs = publicIPs);
      _appendToConsole('Public IPv4: ${publicIPs['ipv4'] ?? 'Not available'}\n');
      _appendToConsole('Public IPv6: ${publicIPs['ipv6'] ?? 'Not available'}\n\n');

      // Step 2: Perform DNS lookups
      final List<String> enabledDnsServers = [];
      for (int i = 0; i < _dnsServers.length; i++) {
        if (_dnsServersEnabled[i]) {
          enabledDnsServers.add(_dnsServers[i]);
        }
      }      final List<String> uniqueIPs = [];
      
      _appendToConsole('Performing DNS lookups for $targetUrl\n');
      for (final dns in enabledDnsServers) {
        if (!_isCapturing) break; // Check if capture was stopped
        
        _appendToConsole('\nDNS Server: $dns\n');
        final lookupResult = await _networkService.performDnsLookup(targetUrl, dns);
        _appendToConsole(lookupResult.output);
        
        // Extract IPs from the lookup result and add to uniqueIPs
        for (final ip in lookupResult.ips) {
          if (!uniqueIPs.contains(ip)) {
            uniqueIPs.add(ip);
          }
        }
      }

      // Count IPv4 and IPv6 addresses
      final ipv4Addresses = uniqueIPs.where((ip) => ip.contains('.')).toList();
      final ipv6Addresses = uniqueIPs.where((ip) => ip.contains(':')).toList();

      // Step 3: Traceroute to unique IPs
      _appendToConsole('\nPerforming traceroute to ${uniqueIPs.length} unique IPs '
          '(${ipv4Addresses.length} IPv4, ${ipv6Addresses.length} IPv6)...\n');
      
      for (final ip in uniqueIPs) {
        if (!_isCapturing) break; // Check if capture was stopped
        
        _appendToConsole('\nTraceroute to $ip:\n');
        final tracertResult = await _networkService.performTraceroute(ip);
        _appendToConsole(tracertResult);
      }

      // Step 4: Ping unique IPs
      _appendToConsole('\nPinging unique IPs...\n');
      for (final ip in uniqueIPs) {
        if (!_isCapturing) break; // Check if capture was stopped
        
        _appendToConsole('\nPing to $ip:\n');
        final pingResult = await _networkService.pingHost(ip);
        _appendToConsole(pingResult);
      }

      _appendToConsole('\nCapture completed!\n');
    } catch (e) {
      _appendToConsole('\nError during capture: $e\n');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  // Stop the capture process
  void _stopCapture() {
    if (_isCapturing) {
      setState(() {
        _isCapturing = false;
        _appendToConsole('\nCapture stopped by user.\n');
      });
    }
  }
  // Clear console output
  void _clearConsole() {
    setState(() {
      _consoleOutput = '';
      _hasOutput = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs cleared')),
    );
  }

  // Copy console output to clipboard
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _consoleOutput)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copied to clipboard')),
      );
    });
  }

  // Append text to console output
  void _appendToConsole(String text) {
    if (mounted) {
      setState(() {
        _consoleOutput += text;
        // Auto-scroll to bottom
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Network Logs Capture Tool'),
            const Text(
              'Developed by Neel',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connectivity status indicator
            ConnectivityStatus(
              isConnected: _isConnected,
              connectionType: _connectionType,
            ),
            
            // Public IP display
            if (_publicIPs['ipv4'] != null || _publicIPs['ipv6'] != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_publicIPs['ipv4'] != null)
                      Text(
                        'Public IPv4: ${_publicIPs['ipv4']}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    if (_publicIPs['ipv6'] != null)
                      Text(
                        'Public IPv6: ${_publicIPs['ipv6']}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // URL input field
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Enter website URL (e.g., example.com)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              enabled: !_isCapturing,
            ),
            
            const SizedBox(height: 16),            // DNS servers selection
            const Text(
              'DNS Servers:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 3.5,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  _dnsServers.length,
                  (index) => Row(
                    children: [
                      Checkbox(
                        value: _dnsServersEnabled[index],
                        onChanged: _isCapturing
                            ? null
                            : (selected) {
                                setState(() {
                                  _dnsServersEnabled[index] = selected!;
                                });
                              },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _dnsControllers[index],
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          enabled: !_isCapturing && _dnsServersEnabled[index],
                          style: const TextStyle(fontSize: 12),
                          onChanged: (value) {
                            _dnsServers[index] = value;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
              // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCapturing ? null : _startCapture,
                    icon: const Icon(Icons.network_check),
                    label: const Text('Capture Logs'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCapturing ? _stopCapture : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Capture'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Second row: Copy and Clear buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _hasOutput && !_isCapturing ? _copyToClipboard : null,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Logs'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _hasOutput && !_isCapturing ? _clearConsole : null,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Logs'),                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Console output
            Expanded(
              child: ConsoleOutput(
                output: _consoleOutput,
                scrollController: _scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
