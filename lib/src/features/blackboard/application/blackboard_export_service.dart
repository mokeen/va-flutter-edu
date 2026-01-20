import 'package:flutter/services.dart' show Uint8List, Offset, rootBundle;
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:va_edu/src/features/blackboard/domain/blackboard_model.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Paint, PaintingStyle, Path, Canvas, StrokeCap, StrokeJoin, TextPainter, TextSpan, TextStyle, TextDirection;

/// 处理黑板数据向专业格式（PDF/图片）导出的服务
class BlackboardExportService {
  /// 将整个课件导出为 PDF 并返回字节
  static Future<Uint8List> exportToPdf(BlackboardData data, {bool darkTheme = false, double width = 1600, double logicalHeight = 1000}) async {
    final pdfDoc = pw.Document();
    
    // 检查是否包含文本类型（只有包含文本才需要加载字体）
    final bool hasText = data.pages.any((page) => page.any((s) => s.type == StrokeType.text));
    
    pw.Font? font;
    pw.Font? fontBold;
    
    if (hasText) {
      try {
        font = await _loadFont('assets/fonts/NotoSansSC-Regular.ttf', isBold: false);
        fontBold = await _loadFont('assets/fonts/NotoSansSC-Bold.ttf', isBold: true);
      } catch (e) {
        font = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }
    }

    final scale = width / 1000.0;
    final pdfHeight = logicalHeight * scale;

    for (int i = 0; i < data.pages.length; i++) {
       await Future.delayed(Duration.zero);
       
      final pageStrokes = data.pages[i];
      pdfDoc.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat(width, pdfHeight, marginAll: 0),
          build: (pw.Context context) {
            return pw.Container(
              color: darkTheme ? const pdf.PdfColor.fromInt(0xFF1A1A1A) : pdf.PdfColors.white,
              child: _PdfStrokesWidget(
                strokes: pageStrokes,
                font: font,
                fontBold: fontBold,
                scale: scale,
                darkTheme: darkTheme,
              ),
            );
          },
        ),
      );
    }

    return pdfDoc.save();
  }

  static Future<Uint8List> exportToPng(BlackboardData data, {bool darkTheme = false, double width = 1600, double pageHeight = 1000}) async {
    final scale = width / 1000.0; // 基于 BlackboardController.baseWidth
    final double totalHeight = data.pages.length * pageHeight * scale;
    final int pagesToRender = data.pages.length;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // 绘制背景
    final bgPaint = Paint()..color = darkTheme ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, totalHeight), bgPaint);

    // 绘制主循环 (保持同步绘制以确保状态一致性)
    for (int i = 0; i < pagesToRender; i++) {
      final strokes = data.pages[i];
      final yOffset = i * pageHeight * scale;
      
      canvas.save();
      canvas.translate(0, yOffset);
      canvas.scale(scale);
      
      for (final stroke in strokes) {
        _drawStrokeToCanvas(canvas, stroke);
      }
      
      canvas.restore();
    }

    final picture = recorder.endRecording();
    
    // 提示：部分平台对 toImage 尺寸存在 hardware-dependent 限制 (如 8192px)。
    // 若高度超出范围且发生异常，可考虑分段导出或转为 PDF 格式。
    try {
      final img = await picture.toImage(width.toInt(), totalHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('PNG toImage failed: $e. Your lesson might be too long for a single image.');
      rethrow;
    }
  }

  static void _drawStrokeToCanvas(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = Color(stroke.style.color)
      ..strokeWidth = stroke.style.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.style.isHighlighter) {
      paint.color = paint.color.withValues(alpha: 0.4);
    }

    switch (stroke.type) {
      case StrokeType.freehand:
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        if (stroke.style.isDashed) {
          _drawDashedPath(canvas, path, paint);
        } else {
          canvas.drawPath(path, paint);
        }
        break;
      case StrokeType.line:
        if (stroke.points.length < 2) break;
        if (stroke.style.isDashed) {
          final path = Path();
          path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
          path.lineTo(stroke.points[1].dx, stroke.points[1].dy);
          _drawDashedPath(canvas, path, paint);
        } else {
          canvas.drawLine(stroke.points[0], stroke.points[1], paint);
        }
        break;
      case StrokeType.rect:
        if (stroke.points.length < 2) break;
        final rect = ui.Rect.fromPoints(stroke.points[0], stroke.points[1]);
        if (stroke.style.isDashed) {
          final path = Path()..addRect(rect);
          _drawDashedPath(canvas, path, paint);
        } else {
          canvas.drawRect(rect, paint);
        }
        break;
      case StrokeType.circle:
        if (stroke.points.length < 2) break;
        final rect = ui.Rect.fromPoints(stroke.points[0], stroke.points[1]);
        if (stroke.style.isDashed) {
          final path = Path()..addOval(rect);
          _drawDashedPath(canvas, path, paint);
        } else {
          canvas.drawOval(rect, paint);
        }
        break;
      case StrokeType.text:
        if (stroke.text == null || stroke.points.isEmpty) break;
        
        final texts = stroke.text!.split('\n');
        for (int i = 0; i < texts.length; i++) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: texts[i],
              style: TextStyle(
                color: Color(stroke.style.color),
                fontSize: stroke.style.width,
                fontFamily: 'Montserrat',
                fontFamilyFallback: const ['NotoSansSC'],
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          
          final offset = Offset(
            stroke.points.first.dx, 
            stroke.points.first.dy + (i * stroke.style.width * 1.2)
          );
          textPainter.paint(canvas, offset);
        }
        break;
    }
  }

  /// 辅助方法：在 Canvas 上绘制虚线路径
  static void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 10.0;
    const double dashSpace = 8.0;
    
    final ui.Path dashPath = ui.Path();
    for (final ui.PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double nextDistance = distance + dashWidth;
        dashPath.addPath(
          pathMetric.extractPath(distance, nextDistance),
          ui.Offset.zero,
        );
        distance = nextDistance + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  /// 交互式保存文件（通用）
  /// 如果提供了 defaultPath (未来用于设置打通)，则直接存；否则弹出系统对话框
  static Future<String?> interactiveSave(Uint8List bytes, String fileName, {String? defaultPath}) async {
    String? savePath;

    if (defaultPath != null && defaultPath.isNotEmpty) {
      // 1. 如果有设置页面的默认路径，直接保存
      savePath = '$defaultPath/$fileName';
      final file = io.File(savePath);
      await file.writeAsBytes(bytes);
    } else {
      // 2. 否则调起系统“另存为”对话框
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [fileName.split('.').last],
      );

      if (savePath != null) {
        final file = io.File(savePath);
        await file.writeAsBytes(bytes);
      }
    }
    return savePath;
  }

  /// 弹出系统打印对话框 (保留，作为备选或纯打印需求)
  static Future<void> printPdf(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (pdf.PdfPageFormat format) async => bytes,
      name: fileName,
    );
  }

  /// 在文件管理器中显示（reveal in Finder/Explorer）
  static Future<void> revealInFolder(String filePath) async {
    if (io.Platform.isMacOS) {
      await io.Process.run('open', ['-R', filePath]);
    } else if (io.Platform.isWindows) {
      await io.Process.run('explorer.exe', ['/select,', filePath.replaceAll('/', '\\')]);
    }
  }

  /// 智能加载字体：优先本地 Asset，其次 Google Fonts，最后回退
  static Future<pw.Font> _loadFont(String assetPath, {required bool isBold}) async {
    try {
      // 1. 尝试从本地 Assets 加载
      final byteData = await rootBundle.load(assetPath);
      return pw.Font.ttf(byteData);
    } catch (e) {
      debugPrint('Local font $assetPath not found, trying network: $e');
      try {
        // 2. 尝试从网络加载 (增加 5 秒超时，防止无限等待)
        return await (isBold 
            ? PdfGoogleFonts.notoSansSCBold() 
            : PdfGoogleFonts.notoSansSCRegular()).timeout(const Duration(seconds: 5));
      } catch (ne) {
        debugPrint('Network font download failed or timed out: $ne');
        // 3. 最终回退
        return isBold ? pw.Font.helveticaBold() : pw.Font.helvetica();
      }
    }
  }
}

/// 专门用于在 PDF 上绘制笔迹的 Widget
class _PdfStrokesWidget extends pw.Widget {
  final List<Stroke> strokes;
  final pw.Font? font;
  final pw.Font? fontBold;
  final double scale;
  final bool darkTheme;

  _PdfStrokesWidget({
    required this.strokes,
    this.font,
    this.fontBold,
    this.scale = 1.0,
    this.darkTheme = false,
  });

  @override
  void layout(pw.Context context, pw.BoxConstraints constraints, {bool parentUsesSize = false}) {
    box = pdf.PdfRect.fromPoints(pdf.PdfPoint.zero, constraints.biggest);
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final canvas = context.canvas;
    final size = box!; // Now it's a pdf.PdfRect

    for (final stroke in strokes) {
      _drawStroke(context, canvas, stroke, size);
    }
  }

  void _drawStroke(pw.Context context, pdf.PdfGraphics canvas, Stroke stroke, pdf.PdfRect size) {
    if (stroke.points.isEmpty) return;

    final color = pdf.PdfColor.fromInt(stroke.style.color);
    double opacity = 1.0;
    if (stroke.style.isHighlighter) {
      opacity = 0.4;
    }

    canvas.saveContext();
    
    // 处理颜色：如果是浅色底 PDF，将白色/浅色笔画转为黑色
    pdf.PdfColor effectiveColor = color;
    if (!darkTheme) {
      final flutterColor = Color(stroke.style.color);
      if (flutterColor.computeLuminance() > 0.8) {
        effectiveColor = pdf.PdfColors.black;
      }
    }
    
    canvas.setStrokeColor(effectiveColor);
    canvas.setLineWidth(stroke.style.width * scale);
    canvas.setLineCap(pdf.PdfLineCap.round);
    canvas.setLineJoin(pdf.PdfLineJoin.round);

    // 处理虚线
    if (stroke.style.isDashed) {
      canvas.setLineDashPattern([5 * scale, 5 * scale], 0);
    } else {
      canvas.setLineDashPattern([], 0);
    }
    
    if (opacity < 1.0) {
      canvas.setGraphicState(pdf.PdfGraphicState(opacity: opacity));
    }

    pdf.PdfPoint toPdf(Offset p) => pdf.PdfPoint(p.dx * scale, size.height - (p.dy * scale));

    switch (stroke.type) {
      case StrokeType.freehand:
        if (stroke.points.length < 2) break;
        final start = toPdf(stroke.points.first);
        canvas.moveTo(start.x, start.y);
        for (int i = 1; i < stroke.points.length; i++) {
          final p = toPdf(stroke.points[i]);
          canvas.lineTo(p.x, p.y);
        }
        canvas.strokePath();
        break;

      case StrokeType.line:
        if (stroke.points.length < 2) break;
        final p1 = toPdf(stroke.points[0]);
        final p2 = toPdf(stroke.points[1]);
        canvas.drawLine(p1.x, p1.y, p2.x, p2.y);
        canvas.strokePath();
        break;

      case StrokeType.rect:
        if (stroke.points.length < 2) break;
        final p1 = toPdf(stroke.points[0]);
        final p2 = toPdf(stroke.points[1]);
        // 确保使用 PDF 坐标系下的正确 min/max
        final rectX = p1.x < p2.x ? p1.x : p2.x;
        final rectY = p1.y < p2.y ? p1.y : p2.y;
        final rectW = (p1.x - p2.x).abs();
        final rectH = (p1.y - p2.y).abs();
        canvas.drawRect(rectX, rectY, rectW, rectH);
        canvas.strokePath();
        break;

      case StrokeType.circle:
        if (stroke.points.length < 2) break;
        final p1 = toPdf(stroke.points[0]);
        final p2 = toPdf(stroke.points[1]);
        final rectX = p1.x < p2.x ? p1.x : p2.x;
        final rectY = p1.y < p2.y ? p1.y : p2.y;
        final rectW = (p1.x - p2.x).abs();
        final rectH = (p1.y - p2.y).abs();
        canvas.drawEllipse(rectX + rectW / 2, rectY + rectH / 2, rectW / 2, rectH / 2);
        canvas.strokePath();
        break;

      case StrokeType.text:
        if (stroke.text == null || stroke.points.isEmpty || font == null) break;
        
        try {
          final p = toPdf(stroke.points.first);
          
          // 文本也要处理颜色反转
          pdf.PdfColor effectiveTextColor = color;
          if (!darkTheme) {
            final flutterColor = Color(stroke.style.color);
            if (flutterColor.computeLuminance() > 0.8) {
              effectiveTextColor = pdf.PdfColors.black;
            }
          }
          
          canvas.setFillColor(effectiveTextColor);
          
          // 处理多行文本：pdf 库不支持 \n，需要手动拆分渲染
          final lines = stroke.text!.split('\n');
          final fontSize = stroke.style.width * scale;
          final lineHeight = fontSize * 1.2; // 估算行高

          for (int i = 0; i < lines.length; i++) {
            final lineText = lines[i];
            // 修正坐标：PDF 坐标系从下往上，换行需要 y 轴递减
            final lineY = p.y - fontSize - (i * lineHeight);
            
            canvas.drawString(
              font!.getFont(context),
              fontSize,
              lineText,
              p.x,
              lineY,
            );
          }
        } catch (e) {
          // 如果字体不支持某些字符 (如 Helvetica 画中文), 这里的异常会被捕获
          // 防止整个 PDF 导出任务崩溃导致一直在 loading
          debugPrint('Failed to draw text stroke: $e');
        }
        break;
    }

    canvas.restoreContext();
  }
}
