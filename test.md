使用技能：`test-engineer`（`test-mode:general-test-strategy-quality-gates`），给你一套可直接执行的“真实可运行”验证路径。

你当前环境先决条件还缺：本机 `flutter`/`dart` 命令不可用，需先安装 Flutter SDK。

**1. 本地基础可运行（不依赖云）**

```bash
cd app
flutter --version
dart --version
flutter create .
cd ..
bash scripts/setup_platform.sh

cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

手工验收最小路径（必须全通过）：

1. Onboarding：AI 披露不可跳过。
2. 选性格 + 命名后进入 Home。
3. Chat 可发送消息，看到披露提醒。
4. Settings 可打开，重置宠物后回到 onboarding。
5. App 前后台切换无崩溃。

**2. 云能力验证（Supabase）**

1. 在 Supabase 执行：`supabase/migrations/20260219_phase_g.sql`
2. 执行留存脚本：`supabase/tests/phase_g_retention.sql`
3. 运行 App（带参数）：

```bash
cd app
flutter run \
  --dart-define SUPABASE_URL=你的URL \
  --dart-define SUPABASE_ANON_KEY=你的KEY
```

4. 在 Settings 点击 Cloud backup，预期成功。
5. 数据库里确认 `pet_backups` 有当前用户数据，且跨用户不可互读（RLS 生效）。

**3. 推送验证（Firebase + FCM）**

1. 放置：

- `app/android/app/google-services.json`
- `app/ios/Runner/GoogleService-Info.plist`

2. 重新 `flutter run`，授予通知权限。
3. 确认 `fcm_tokens` 有 token 入库。
4. 部署 `supabase/functions/send_push/index.ts`，用 `token` 或 `pet_id` 触发推送。
5. 前台收到消息时，App 能展示本地通知。

**4. 通过标准（建议）**

- Gate A：`flutter analyze` + `flutter test` 全通过。
- Gate B：核心用户流程 0 阻断（上述 5 步）。
- Gate C：云备份可用 + RLS 隔离有效。
- Gate D：FCM token 入库且可收到推送。

如果你愿意，我下一步可以按这个清单逐条陪你在当前机器上执行并记录结果。
