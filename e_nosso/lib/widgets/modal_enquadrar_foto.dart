import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Modal interativo para enquadramento e recorte de fotos em proporção fixa 1:1.
class ModalEnquadrarFoto extends StatefulWidget {
  final Uint8List imageBytes;
  final String titulo;
  final String descricao;

  const ModalEnquadrarFoto({
    super.key,
    required this.imageBytes,
    this.titulo = 'Enquadrar Foto',
    this.descricao = 'Arraste e use o gesto de pinça/zoom para enquadrar a foto na moldura quadrada fixa (1:1).',
  });

  /// Método estático utilitário para exibir o enquadrador e retornar os bytes recortados.
  static Future<Uint8List?> exibir(
    BuildContext context,
    Uint8List imageBytes, {
    String titulo = 'Enquadrar Foto',
    String descricao = 'Arraste e use o gesto de pinça/zoom para enquadrar a foto na moldura quadrada fixa (1:1).',
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEnquadrarFoto(
        imageBytes: imageBytes,
        titulo: titulo,
        descricao: descricao,
      ),
    );
  }

  @override
  State<ModalEnquadrarFoto> createState() => _ModalEnquadrarFotoState();
}

class _ModalEnquadrarFotoState extends State<ModalEnquadrarFoto> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();
  bool _processando = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetarZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _confirmarRecorte() async {
    if (_processando) return;
    setState(() => _processando = true);

    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.pop(context, widget.imageBytes);
        return;
      }

      // Captura o bitmap recortado nos exatos limites do quadrado com alta fidelidade
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List croppedBytes = byteData.buffer.asUint8List();
        if (mounted) Navigator.pop(context, croppedBytes);
      } else {
        if (mounted) Navigator.pop(context, widget.imageBytes);
      }
    } catch (e) {
      debugPrint('Erro ao recortar imagem: $e');
      if (mounted) Navigator.pop(context, widget.imageBytes);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double boxSize =
        (screenSize.width * 0.8).clamp(240.0, 320.0).toDouble();

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.crop, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.descricao,
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.3),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),

            // Área de Recorte Quadrada com Proporção Fixa 1:1
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white54, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Área que será capturada no recorte (apenas a imagem limpa)
                    RepaintBoundary(
                      key: _cropKey,
                      child: Container(
                        color: Colors.black,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.8,
                          maxScale: 4.0,
                          boundaryMargin: EdgeInsets.all(boxSize),
                          clipBehavior: Clip.hardEdge,
                          child: Center(
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Grade de guia visual da Regra dos Terços (fica visível na tela mas FORA do recorte)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _GridGuidePainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Botão de resetar zoom
            TextButton.icon(
              onPressed: _resetarZoom,
              icon: const Icon(Icons.restart_alt, size: 18, color: Colors.white70),
              label: const Text(
                'Resetar Posição / Zoom',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processando ? null : _confirmarRecorte,
                    icon: _processando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Enquadrar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenha linhas suaves de grade (Regra dos Terços) sobre a área de enquadramento
class _GridGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Linhas verticais
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Linhas horizontais
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
