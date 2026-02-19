# CLAUDE.md — Luma 项目交接文档

> 每次新会话开始时请先阅读此文件，了解项目当前状态。

## 项目概要

Luma 是一款 **AI 宠物陪伴 app**（Flutter/Dart），核心理念："它在你不在时也活着"。
- 宠物有自主运行的需求系统（孤独、好奇、疲劳、安全感）、双轴情绪模型（效价×唤醒度）、3层记忆
- 对话由 Claude API 驱动，人格通过 system prompt 注入
- 严格遵守 NY GBS Art. 47 和 CA SB 243 合规要求（AI 身份披露、危机干预、审计日志）

## 仓库结构

```
/home/user/luma/
├── app/                    # Flutter 应用
│   ├── lib/
│   │   ├── main.dart       # 入口（ProviderScope + 通知初始化 + WorkManager）
│   │   ├── app.dart        # MaterialApp + M3 主题
│   │   ├── router/
│   │   │   └── app_router.dart    # 状态驱动路由（onboarding → home ↔ chat/settings）
│   │   ├── providers/
│   │   │   └── pet_provider.dart  # Riverpod：所有 Provider 定义 + SecureStorage API key
│   │   ├── core/
│   │   │   ├── engine/            # LifeEngine, NeedSystem, EmotionSystem, BehaviorDecider, TimeSimulator
│   │   │   ├── identity/          # PetIdentity (birth factory), Personality (evolution)
│   │   │   ├── memory/            # MemoryManager (L1/L2/L3)
│   │   │   ├── safety/            # CrisisDetector (2层), AuditLogger, RiskClassifier
│   │   │   └── services/          # BackgroundService (WorkManager), NotificationService (local push)
│   │   ├── data/
│   │   │   ├── models/            # PetState, Emotion, Needs, ChatMessage, DiaryEntry, MemoryEntry
│   │   │   ├── local/             # LumaDatabase (SQLite), PetDao, ChatDao, MemoryDao, SecureStorage
│   │   │   └── remote/            # LlmClient (Anthropic API), AnalyticsClient
│   │   ├── features/
│   │   │   ├── onboarding/        # AiDisclosureScreen, BirthScreen, NameScreen
│   │   │   ├── home/              # HomeScreen, PetAvatar (CustomPainter), StatusBar, DiarySheet
│   │   │   ├── chat/              # ChatScreen, ChatController, CrisisCard (url_launcher), DisclosureReminder
│   │   │   └── settings/          # SettingsScreen
│   │   └── shared/
│   │       └── constants.dart     # LumaConstants（所有阈值和配置）
│   └── pubspec.yaml
├── docs/                   # git submodule → AIPetLuma/docs.git
│   ├── Luma_AI宠物创业报告_更新版.md
│   ├── Luma_MVP代码开发计划_2026-02-18.md
│   └── p0/                # NY/CA 合规映射、危机干预手册、留存实验设计
├── CLAUDE.md               # 本文件
├── .gitmodules
├── Makefile
└── LICENSE (MIT)
```

## 已完成的工作

### Phase A — 核心引擎（commit 078f1eb）
- LifeEngine：60s tick 循环，前台实时更新，后台 TimeSimulator 快进
- NeedSystem：4维需求漂移 + 交互响应
- EmotionSystem：双轴情绪模型，基线衰减 + 需求压力 + 事件冲击
- BehaviorDecider：状态 → 行为翻译（reach out / diary / sleep / withdraw）
- TimeSimulator：离线模拟（30分钟 chunk），生成日记条目
- 3层记忆：L1 工作/L2 短期(30天)/L3 长期(永久)
- 2层危机检测：L1 关键词（同步100%召回）+ L2 LLM分类
- AuditLogger：append-only 审计日志
- ChatController：完整编排（用户输入 → 危机检查 → prompt 组装 → LLM → 状态更新）
- 全部数据模型 + DAO + SQLite schema + LLM client

### Phase B — UI 层（commit 2d63993）
- 入职流程：AI 披露（不可跳过）→ 性格选择 → 命名
- 主页：宠物头像（情绪驱动）、4维需求条、日记底部弹窗
- 聊天：消息气泡、情绪标签、内联危机卡片、定时 AI 披露提醒
- 设置：宠物信息、AI 披露复查、危机资源、隐私说明
- Riverpod 状态管理：所有 Provider 定义 + PetStateNotifier
- AppRouter：生命周期感知（pause/resume 触发引擎 + 会话压缩）

### Phase C — 集成层
- **isInteracting 修正** — LifeEngine 新增 `isUserInteracting` 标志，AppRouter 在进入/退出聊天时切换，tick 现在正确传递
- **url_launcher** — CrisisCard 的 Call/Text 按钮现在能拨打 988 或发短信
- **SecureStorage** — API key 从 flutter_secure_storage 读取（Keychain/EncryptedSharedPrefs），回退到编译时 env
- **BackgroundService** — WorkManager 每15分钟触发后台 tick，loneliness > 0.8 时弹出本地通知
- **NotificationService** — 封装 flutter_local_notifications 初始化 + 权限请求 + 显示
- **PetAvatar 重写** — CustomPainter 绘制呼吸动画球体：径向渐变、唤醒度驱动粒子、效价驱动表情（眼睛/嘴巴）
- **main.dart** — 启动时初始化通知 + 注册后台任务
- **pubspec.yaml** — 新增 url_launcher、flutter_secure_storage

### Phase D — 质量保证（当前 commit）
- **Unit tests** — NeedSystem (9 tests)、EmotionSystem (8 tests)、CrisisDetector (8 tests)、LifeEngine (5 tests) 已在 Phase A 编写
- **Widget tests** — 新增 3 个 widget 测试文件：
  - `onboarding_test.dart` — AI 披露文本/按钮、性格选择、名称验证
  - `crisis_card_test.dart` — L3/L2/L1 卡片渲染
  - `settings_screen_test.dart` — 宠物信息、AI 披露、危机资源
- **LLM 降级策略** — `LlmClient.chat()` 现在 try/catch 包装，API 失败时返回本地手势回复（`*tilts head*` 等），`classifyRisk()` 失败时返回 0（安全默认值，关键词层保底）
- **Settings 页面补全** — 新增 API key 输入界面（TextField + 保存按钮）、重置宠物按钮（确认对话框）
- **DAO 补全** — `PetDao.delete()`、`ChatDao.deleteAllForPet()` 用于重置流程
- **AppRouter 接线** — Settings 的 `onResetPet` 删除数据并回到 onboarding，`onApiKeyChanged` 写入 SecureStorage 并刷新 provider

## 下一步工作（按优先级）

### Phase E — 应该做（上线前）
1. **Firebase 平台配置** — 添加 google-services.json (Android) + GoogleService-Info.plist (iOS)，取消 main.dart 中注释
2. **AnalyticsClient 接入 Mixpanel** — 当前是 stub，需要对接真实 SDK
3. **集成测试** — 端到端 onboarding → chat → settings 完整流程

### Phase F — 可以做（增强体验）
4. **Google Fonts** — 自定义字体
5. **flutter_animate** — 页面转场动画
6. **Supabase** — 云端备份（可选）
7. **i18n** — 中英文支持
8. **深色主题微调** — 当前用 Material3 自动生成，可手动调色

## 关键设计决策（不要改）

1. **情绪驱动行为** — 情绪直接控制回复长度/速度/拒绝，不是装饰标签
2. **append-only 审计** — audit_logs 表永远不删，是合规证据链
3. **关键词层保证100%召回** — L3 关键词触发时直接阻断回复，不等 LLM
4. **本地优先** — 所有数据存设备端 SQLite，不上传云端（MVP 阶段）
5. **PersonalityPreset** — 出生时固定，只通过 PersonalityEvolver 缓慢漂移（0.002/次）
6. **CrisisCard 审计日志在 initState** — 保证每次展示只记录一次（不在 build 中）

## 平台配置待完成

### Android
- `android/app/src/main/AndroidManifest.xml` 需要添加：
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <queries>
    <intent><action android:name="android.intent.action.DIAL"/></intent>
    <intent><action android:name="android.intent.action.SENDTO"/></intent>
  </queries>
  ```

### iOS
- `ios/Runner/Info.plist` 需要添加 `LSApplicationQueriesSchemes`（tel, sms）
- `ios/Runner/GoogleService-Info.plist` — Firebase 配置

## 开发分支

当前分支：`claude/read-docs-submodule-8NTl4`

## 依赖版本

- Flutter SDK: >=3.2.0 <4.0.0
- flutter_riverpod: 2.5.0
- sqflite: 2.3.0
- dio: 5.4.0
- url_launcher: 6.2.0
- flutter_secure_storage: 9.0.0
- workmanager: 0.5.2
- flutter_local_notifications: 17.0.0
- Claude models: haiku-4.5 (默认), sonnet-4.5 (质量)
