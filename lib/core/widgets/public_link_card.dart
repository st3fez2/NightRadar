import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../public_link_config.dart';

class PublicLinkCard extends StatefulWidget {
  const PublicLinkCard({
    super.key,
    this.title = 'QR pubblico NightRadar',
    this.subtitle =
        'Condividi subito il link pubblico del progetto, scarica il QR o apri il sito live.',
  });

  final String title;
  final String subtitle;

  @override
  State<PublicLinkCard> createState() => _PublicLinkCardState();
}

class _PublicLinkCardState extends State<PublicLinkCard> {
  bool _isWorking = false;

  String get _publicUrl => PublicLinkConfig.resolveAppUrl();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE5DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PUBLIC LINK LIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (_isWorking)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(widget.subtitle),
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _publicUrl,
                  size: compact ? 170 : 210,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Link pubblico',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2ECE5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: SelectableText(
                _publicUrl,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isWorking ? null : _shareQr,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Condividi QR'),
                ),
                OutlinedButton.icon(
                  onPressed: _isWorking ? null : _downloadQr,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Scarica'),
                ),
                OutlinedButton.icon(
                  onPressed: _isWorking ? null : _copyLink,
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('Copia link'),
                ),
                TextButton.icon(
                  onPressed: _isWorking ? null : _openLink,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Apri sito'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _publicUrl));
    _showMessage('Link pubblico copiato');
  }

  Future<void> _openLink() async {
    final opened = await launchUrl(
      Uri.parse(_publicUrl),
      webOnlyWindowName: '_blank',
    );

    if (!opened) {
      _showMessage('Impossibile aprire il link pubblico');
    }
  }

  Future<void> _downloadQr() async {
    await _runWithLoader(() async {
      final bytes = await _buildQrBytes();
      await FileSaver.instance.saveFile(
        name: 'nightradar-public-qr',
        bytes: bytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      _showMessage('QR scaricato con successo');
    });
  }

  Future<void> _shareQr() async {
    await _runWithLoader(() async {
      final bytes = await _buildQrBytes();
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          title: 'NightRadar',
          subject: 'NightRadar',
          text: 'NightRadar\n$_publicUrl',
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: 'nightradar-public-qr.png',
            ),
          ],
          fileNameOverrides: const ['nightradar-public-qr.png'],
          downloadFallbackEnabled: true,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    });
  }

  Future<Uint8List> _buildQrBytes() async {
    final painter = QrPainter(
      data: _publicUrl,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF18130F),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF18130F),
      ),
    );
    final byteData = await painter.toImageData(
      1200,
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Impossibile generare il QR');
    }

    return byteData.buffer.asUint8List();
  }

  Future<void> _runWithLoader(Future<void> Function() action) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
