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
├── scripts/
│   └── setup_platform.sh   # Android/iOS 权限配置脚本
├── CLAUDE.md               # 本文件
├── .gitmodules
├── Makefile                 # 新增 `make setup` 目标
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

### Phase D — 质量保证
- **Unit tests** — NeedSystem (9 tests)、EmotionSystem (8 tests)、CrisisDetector (8 tests)、LifeEngine (5 tests) 已在 Phase A 编写
- **Widget tests** — 新增 3 个 widget 测试文件：
  - `onboarding_test.dart` — AI 披露文本/按钮、性格选择、名称验证
  - `crisis_card_test.dart` — L3/L2/L1 卡片渲染
  - `settings_screen_test.dart` — 宠物信息、AI 披露、危机资源
- **LLM 降级策略** — `LlmClient.chat()` 现在 try/catch 包装，API 失败时返回本地手势回复（`*tilts head*` 等），`classifyRisk()` 失败时返回 0（安全默认值，关键词层保底）
- **Settings 页面补全** — 新增 API key 输入界面（TextField + 保存按钮）、重置宠物按钮（确认对话框）
- **DAO 补全** — `PetDao.delete()`、`ChatDao.deleteAllForPet()` 用于重置流程
- **AppRouter 接线** — Settings 的 `onResetPet` 删除数据并回到 onboarding，`onApiKeyChanged` 写入 SecureStorage 并刷新 provider

### Phase E — 上线前准备（当前 commit）
- **Firebase 初始化** — `firebase_core` 加入依赖，`main.dart` 启动时 try/catch 初始化（无配置文件时 graceful fallback）
- **Mixpanel 接入** — `AnalyticsClient` 从 stub 升级为 `mixpanel_flutter` 真实封装（singleton，token 通过 `--dart-define MIXPANEL_TOKEN` 注入，空 token 自动降级 stub 模式）
- **10 个埋点完整接线**：
  - `signup_completed` — 宠物出生后触发
  - `session_started` / `session_ended` — App 生命周期 resume/pause 自动追踪（含时长）
  - `ai_disclosure_shown` — onboarding + 聊天中每 3 小时提醒
  - `risk_signal_detected` / `risk_level_assigned` — 危机检测触发时
  - `crisis_resource_shown` — L1/L2/L3 资源卡展示时
  - D1/D7/D21 留存事件已定义，等服务端对接
- **集成测试** — `test/integration/app_flow_test.dart`，8 个测试覆盖完整流程：
  - 完整 onboarding 流转（disclosure → birth → name → home）
  - home → chat → home 转场 + 披露提醒验证
  - home → settings → home 转场 + 合规内容验证
  - settings reset → 回到 onboarding
  - 聊天输入栏/发送按钮验证
  - 合规内容验证（AI 披露、危机资源、988/741741）
- **平台配置脚本** — `scripts/setup_platform.sh` + Makefile `make setup` 一键生成并配置 Android/iOS 权限
- **pubspec.yaml** — 新增 `firebase_core: ^2.25.0`

## 下一步工作（按优先级）

### Phase F — 可以做（增强体验）
1. **Google Fonts** — 自定义字体
2. **flutter_animate** — 页面转场动画
3. **Supabase** — 云端备份（可选）
4. **i18n** — 中英文支持
5. **深色主题微调** — 当前用 Material3 自动生成，可手动调色

## 关键设计决策（不要改）

1. **情绪驱动行为** — 情绪直接控制回复长度/速度/拒绝，不是装饰标签
2. **append-only 审计** — audit_logs 表永远不删，是合规证据链
3. **关键词层保证100%召回** — L3 关键词触发时直接阻断回复，不等 LLM
4. **本地优先** — 所有数据存设备端 SQLite，不上传云端（MVP 阶段）
5. **PersonalityPreset** — 出生时固定，只通过 PersonalityEvolver 缓慢漂移（0.002/次）
6. **CrisisCard 审计日志在 initState** — 保证每次展示只记录一次（不在 build 中）

## 平台配置（`make setup` 一键完成）

运行 `make setup` 会执行 `flutter create .` 生成平台文件，然后自动配置权限。

### 仍需手动添加
- `android/app/google-services.json` — Firebase Console 下载
- `ios/Runner/GoogleService-Info.plist` — Firebase Console 下载
- Mixpanel token — 构建时传入 `--dart-define MIXPANEL_TOKEN=xxx`

## 开发分支

当前分支：`claude/read-docs-submodule-8NTl4`

## 依赖版本

- Flutter SDK: >=3.2.0 <4.0.0
- flutter_riverpod: 2.5.0
- sqflite: 2.3.0
- dio: 5.4.0
- firebase_core: 2.25.0
- firebase_messaging: 14.7.0
- mixpanel_flutter: 2.2.0
- url_launcher: 6.2.0
- flutter_secure_storage: 9.0.0
- workmanager: 0.5.2
- flutter_local_notifications: 17.0.0
- Claude models: haiku-4.5 (默认), sonnet-4.5 (质量)
