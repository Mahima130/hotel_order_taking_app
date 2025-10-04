// lib/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // initialize _isFrontCamera from controller's initial facing
    _isFrontCamera = cameraController.facing == CameraFacing.front;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  // Optional: handle lifecycle (pause/resume) if you want
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // keep camera paused when app goes to background
    if (state == AppLifecycleState.paused) {
      cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      cameraController.start();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        setState(() => _isScanned = true);
        _parseQrCode(raw);
        break;
      }
    }
  }

  void _parseQrCode(String code) {
    try {
      final cleanCode = code.toUpperCase().replaceFirst('TABLE:', '');
      final parts =
          cleanCode.contains(':') ? cleanCode.split(':') : cleanCode.split(',');
      if (parts.isEmpty) {
        _showError('Invalid QR code format');
        return;
      }
      final tableNoString = parts[0].trim();
      final tableType = parts.length > 1 ? parts[1].trim() : null;

      Navigator.pop(context, {
        'tableNo': tableNoString,
        'tableType': tableType,
      });
    } catch (e) {
      _showError('Could not read QR code: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isScanned = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Table QR Code'),
        actions: [
          // Torch button: read torch state from controller.value via ValueListenableBuilder
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: cameraController,
            builder: (context, state, child) {
              final torchState = state.torchState;
              IconData icon;
              switch (torchState) {
                case TorchState.off:
                  icon = Icons.flash_off;
                  break;
                case TorchState.on:
                  icon = Icons.flash_on;
                  break;
                case TorchState.auto:
                  icon = Icons.flash_auto;
                  break;
                case TorchState.unavailable:
                default:
                  icon = Icons.flash_off;
                  break;
              }
              return IconButton(
                icon: Icon(icon),
                onPressed: () async {
                  try {
                    await cameraController.toggleTorch();
                  } catch (e) {
                    _showError('Could not toggle torch: $e');
                  }
                },
              );
            },
          ),

          // Camera facing button: toggle and update local state
          IconButton(
            icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: () async {
              try {
                await cameraController.switchCamera();
                setState(() => _isFrontCamera = !_isFrontCamera);
              } catch (e) {
                _showError('Could not switch camera: $e');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // camera preview
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // translucent overlay + scan frame (kept from your design)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0, 0.3, 0.7, 1],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Position QR code within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'QR format: TABLE:101:VIP',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
