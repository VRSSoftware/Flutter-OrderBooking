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
  bool _continuousScan = false;
  List<String> _scannedBarcodes = [];
  Set<String> _scannedSet = {};

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
        if (_continuousScan) {
          // Continuous mode: add to list
          if (!_scannedSet.contains(code)) {
            setState(() {
              _scannedBarcodes.add(code);
              _scannedSet.add(code);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added: $code'),
                duration: const Duration(milliseconds: 800),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Already in list: $code'),
                duration: const Duration(milliseconds: 800),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // Single scan mode: return immediately
          Navigator.pop(context, [code]);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No barcode detected")),
      );
    }
  }

  void _showScannedList() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scanned Barcodes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Expanded(
                      child: _scannedBarcodes.isEmpty
                          ? const Center(child: Text('No barcodes scanned'))
                          : ListView.builder(
                              itemCount: _scannedBarcodes.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryColor,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    _scannedBarcodes[index],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _scannedSet.remove(_scannedBarcodes[index]);
                                        _scannedBarcodes.removeAt(index);
                                      });
                                      setStateSheet(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_scannedBarcodes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _scannedBarcodes.clear();
                                    _scannedSet.clear();
                                  });
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Return the list when confirming
                                  Navigator.pop(context, _scannedBarcodes);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                ),
                                child: Text('Confirm (${_scannedBarcodes.length})'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((result) {
      // Handle the result when bottom sheet closes
      if (result != null && result is List<String> && result.isNotEmpty) {
        // Return the list to the calling screen
        Navigator.pop(context, result);
      }
    });
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.primaryColor,
            child: Row(
              children: [
                Checkbox(
                  value: _continuousScan,
                  onChanged: (value) {
                    setState(() {
                      _continuousScan = value ?? false;
                      if (!_continuousScan && _scannedBarcodes.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear List?'),
                            content: Text('You have ${_scannedBarcodes.length} barcode(s). Clear them?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _scannedBarcodes.clear();
                                    _scannedSet.clear();
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Clear'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Keep'),
                              ),
                            ],
                          ),
                        );
                      }
                    });
                  },
                  activeColor: Colors.white,
                  checkColor: AppColors.primaryColor,
                ),
                const Text(
                  'Continuous Scan',
                  style: TextStyle(color: Colors.white),
                ),
                const Spacer(),
                if (_continuousScan && _scannedBarcodes.isNotEmpty)
                  GestureDetector(
                    onTap: _showScannedList,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_scannedBarcodes.length} items',
                        style: const TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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