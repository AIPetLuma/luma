# Luma App (Flutter)

Luma 是一款 AI 宠物陪伴应用，主要代码位于 `app/`，构建与运行通过 Flutter 完成。

## 快速开始

```bash
cd app
flutter pub get
flutter run
```

如果缺少平台目录（android/ios），先生成：

```bash
cd app
flutter create .
cd ..
bash scripts/setup_platform.sh
```

## 配置与运行参数

使用 `--dart-define` 注入运行时参数，建议使用配置文件：

```bash
make fr DEFINE_FILE=dev.json
```

常用参数（示例）：

- `LLM_PROVIDER`：`auto` / `anthropic` / `openai-compatible`
- `LLM_API_KEY`
- `LLM_BASE_URL`
- `LLM_MODEL`
- `MIXPANEL_TOKEN`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 测试与质量

```bash
cd app
flutter test
```

WSL 代理环境下若测试无法连接 VM Service，可临时清空代理变量：

```bash
cd app
HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= NO_PROXY=127.0.0.1,localhost,::1 \
http_proxy= https_proxy= all_proxy= no_proxy=127.0.0.1,localhost,::1 \
flutter test test/integration/app_flow_test.dart \
  test/features/onboarding_test.dart \
  test/features/settings_screen_test.dart \
  test/features/chat_warning_test.dart
```

## 发布就绪检查

仓库根目录提供发布就绪检查：

```bash
make p1-check
RUN_FLUTTER_CHECKS=1 make p1-check
```

## 发布签名与推送配置

- Android 签名：`app/android/key.properties`
- Firebase Android：`app/android/app/google-services.json`
- Firebase iOS：`app/ios/Runner/GoogleService-Info.plist`

> 提醒：不要把 keystore、Firebase 私钥或任何 API key 提交到仓库。
