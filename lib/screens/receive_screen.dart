import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;

import '../services/auth_service.dart';
import '../widgets/gradient_app_bar.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final _amountController = TextEditingController();
  final _qrKey = GlobalKey();
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId != null) {
      _updateQrData(userId, null);
    }
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId != null) {
      final amount = double.tryParse(_amountController.text);
      _updateQrData(userId, amount);
    }
  }

  void _updateQrData(String userId, double? amount) {
    final data = {
      'userId': userId,
      if (amount != null && amount > 0) 'amount': amount,
    };
    setState(() {
      _qrData = jsonEncode(data);
    });
  }

  Future<void> _captureAndSave() async {
    try {
      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // Web implementation: download the file
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'afercon_pay_qr_code.png';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile implementation: save to gallery using gal
        final hasAccess = await Gal.requestAccess();
        if (hasAccess) {
            await Gal.putImageBytes(pngBytes, album: 'AferconPay');
        } else {
            throw Exception('Permissão para aceder à galeria foi negada.');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code guardado com sucesso na galeria!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar o QR Code: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.currentUser?.displayName ?? 'Utilizador Afercon';
    final userPhotoUrl = authService.currentUser?.photoURL;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: GradientAppBar(
        title: const Text('Receber Pagamento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildQrCard(context, _qrData, userName, userPhotoUrl),
                  const SizedBox(height: 24),
                  _buildAmountInput(context),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard(BuildContext context, String qrData, String userName, String? photoUrl) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      key: _qrKey,
      child: Card(
        elevation: 12,
        shadowColor: theme.shadowColor.withAlpha(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text('Mostre este código para receber', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (qrData.isNotEmpty)
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220.0,
                  gapless: false,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: theme.colorScheme.onSurface),
                  dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: theme.colorScheme.onSurface),
                  embeddedImage: photoUrl != null 
                      ? NetworkImage(photoUrl) 
                      : const AssetImage('assets/afercon.logo.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(40, 40),
                  ),
                ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(userName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildAmountInput(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: 'Montante Específico (Opcional)',
        labelStyle: theme.textTheme.labelMedium,
        prefixIcon: Icon(Iconsax.money_send, color: theme.colorScheme.primary),
        suffixText: 'Kz',
        suffixStyle: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withAlpha(150)),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 250, 
          child: ElevatedButton.icon(
            icon: const Icon(Iconsax.document_download, size: 20),
            label: const Text('Guardar na Galeria'),
            onPressed: _captureAndSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}
