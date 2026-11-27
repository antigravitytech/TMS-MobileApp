import 'package:pdf/widgets.dart' show Barcode, BarcodeBar;
import 'package:flutter/material.dart';

/// Paints [data] as a black QR code filling the canvas.
class QrPainter extends CustomPainter {
  const QrPainter(this.data);
  final String data;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (final element
        in Barcode.qrCode()
            .make(data, width: size.width, height: size.height, drawText: false)
            .whereType<BarcodeBar>()) {
      if (element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width,
            element.height,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(QrPainter old) => old.data != data;
}
