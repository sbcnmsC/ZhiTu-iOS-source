# 知图 · ZhiTu iOS

原生 SwiftUI 学习应用第一版工程骨架。目标平台 iOS 17+。

## 当前包含
- 首页学习概览
- 可交互的演示知识图谱（拖动/缩放/点选）
- 知识点详情与教材来源占位
- 本地示例题库与答题反馈
- 错题列表
- 复习计划
- SwiftData 本地模型与示例数据

## 当前未实现
- PDF 文件导入与可靠的页码/文本锚点解析
- AI 服务端与真实模型调用
- 生产级 FSRS 调度
- OCR、向量检索、云同步、登录
- 代码签名、真机编译和 IPA 导出

界面中的示例教材、题目和掌握度均为演示数据，不应视为真实教材解析结果。

## 在 Xcode 中运行
1. 使用 macOS 上的 Xcode 15 或更新版本。
2. 新建 iOS App，Product Name 设为 `ZhiTu`，Interface 选 SwiftUI，Language 选 Swift。
3. Deployment Target 设为 iOS 17.0 或更高。
4. 将 `ZhiTu/` 目录中的 Swift 文件加入项目（勾选 Copy items if needed，并加入 App target）。
5. 如果 Xcode 自动生成了同名 `ZhiTuApp.swift` 或 `ContentView.swift`，用本目录文件替换，避免重复入口。
6. 选择 iPhone 模拟器运行。

也可在 Xcode 中新建空项目后，将本目录文件按上述方式加入。此交付是源码包，不是已编译或已签名的 IPA。

## 下一阶段
- 用 PDFKit + 文件选择器实现 PDF 导入。
- 建立 FastAPI 服务端：教材解析、检索、题目生成、答案审核。
- 使用成熟 FSRS 实现，并为每个复习状态保存算法版本与作答历史。
