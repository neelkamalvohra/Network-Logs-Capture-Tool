# Network Logs Capture Tool

A lightweight Android application for support engineers to collect network logs when troubleshooting website connectivity issues.

## Features

- **Internet Connectivity Status**: Shows current network status (WiFi or Mobile Data) with visual indicator
- **Website Diagnostics**: Enter any website URL to diagnose connection issues
- **Comprehensive Tests**:
  - Public IP address detection (IPv4 & IPv6)
  - DNS lookups with customizable DNS servers
  - Traceroute to all discovered IPs
  - Ping tests to verify connectivity
- **Real-time Output**: View test results in a console-like interface
- **Copy Results**: Copy all collected logs to clipboard with a single tap
- **Configurable**: Choose which DNS servers to use for lookups

## Purpose

This app is designed for support engineers who need to collect network diagnostics when customers report website connectivity issues. Instead of requiring an on-site visit, engineers can share this app with customers to gather the necessary troubleshooting information remotely.

## Requirements

- Android 5.0 (API level 21) or higher
- Internet connection (for performing diagnostics)

## Installation

1. Download the APK from releases
2. Install on your Android device

## Development

### Prerequisites

- Flutter 3.x
- Dart 3.x
- Android Studio / VS Code with Flutter extensions

### Setup

1. Clone this repository:
```
git clone https://github.com/neelkamalvohra/Network-Logs-Capture-Tool.git
```

2. Navigate to the project directory:
```
cd Network-Logs-Capture-Tool
```

3. Install dependencies:
```
flutter pub get
```

4. Run the application:
```
flutter run
```
3. Grant the required network permissions

Alternatively, build from source:

```bash
flutter pub get
flutter build apk --release
```

## Usage

1. Launch the app and check for internet connectivity (indicator will be green if connected)
2. Enter the problematic website URL in the input field
3. Press "Capture Logs" to start the diagnostic process
4. View the results in real-time in the console output
5. Once complete, tap the copy button to copy all logs to clipboard
6. Share the logs with your support team

## Size Optimization

This app is designed to be minimal in size for easy sharing via messaging apps like WhatsApp.
