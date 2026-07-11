import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/label_scanner_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final code = capture.barcodes
        .where((b) => b.rawValue != null)
        .where((b) => RegExp(r'^\d{6,14}$').hasMatch(b.rawValue!))
        .map((b) => b.rawValue!)
        .firstOrNull;

    if (code == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    final result = await LabelScannerService().lookupBarcode(code);

    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Código de Barras',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Lanterna',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay escuro nas laterais com janela central
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(color: Colors.transparent),
                Center(
                  child: Container(
                    width: 270,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Moldura verde na janela de scan
          Center(
            child: Container(
              width: 270,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00E676), width: 2.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Texto de instrução
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Text(
              _processing
                  ? 'A procurar produto...'
                  : 'Centra o código de barras na moldura',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          if (_processing)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            ),
        ],
      ),
    );
  }
}
