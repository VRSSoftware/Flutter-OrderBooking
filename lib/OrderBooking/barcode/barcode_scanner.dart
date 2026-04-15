import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.code39],
  );

  bool _isFlashOn = false;
  bool _cameraStarted = false;
  String? _error;

  BarcodeCapture? lastCapture;

  Future<void> _startCamera() async {
    try {
      setState(() => _error = null);
      await _controller.start();
      _cameraStarted = true;
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _onCapturePressed() {
    if (lastCapture != null && lastCapture!.barcodes.isNotEmpty) {
      final code = lastCapture!.barcodes.first.rawValue;
      if (code != null) {
        // Single scan mode: return immediately
        Navigator.pop(context, [code]);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No barcode detected")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCamera();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () async {
                setState(() => _isFlashOn = !_isFlashOn);
                await _controller.toggleTorch();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_error == null)
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  lastCapture = capture;
                },
                errorBuilder: (context, error, child) {
                  return _buildError(error.toString());
                },
              )
            else
              _buildError(_error!),

            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 2),
                ),
              ),
            ),

            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _onCapturePressed,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(
              "Camera error",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _startCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}