# Luma P1 发布就绪门禁

## Request Snapshot

- 选择模式：`test-mode:general-test-strategy-quality-gates`
- 系统范围：Flutter 客户端、Supabase 备份与留存、Firebase/FCM 推送、App Store / Play 发布流程
- 当前约束：
  - 本仓库内无法直接完成 App Store Connect / Play Console 后台点击操作
  - 真机推送依赖 `google-services.json`、`GoogleService-Info.plist` 和 Firebase 控制台配置
  - WSL 代理环境下 `flutter test` 需要临时清空大小写代理变量

## Risk and Coverage Plan

风险分级：

- Critical：首次启动崩溃、无法完成 onboarding、聊天发送失败无提示、商店包名/签名配置错误
- High：推送 token 不入库、前后台推送不达、设置页重置异常、隐私与条款入口缺失
- Medium：中英文切换异常、测试轨道可安装但核心流程有视觉或交互瑕疵
- Low：商店文案细节、截图标注优化、非阻塞日志噪音

覆盖策略：

- 单元/Widget：`onboarding`、`chat warning`、`settings`、危机卡片、中文 i18n
- 集成回归：`onboarding -> home -> chat -> settings`
- 手工真机：FCM 前台/后台/冷启动、Android 上传签名、iOS capability
- 发布资料：隐私政策、条款、支持邮箱、商店文案、截图矩阵

## Test Design

优先场景：

1. 新用户首次进入应用，完成 disclosure、出生设定、命名并进入 Home
2. 已创建宠物后进入 Chat，发送普通消息与失败消息，前端可给出明确反馈
3. Settings 页面可查看合规信息并执行 reset 返回 onboarding
4. Firebase 已配置时，首次启动产生 token 并写入 `fcm_tokens`
5. TestFlight / Closed Testing 安装包可正常启动、聊天、设置、退出重进

关键验证用例：

- Given 新安装应用，When 完成 onboarding，Then 能进入 Home 且不崩溃
- Given 聊天接口返回 4xx/5xx，When 用户发送消息，Then 前端出现含状态码的错误提示
- Given LLM 超时，When 用户发送消息，Then 前端出现超时提示
- Given 进入 Settings，When 查看合规区域，Then AI disclosure / crisis resources / data privacy 均可见
- Given Firebase 完整配置，When 真机启动应用，Then `fcm_tokens` 入库且前台消息可见

## Quantitative Quality Gate Table

| Gate | Threshold |
| --- | --- |
| `flutter analyze` | 0 issues |
| 核心回归集 | 100% 通过 |
| P0 缺陷 | 0 |
| P1 阻塞缺陷 | 0 |
| 推送链路 | Android+iOS 各至少 1 次前台、1 次后台成功 |
| 内测安装 | TestFlight / Closed Testing 各至少 1 台真机可安装 |
| 商店资料 | 标题、描述、隐私政策、支持邮箱、截图矩阵全部齐备 |

## Environment and Test Data Governance

- 本地开发：
  - 使用 `make fr` / `make fb`
  - `flutter test` 在 WSL 下需要清空代理变量
- 测试数据：
  - 不在仓库提交任何真实 API key、keystore、Firebase 私钥
  - 商店测试使用非敏感测试账号或匿名会话
- 环境分层：
  - Repo 内验证：静态检查、Widget/Integration 测试、文件完整性检查
  - 外部验证：Firebase 控制台、真机推送、商店后台分发与提审

## Quality Gates

入口条件：

- `reports/app_store_play_console_ops_checklist.md` 已建立
- `reports/store_listing_copy_template.md` 已填写初稿
- 法务文档不再使用占位支持邮箱

退出条件：

- `make p1-check` 无 blocker
- `RUN_FLUTTER_CHECKS=1 make p1-check` 通过
- 真机推送验证完成并留档
- TestFlight / Closed Testing 均完成至少一轮安装验证

Release blocker 定义：

- 包名、签名、Bundle ID 配置错误
- 核心回归失败
- 法务文档仍带占位信息
- 商店后台无法安装测试包
- 推送作为承诺功能但链路未完成验证

## Execution and Ownership

执行顺序：

1. Repo 内门禁：`make p1-check`
2. 自动化质量门禁：`RUN_FLUTTER_CHECKS=1 make p1-check`
3. Firebase / FCM 真机联调
4. TestFlight / Play Closed Testing 分发
5. 商店资料上传与提审

证据产物：

- `reports/store_release_checklist_plan_2026-03-06.md`
- `reports/app_store_play_console_ops_checklist.md`
- `reports/store_listing_copy_template.md`
- 真机截图、推送成功截图、商店后台截图

## Routing Decisions

- App Store / Play 政策最终解释：超出仓库自动化范围，需要人工审核
- 最终法务审阅：超出工程门禁范围，需要人工或法律顾问确认
- 真机证书与商店账号配置：超出代码仓库范围，需要账号持有者执行

## Next Actions

1. 先把 `legal/privacy_policy.md` 与 `legal/terms_of_service.md` 的支持邮箱换成真实值
2. 准备 `app/android/key.properties` 和 Android upload keystore
3. 放入 `app/android/app/google-services.json` 与 `app/ios/Runner/GoogleService-Info.plist`
4. 执行 `RUN_FLUTTER_CHECKS=1 make p1-check`
5. 开始 TestFlight / Play Closed Testing 首轮内测
