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
│   │   ├── main.dart       # 入口（ProviderScope 包裹）
│   │   ├── app.dart        # MaterialApp + M3 主题
│   │   ├── router/
│   │   │   └── app_router.dart    # 状态驱动路由（onboarding → home ↔ chat/settings）
│   │   ├── providers/
│   │   │   └── pet_provider.dart  # Riverpod：所有 Provider 定义
│   │   ├── core/
│   │   │   ├── engine/            # LifeEngine, NeedSystem, EmotionSystem, BehaviorDecider, TimeSimulator
│   │   │   ├── identity/          # PetIdentity (birth factory), Personality (evolution)
│   │   │   ├── memory/            # MemoryManager (L1/L2/L3)
│   │   │   └── safety/            # CrisisDetector (2层), AuditLogger, RiskClassifier
│   │   ├── data/
│   │   │   ├── models/            # PetState, Emotion, Needs, ChatMessage, DiaryEntry, MemoryEntry
│   │   │   ├── local/             # LumaDatabase (SQLite), PetDao, ChatDao, MemoryDao
│   │   │   └── remote/            # LlmClient (Anthropic API), AnalyticsClient
│   │   ├── features/
│   │   │   ├── onboarding/        # AiDisclosureScreen, BirthScreen, NameScreen
│   │   │   ├── home/              # HomeScreen, PetAvatar, StatusBar, DiarySheet
│   │   │   ├── chat/              # ChatScreen, ChatController, CrisisCard, DisclosureReminder
│   │   │   └── settings/          # SettingsScreen
│   │   └── shared/
│   │       └── constants.dart     # LumaConstants（所有阈值和配置）
│   └── pubspec.yaml
├── docs/                   # git submodule → AIPetLuma/docs.git
│   ├── Luma_AI宠物创业报告_更新版.md
│   ├── Luma_MVP代码开发计划_2026-02-18.md
│   └── p0/                # NY/CA 合规映射、危机干预手册、留存实验设计
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
- 主页：宠物头像（情绪驱动颜色/大小/emoji）、4维需求条、日记底部弹窗
- 聊天：消息气泡、情绪标签、内联危机卡片、定时 AI 披露提醒
- 设置：宠物信息、AI 披露复查、危机资源、隐私说明
- Riverpod 状态管理：所有 Provider 定义 + PetStateNotifier
- AppRouter：生命周期感知（pause/resume 触发引擎 + 会话压缩）

## 下一步工作（按优先级）

### Phase C — 必须做（MVP 可运行）
1. **NeedSystem.tick() 的 isInteracting 参数** — 当前 provider 只传了 false，需要在 ChatController 交互时标记
2. **WorkManager 后台任务** — 离线时 push 通知（loneliness > 0.8 时触发）
3. **Firebase 初始化** — main.dart 中需要 `Firebase.initializeApp()`
4. **API key 安全存储** — 当前用 `String.fromEnvironment`，应改为 `flutter_secure_storage` 或 `.env`
5. **Rive/Lottie 动画** — 替换 PetAvatar 中的 emoji placeholder
6. **url_launcher** — CrisisCard 中的 call/text 按钮目前是空 onPressed

### Phase D — 应该做（质量保证）
7. **Unit tests** — NeedSystem, EmotionSystem, CrisisDetector, TimeSimulator
8. **Widget tests** — 关键流程：onboarding 完整流程、危机卡片显示
9. **AnalyticsClient** — Mixpanel 集成
10. **错误处理** — LLM 调用失败时的降级策略

### Phase E — 可以做（增强体验）
11. **Google Fonts** — 自定义字体
12. **flutter_animate** — 页面转场动画
13. **Supabase** — 云端备份（可选）
14. **i18n** — 中英文支持

## 关键设计决策（不要改）

1. **情绪驱动行为** — 情绪直接控制回复长度/速度/拒绝，不是装饰标签
2. **append-only 审计** — audit_logs 表永远不删，是合规证据链
3. **关键词层保证100%召回** — L3 关键词触发时直接阻断回复，不等 LLM
4. **本地优先** — 所有数据存设备端 SQLite，不上传云端（MVP 阶段）
5. **PersonalityPreset** — 出生时固定，只通过 PersonalityEvolver 缓慢漂移（0.002/次）

## 开发分支

当前分支：`claude/read-docs-submodule-8NTl4`

## 依赖版本

- Flutter SDK: >=3.2.0 <4.0.0
- flutter_riverpod: 2.5.0
- sqflite: 2.3.0
- dio: 5.4.0
- Claude models: haiku-4.5 (默认), sonnet-4.5 (质量)
