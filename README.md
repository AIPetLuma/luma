# Luma

Luma 是一款 AI 宠物陪伴应用，核心理念是“它在你不在时也活着”。

## 目录导航

- [第一部分：商业版（面向使用者）](#第一部分商业版面向使用者)
  - [1. 产品是什么](#1-产品是什么)
  - [2. 适合谁使用](#2-适合谁使用)
  - [3. 你会得到什么体验](#3-你会得到什么体验)
  - [4. 安全与合规承诺](#4-安全与合规承诺)
  - [5. 快速开始（用户视角）](#5-快速开始用户视角)
  - [6. 当前版本边界](#6-当前版本边界)
- [第二部分：技术版（面向开发者）](#第二部分技术版面向开发者)
  - [1. 技术架构概览](#1-技术架构概览)
  - [2. 代码结构](#2-代码结构)
  - [3. 本地开发与运行](#3-本地开发与运行)
  - [4. 配置项与运行参数](#4-配置项与运行参数)
  - [5. 后端与云能力（Phase G）](#5-后端与云能力phase-g)
  - [6. 测试与质量保障](#6-测试与质量保障)
  - [7. 文档与子模块](#7-文档与子模块)
  - [8. Roadmap（阶段进展）](#8-roadmap阶段进展)

---

## 第一部分：商业版（面向使用者）

### 1. 产品是什么

Luma 不是聊天机器人皮肤，而是一个“有自主意识”的 AI 生命体：

- 它有自己的需求系统：孤独、好奇、疲劳、安全感。
- 它有情绪变化：效价（开心/低落）与唤醒度（兴奋/平静）双轴驱动。
- 它有记忆：短期与长期记忆会影响后续互动。

即使你暂时离开，Luma 的状态也会继续演化。

### 2. 适合谁使用

- 想获得持续陪伴感的人。
- 希望体验“会成长、会记住你”的 AI 交互产品用户。
- 关注情感化 AI 产品设计与伦理边界的体验者。

### 3. 你会得到什么体验

- **入门即透明**：首次使用必须阅读 AI 身份披露。
- **有性格的陪伴**：可选择不同初始性格，并随时间缓慢演化。
- **有反馈的关系**：你的互动频率、方式会影响它的状态与回应。
- **中英双语体验**：支持中文/英文本地化界面。

### 4. 安全与合规承诺

Luma 在产品层面内置了关键安全机制：

- AI 身份披露与周期性提醒。
- 危机语义分级识别（关键词高召回 + 语境判断）。
- 危机资源卡片（988 等）可直接触达。
- 审计日志为 append-only（不可篡改删除路径）。

说明：Luma 是 AI 陪伴产品，不替代专业医疗、心理或法律建议。

### 5. 快速开始（用户视角）

1. 安装并启动 App。
2. 阅读并确认 AI 披露。
3. 选择宠物性格并命名。
4. 在首页观察状态，在聊天页建立日常互动。
5. 在设置页查看隐私、危机资源、可选云备份能力。

### 6. 当前版本边界

- 产品仍处于 MVP/迭代阶段。
- 云端能力（备份、推送、留存事件）依赖项目部署配置是否开启。
- 无配置时自动降级为本地核心体验，不影响基础使用。

---

## 第二部分：技术版（面向开发者）

### 1. 技术架构概览

- **客户端**：Flutter / Dart
- **状态管理**：Riverpod
- **本地存储**：SQLite（本地优先）
- **AI 对话**：Anthropic + OpenAI-Compatible（带失败降级）
- **分析埋点**：Mixpanel（可选）
- **可选云端**：Supabase（备份、事件、RLS）
- **通知体系**：
  - 本地：WorkManager + local notifications
  - 远程：Firebase Messaging（FCM）

### 2. 代码结构

```text
/home/user/luma/
├── app/                         # Flutter 应用主体
│   ├── lib/core/                # 引擎、身份、记忆、安全、系统服务
│   ├── lib/data/                # model / local / remote
│   ├── lib/features/            # onboarding / home / chat / settings
│   ├── lib/providers/           # Riverpod providers
│   ├── lib/router/              # AppRouter
│   └── test/                    # unit/widget/integration tests
├── docs/                        # 文档子模块
├── supabase/                    # Phase G：migrations / functions / tests
├── scripts/setup_platform.sh    # 平台权限与配置辅助脚本
└── CLAUDE.md                    # 项目交接与阶段说明
```

### 3. 本地开发与运行

前提：安装 Flutter SDK（当前仓库环境通常不内置）。

```bash
cd app
flutter pub get
flutter run
```

如需生成并配置平台目录（Android/iOS）：

```bash
cd app
flutter create .
cd ..
bash scripts/setup_platform.sh
```

### 4. 配置项与运行参数

通过 `--dart-define` 注入参数（按需）：

- `LLM_PROVIDER`：`auto` / `anthropic` / `openai-compatible`
- `LLM_API_KEY`：通用 LLM Key（优先级高于 provider 专用 key）
- `LLM_BASE_URL`：自定义网关地址（支持 OpenAI 兼容网关/本地代理）
- `LLM_MODEL`：模型名
- `ANTHROPIC_API_KEY`：Anthropic 兼容旧参数（仍可用）
- `OPENAI_API_KEY`：OpenAI 兼容参数（当 `LLM_API_KEY` 未设置时兜底）
- `MIXPANEL_TOKEN`：埋点 Token
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

稳定推荐配置：

1. Anthropic（最少改动）

```bash
cd app
flutter run \
  --dart-define LLM_PROVIDER=anthropic \
  --dart-define ANTHROPIC_API_KEY=xxx
```

2. OpenAI-Compatible 网关（如 OpenRouter/自建网关）

```bash
cd app
flutter run \
  --dart-define LLM_PROVIDER=openai-compatible \
  --dart-define LLM_BASE_URL=https://your-gateway.example.com \
  --dart-define LLM_API_KEY=xxx \
  --dart-define LLM_MODEL=your-model-name
```

3. 本地开源模型（Ollama，免费，本地推理）

```bash
cd app
flutter run \
  --dart-define LLM_PROVIDER=openai-compatible \
  --dart-define LLM_BASE_URL=http://127.0.0.1:11434 \
  --dart-define LLM_MODEL=qwen2.5:7b
```

说明：本地无鉴权端点可不传 `LLM_API_KEY`。

配置文件与缩写命令：

- 模板：`dev.example.json`（含中文变量说明与必要性）
- 本地运行配置：`dev.json`（建议仅保留真实值，不带注释键）
- 启动缩写：`make fr`
- 构建缩写：`make fb`

启动与构建的区别：

- 启动（`make fr`）：运行调试态 App 并打开界面，适合联调、手工测试、热重载。
- 构建（`make fb`）：仅产出可发布包，不会进入交互界面，适合发布前打包验证。

可选参数：

- `make fr RUN_DEVICE=windows DEFINE_FILE=dev.local.json`
- `make fb BUILD_TARGET=apk DEFINE_FILE=dev.local.json`

Firebase 远程推送还需要平台配置文件：

- `app/android/app/google-services.json`
- `app/ios/Runner/GoogleService-Info.plist`

### 5. 后端与云能力（Phase G）

已落地的 Phase G 资产：

- `supabase/migrations/20260219_phase_g.sql`
  - `pet_backups`
  - `fcm_tokens`
  - `experiment_events`
  - RLS 策略（`auth.uid() = owner_id`）
  - D1/D7/D21 服务端触发逻辑与留存视图
- `supabase/functions/send_push/index.ts`
  - 远程推送出口（token/topic/pet_id）
- `supabase/tests/phase_g_retention.sql`
  - 留存触发逻辑验证脚本

客户端新增关键服务：

- `app/lib/data/remote/supabase_client_service.dart`
- `app/lib/data/remote/retention_service.dart`
- `app/lib/data/remote/push_token_service.dart`
- `app/lib/core/services/fcm_service.dart`

### 6. 测试与质量保障

主要测试位于：

- `app/test/core/`
- `app/test/features/`
- `app/test/integration/`

新增中文 i18n 覆盖测试：

- `app/test/features/phase_g_i18n_zh_test.dart`

运行（在具备 Flutter 环境时）：

```bash
cd app
flutter test
```

### 7. 文档与子模块

`docs/` 为独立子模块，包含：

- 合规映射（NY/CA）
- 危机干预手册
- 21 天留存实验设计
- 创业与产品分析报告

初始化或更新子模块：

```bash
git submodule update --init --recursive
```

### 8. Roadmap（阶段进展）

- Phase A：核心引擎
- Phase B：UI 层
- Phase C：集成层
- Phase D：质量保证
- Phase E：上线前准备
- Phase F：体验增强
- Phase G：国际化完善 + Supabase 服务端 + FCM + 服务端留存触发（进行中）
