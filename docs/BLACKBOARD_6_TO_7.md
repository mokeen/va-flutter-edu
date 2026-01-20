# 画板从 6 → 7 (TODO #7：本地持久化与数据生命周期)

本阶段致力于解决“数据随关随丢”的问题，通过建立可靠的本地存储机制，让黑板应用拥有真正的“记忆”。

---

## 🏗️ 核心目标 (Goals)

1.  **自动存档 (Auto-Save)**：用户绘图时实时或断点将数据持久化，防止崩溃或误关导致丢失。
2.  **多文件管理 (Lesson Library)**：支持保存为 `.vabd` 文件，并能从列表中重新加载。
3.  **数据迁移与兼容 (Versioning)**：确保模型升级时，旧版本的存档能够平滑迁移。
4.  **导出基础 (Export Engine)**：为下一步的高清 PDF 导出提供离线渲染的数据基础。

---

## 📐 技术方案 (Technical Approach)

### 1. 存储引擎选择

- **方案 A (JSON File)**：直接将 `List<Stroke>` 序列化为 JSON 存入应用支持目录 (`ApplicationSupportDirectory`)。
- **方案 B (SQLite/drift)**：适合极大量笔迹的索引与查询。
- **结论**：优先采用 **方案 A**。对于教学课件，单文件内笔迹量通常在 10MB 以内，JSON 序列化足以应对，且开发成本低、文件便携。

### 2. 模型序列化 (`blackboard_model.dart`)

- 为 `Stroke`, `StrokeStyle`, `Offset` 编写 `toJson/fromJson` 方法。
- 引入 `version` 字段标识数据版本。

### 3. 持久化服务 (`BlackboardService`)

- 封装文件 IO 逻辑：`savePage(index, strokes)`, `loadAllPages()`, `deleteLesson()`.
- 使用 `debouncer` 控制磁盘写入频率，避免高频绘图导致 IO 瓶颈。

---

## 📝 Step TODO List

### Step 1: 序列化适配 (Serialization) [DONE]

- [x] 为 `StrokeStyle` 实现 JSON 转换逻辑。
- [x] 为 `Stroke` 类实现 JSON 转换逻辑（处理 `Offset` 序列化）。
- [x] 定义 `BlackboardData` 容器类，包含 `pages`, `version`, `lastModified` 等元数据。

### Step 2: 文件管理层 (IO Implementation) [DONE]

- [x] 封装 `BlackboardRepository` 处理 `path_provider` 的路径获取及文件读写。
- [x] 实现基本的持久化机制。

### Step 3: 控制器集成 (Controller Integration) [DONE]

- [x] 在 `BlackboardController` 中注入 `Repository`。
- [x] 实现 `autoSave` 逻辑。
- [x] 实现应用启动时的 `initialLoad` 逻辑。

### Step 4: UI 管理界面 (Library UI) [DONE]

- [x] 设计一个简易的“我的课件”列表页或对话框。
- [x] 实现“新建/删除”功能。

---

## 💡 关键代码预览

### JSON 结构预览

```json
{
  "version": "1.0",
  "lastModified": "2026-01-20T...",
  "pages": [
    {
      "index": 0,
      "strokes": [
        {
          "type": "freehand",
          "points": [{"dx": 10.0, "dy": 20.0}, ...],
          "style": { "color": 4294967295, "width": 2.0 }
        }
      ]
    }
  ]
}
```

## ✅ 最终实现 (Final Implementation)

### 1. 序列化实现

在 `blackboard_model.dart` 中为 `StrokeStyle` 和 `Stroke` 添加了 `toJson` 和 `fromJson`。使用了 `Offset` 的 `{dx: ..., dy: ...}` 结构保证 JSON 兼容性。

### 2. Repository 模式

新增 `BlackboardRepository` 类，负责：

- 自动创建并定位 `ApplicationSupportDirectory` 下的存储目录。
- 处理 `.vabd` 文件的读写与删除。
- 扫描目录生成课件列表。

### 3. 控制器逻辑

- **初始化加载**：启动时自动尝试加载名为 `default` 的课件。
- **自动保存**：在 `endStroke`, `undo`, `redo` 等操作后触发 2 秒延迟的 `saveLesson`。
- **状态同步**：保存时将扁平化的笔迹数据重新映射到对应的页面容器中。

### 4. 课件管理 UI

在 `BlackboardScreen` 中集成了一个基于 `AlertDialog` 的管理界面，支持实时刷新列表、新建与删除。
