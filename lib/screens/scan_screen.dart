import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import '../main.dart';
import '../widgets/gradient_app_bar.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  late AnimationController _animationController;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final String? rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;
      final userId = data['userId'] as String?;
      final amount = (data['amount'] as num?)?.toDouble();

      if (userId == null) throw 'QR Code inválido.';

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final recipientData = await firestoreService.getUserData(userId);

      if (!mounted) return;
      context.push('/payment-confirmation', extra: {
        'recipientData': recipientData,
        'amount': amount,
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ler QR Code: ${e.toString()}'), backgroundColor: Colors.red),
        );
        _resetScanner();
      }
    }
  }

  Future<void> _pickAndScanImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final BarcodeCapture? result = await _scannerController.analyzeImage(image.path);

    if (result != null && result.barcodes.isNotEmpty) {
      _handleBarcode(result);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum QR Code encontrado na imagem.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _resetScanner() {
    if (mounted) {
      setState(() => _isProcessing = false);
      _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Escanear para Pagar'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.flash_1),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Lanterna',
          ),
          IconButton(
            icon: const Icon(Iconsax.gallery),
            onPressed: _pickAndScanImage,
            tooltip: 'Escolher da Galeria',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          QRScannerOverlay(overlayColour: Colors.black.withAlpha(153), animation: _animationController),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }
}

// The QRScannerOverlay and QRScannerOverlayPainter classes remain the same
class QRScannerOverlay extends StatelessWidget {
  final Color overlayColour;
  final Animation<double> animation;

  const QRScannerOverlay({super.key, required this.overlayColour, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            overlayColour,
            BlendMode.srcOut,
          ), 
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: CustomPaint(
            painter: QRScannerOverlayPainter(),
            child: const SizedBox(width: 260, height: 260),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -130 + (animation.value * 260)),
                child: Container(
                  height: 2,
                  width: 240,
                  color: AppColors.primaryGreen,
                ),
              );
            },
          ),
        ),
        const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Aponte a câmara para o QR Code', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.white, fontSize: 16),
            )
        )
      ],
    );
  }
}

class QRScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const p = 0.0;

    // Top-left corner
    canvas.drawLine(const Offset(p, p), const Offset(p + cornerLength, p), paint);
    canvas.drawLine(const Offset(p, p), const Offset(p, p + cornerLength), paint);

    // Top-right corner
    canvas.drawLine(Offset(size.width - p, p), Offset(size.width - p - cornerLength, p), paint);
    canvas.drawLine(Offset(size.width - p, p), Offset(size.width - p, p + cornerLength), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(p, size.height - p), Offset(p + cornerLength, size.height - p), paint);
    canvas.drawLine(Offset(p, size.height - p), Offset(p, size.height - p - cornerLength), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width - p, size.height - p), Offset(size.width - p - cornerLength, size.height - p), paint);
    canvas.drawLine(Offset(size.width - p, size.height - p), Offset(size.width - p, size.height - p - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
