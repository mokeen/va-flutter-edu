import 'package:flutter/material.dart';

/// 笔迹类型
enum StrokeType {
  freehand, // 自由曲线
  line,     // 直线
  circle,   // 圆/椭圆
  rect,     // 矩形
  text,     // 文本
}

/// 笔迹样式
class StrokeStyle {
  final int color; // AARRGGBB
  final double width;
  final bool isHighlighter; // 荧光笔模式 (半透明叠加)
  final bool isDashed;      // 虚线模式

  const StrokeStyle({
    required this.color,
    required this.width,
    this.isHighlighter = false,
    this.isDashed = false,
  });

  /// 默认样式
  static const StrokeStyle defaultStyle = StrokeStyle(
    color: 0xFFFFFFFF, // White
    width: 2.0,
  );
  
  /// 荧光笔默认样式
  static const StrokeStyle highlighterDefault = StrokeStyle(
    color: 0xFFFFFF00, // Yellow
    width: 15.0,
    isHighlighter: true,
  );

  /// 转换为 Paint 对象
  Paint toPaint() {
    final paint = Paint()
      ..color = Color(color)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (isHighlighter) {
      // 荧光笔使用半透明叠加，或者 Multiply 混合模式
      // 这里简单使用半透明处理，BlendMode 在 Layer 合成时再处理可能更好
      // 通过调整颜色的 Alpha 通道实现
      paint.color = Color(color).withAlpha(100); 
    }

    return paint;
  }
  
  StrokeStyle copyWith({
    int? color,
    double? width,
    bool? isHighlighter,
    bool? isDashed,
  }) {
    return StrokeStyle(
      color: color ?? this.color,
      width: width ?? this.width,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      isDashed: isDashed ?? this.isDashed,
    );
  }

  Map<String, dynamic> toJson() => {
    'color': color,
    'width': width,
    'isHighlighter': isHighlighter,
    'isDashed': isDashed,
  };

  factory StrokeStyle.fromJson(Map<String, dynamic> json) => StrokeStyle(
    color: json['color'] as int,
    width: (json['width'] as num).toDouble(),
    isHighlighter: json['isHighlighter'] as bool? ?? false,
    isDashed: json['isDashed'] as bool? ?? false,
  );
}

/// 笔迹对象 (替代原有的 `List<Offset>`)
class Stroke {
  final List<Offset> points;
  final StrokeStyle style;
  final StrokeType type;
  final String? text; // 仅当 type == StrokeType.text 时有效
  final DateTime? createdAt; // 创建时间 (用于激光笔等有时效性的场景)
  final String? groupId; // [New] 用于对象分组

  Stroke({
    required this.points,
    required this.style,
    this.type = StrokeType.freehand,
    this.text,
    this.createdAt,
    this.groupId,
  });
  
  /// 创建一个拷贝
  Stroke copyWith({
    List<Offset>? points,
    StrokeStyle? style,
    StrokeType? type,
    String? text,
    DateTime? createdAt,
    Object? groupId = _sentinel,
  }) {
    return Stroke(
      points: points ?? this.points,
      style: style ?? this.style,
      type: type ?? this.type,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      groupId: identical(groupId, _sentinel) ? this.groupId : (groupId as String?),
    );
  }

  static const _sentinel = Object();

  /// 获取对应的包围盒
  Rect getBounds() {
    if (points.isEmpty) return Rect.zero;

    if (type == StrokeType.text && text != null) {
       final textPainter = TextPainter(
         text: TextSpan(
           text: text,
           style: TextStyle(fontSize: style.width),
         ),
         textDirection: TextDirection.ltr,
       )..layout();
       return Rect.fromLTWH(points.first.dx, points.first.dy, textPainter.width, textPainter.height);
    }
    
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;
    
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    
    final halfWidth = style.width / 2;
    return Rect.fromLTRB(minX - halfWidth, minY - halfWidth, maxX + halfWidth, maxY + halfWidth);
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    'style': style.toJson(),
    'type': type.name,
    'text': text,
    'createdAt': createdAt?.toIso8601String(),
    'groupId': groupId,
  };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    points: (json['points'] as List).map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble())).toList(),
    style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
    type: StrokeType.values.byName(json['type'] as String? ?? 'freehand'),
    text: json['text'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    groupId: json['groupId'] as String?,
  );
}

/// 完整黑板数据容器
class BlackboardData {
  final List<List<Stroke>> pages;
  final String version;
  final DateTime lastModified;

  BlackboardData({
    required this.pages,
    this.version = '1.0',
    required this.lastModified,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'lastModified': lastModified.toIso8601String(),
    'pages': pages.map((page) => page.map((s) => s.toJson()).toList()).toList(),
  };

  factory BlackboardData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> pagesJson = json['pages'] as List? ?? [];
    return BlackboardData(
      version: json['version'] as String? ?? '1.0',
      lastModified: DateTime.parse(json['lastModified'] as String? ?? DateTime.now().toIso8601String()),
      pages: pagesJson.map((page) => (page as List).map((s) => Stroke.fromJson(s as Map<String, dynamic>)).toList()).toList(),
    );
  }
}
