import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:va_edu/src/features/blackboard/domain/blackboard_model.dart';

/// 处理黑板数据持久化的仓库
class BlackboardRepository {
  /// 获取存档目录
  Future<Directory> get _storageDir async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/blackboards');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 保存黑板数据
  Future<void> save(String fileName, BlackboardData data) async {
    final dir = await _storageDir;
    final file = File('${dir.path}/$fileName.vabd');
    final jsonStr = jsonEncode(data.toJson());
    await file.writeAsString(jsonStr);
  }

  /// 加载黑板数据
  Future<BlackboardData?> load(String fileName) async {
    final dir = await _storageDir;
    final file = File('${dir.path}/$fileName.vabd');
    if (!await file.exists()) return null;
    
    try {
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return BlackboardData.fromJson(json);
    } catch (e) {
      // 解析失败，可能版本不兼容或损坏
      return null;
    }
  }

  /// 获取所有课件列表
  Future<List<String>> listLessons() async {
    final dir = await _storageDir;
    if (!await dir.exists()) return [];
    
    final List<String> lessons = [];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.vabd')) {
        final name = entity.path.split('/').last.replaceAll('.vabd', '');
        lessons.add(name);
      }
    }
    return lessons;
  }

  /// 删除课件
  Future<void> delete(String fileName) async {
    final dir = await _storageDir;
    final file = File('${dir.path}/$fileName.vabd');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
