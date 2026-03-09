# Luma 商店上架清单与开发计划（2026-03-06）

## 目标

- 在满足 Apple App Store 与 Google Play 基线要求的前提下，完成可提审版本。
- 优先解决提审阻塞项（P0），再处理上线质量项（P1）。

## P0 清单（提审阻塞）

1. [x] 替换模板包名（Android `applicationId/namespace`、iOS `PRODUCT_BUNDLE_IDENTIFIER`）。
2. [x] Android release 不再使用 debug 签名，改为正式签名配置。
3. [x] Android 主清单补齐 `INTERNET` 权限（release 可联网）。
4. [x] iOS 推送能力基础配置（entitlements / 背景模式）落地。
5. [x] 输出隐私政策与服务条款文档并在 README 可索引。
6. [ ] 真实证书与商店后台配置（开发者账号、证书、App 信息）完成。

## P1 清单（上线质量）

1. [x] `flutter analyze` 警告收敛。
2. [x] 核心路径回归（onboarding/home/chat/settings）。
3. [ ] 推送链路真机联调（前台/后台）。
4. [ ] 内测分发（TestFlight / Play Closed Testing）。
5. [ ] 提审素材与商店文案完备。

## 15 个工作日计划

1. D1-D3：发布工程底座（包名、签名、联网权限、可构建产物）。
2. D4-D6：推送能力与平台配置（Firebase 文件、iOS capability）。
3. D7-D9：合规资产（隐私政策、条款、支持联系方式、商店表单）。
4. D10-D12：质量与预发（告警收敛、回归、灰度）。
5. D13-D15：提审与反馈闭环（商店提交、修复、复审）。

## 执行日志

- 2026-03-06：
  - [x] 文档创建。
  - [x] Android 包名改造：`com.example.luma` -> `ai.luma.app`。
  - [x] iOS Bundle ID 改造：`com.example.luma` -> `ai.luma.app`。
  - [x] Android release 签名从 debug key 切换为 release 签名配置（需 key.properties）。
  - [x] Android 主清单新增 `INTERNET` 权限。
  - [x] iOS 新增 `Runner.entitlements` 与 `UIBackgroundModes(remote-notification)`。
  - [x] Android 接入 `google-services` 条件启用（有 `google-services.json` 才应用插件）。
  - [x] 新增隐私政策/服务条款草案并接入 README 入口。
  - [x] `flutter analyze` 告警清零（当前 0 issues）。
  - [x] 核心回归测试通过：
    - `test/integration/app_flow_test.dart`
    - `test/features/onboarding_test.dart`
    - `test/features/settings_screen_test.dart`
    - `test/features/chat_warning_test.dart`
  - [x] 修复 `chat_warning_test` 定位脆弱问题：
    - 新增 `chat_input_field` / `chat_send_button` key。
    - 改为 key 定位，避免 Flutter 版本差异导致 `find.byType(TextField)` 失败。
  - [ ] 外部控制台工作（Apple Team/证书、Play Console、Firebase 项目、商店资料）待执行。
  - [ ] 推送链路真机联调待执行（依赖 Firebase 平台配置与真机环境）。
- 2026-03-07：
  - [x] 新增商店后台逐项勾选清单：`reports/app_store_play_console_ops_checklist.md`
  - [x] 新增 P1 发布就绪门禁：`reports/p1_release_readiness.md`
  - [x] 新增商店文案模板：`reports/store_listing_copy_template.md`
  - [x] 新增本地发布检查脚本：`scripts/check_release_readiness.sh`
  - [x] 新增命令：`make p1-check`
  - [x] 执行 `RUN_FLUTTER_CHECKS=1 bash scripts/check_release_readiness.sh`
  - [x] `flutter analyze` 通过
  - [x] 核心回归通过（`app_flow` / `onboarding` / `settings` / `chat_warning`）
  - [ ] 当前 blocker：法务文档仍使用占位支持邮箱 `support@your-domain.com`
  - [ ] 当前 warning：缺少 `app/android/key.properties`
  - [ ] 当前 warning：缺少 `app/android/app/google-services.json`
  - [ ] 当前 warning：缺少 `app/ios/Runner/GoogleService-Info.plist`

## 当前阻塞与下一优先级

1. 法务文档支持邮箱仍是占位值，当前不能视为提审可用。
2. 外部平台配置未完成（P0-6），无法进入真实提审流程。
3. 推送联调依赖 `google-services.json` / `GoogleService-Info.plist` 与真机（P1-3）。
4. 内测分发依赖签名证书、商店后台应用与版本轨道（P1-4）。

## 本地回归命令（WSL 代理环境）

```bash
cd app
HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= NO_PROXY=127.0.0.1,localhost,::1 \
http_proxy= https_proxy= all_proxy= no_proxy=127.0.0.1,localhost,::1 \
flutter test test/integration/app_flow_test.dart \
  test/features/onboarding_test.dart \
  test/features/settings_screen_test.dart \
  test/features/chat_warning_test.dart
```

## P1 检查命令

```bash
make p1-check
RUN_FLUTTER_CHECKS=1 make p1-check
```
