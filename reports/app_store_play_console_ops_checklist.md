# Luma App Store / Play Console 实操清单

适用对象：

- 负责 Apple App Store Connect / Google Play Console 上架操作的人
- 需要逐项勾选、避免漏配证书、推送、测试轨道和商店资料的人

项目信息基线：

- App 名称：Luma
- Android 包名：`ai.luma.app`
- iOS Bundle ID：`ai.luma.app`
- 隐私政策：`legal/privacy_policy.md`
- 服务条款：`legal/terms_of_service.md`
- P1 门禁：`reports/p1_release_readiness.md`

## 1. 本地提交前检查

- [ ] 已确认 `legal/privacy_policy.md` 与 `legal/terms_of_service.md` 不再使用占位支持邮箱 `support@your-domain.com`
- [ ] 已准备 Android 上传签名：`app/android/key.properties` + 对应 keystore 文件
- [ ] 已准备 Firebase Android 配置：`app/android/app/google-services.json`
- [ ] 已准备 Firebase iOS 配置：`app/ios/Runner/GoogleService-Info.plist`
- [ ] 已执行 `make p1-check`
- [ ] 如需本地回归，已执行 `RUN_FLUTTER_CHECKS=1 make p1-check`

## 2. App Store Connect 操作

- [ ] Apple Developer Program 账号可用
- [ ] Apple 后台已创建 `ai.luma.app` 对应 App ID
- [ ] App ID 已开启 Push Notifications capability
- [ ] 已在 Apple Developer 创建 APNs Auth Key 或证书
- [ ] 已将 APNs Key 接入 Firebase 项目
- [ ] 已在 App Store Connect 创建 App 记录
- [ ] 已填写应用名称、副标题、关键词、描述、支持 URL、隐私政策 URL
- [ ] 已填写 App Privacy（Nutrition Labels）
- [ ] 已填写年龄分级 / 内容分级
- [ ] 已填写 Review Notes
- [ ] 如审核需要，已准备演示说明或测试账号
- [ ] 已通过 Xcode Archive 或 Transporter 上传可安装构建
- [ ] 已在 TestFlight 创建 Internal Testing / External Testing 组
- [ ] 已邀请测试用户并确认可安装
- [ ] 已上传 iPhone 截图
- [ ] 如支持 iPad，已上传 iPad 截图
- [ ] 已确认 App Icon、Launch Screen、版本号、Build Number 正确

## 3. Google Play Console 操作

- [ ] Google Play Developer 账号可用
- [ ] 已在 Play Console 创建 `ai.luma.app`
- [ ] 已填写应用名称、简短说明、完整说明
- [ ] 已填写支持邮箱、隐私政策 URL、应用访问说明
- [ ] 已完成 Data safety 表单
- [ ] 已完成 Content rating 问卷
- [ ] 已完成 Ads 声明
- [ ] 已完成目标受众与内容声明
- [ ] 已创建 Closed Testing 轨道
- [ ] 已添加测试邮箱组或 Google Group
- [ ] 已上传 `.aab` 包
- [ ] 已填写发布说明
- [ ] 已上传手机截图
- [ ] 已上传 512x512 图标
- [ ] 已上传 Feature Graphic
- [ ] 如需要，已上传 7 英寸 / 10 英寸平板截图

## 4. Firebase / FCM 真机联调

- [ ] Firebase 项目中已创建 Android App：`ai.luma.app`
- [ ] Firebase 项目中已创建 iOS App：`ai.luma.app`
- [ ] Android 真机首次启动后，`fcm_tokens` 表中可看到 token 入库
- [ ] iOS 真机首次启动后，`fcm_tokens` 表中可看到 token 入库
- [ ] 前台收到推送时，应用内可展示本地通知
- [ ] 后台收到推送时，系统通知中心可见消息
- [ ] 杀进程后再次推送，应用唤起路径符合预期
- [ ] 已记录一次成功推送样本（token、时间、平台、结果）

## 5. 内测分发

- [ ] TestFlight Internal Testing 已可安装并完成一次聊天主流程验证
- [ ] TestFlight External Testing 已准备提交审核
- [ ] Play Closed Testing 已可安装并完成一次聊天主流程验证
- [ ] 已收集至少一轮测试反馈并回填缺陷清单
- [ ] 已确认 P0 缺陷为 0
- [ ] 已确认 P1 缺陷仅保留不阻塞上架项

## 6. 商店素材与提审资料

- [ ] 已产出中英文应用标题与一句话卖点
- [ ] 已产出中英文长描述
- [ ] 已产出版本更新说明
- [ ] 已准备商店截图文案与标注
- [ ] 已准备支持邮箱、官网或落地页 URL
- [ ] 已确认隐私政策 URL 与服务条款 URL 可公网访问
- [ ] 已确认应用内文案、商店文案、隐私文档三者一致

## 7. 提交前最终确认

- [ ] `reports/p1_release_readiness.md` 中 blocker 已全部关闭
- [ ] `reports/store_listing_copy_template.md` 已从模板替换成真实文案
- [ ] 已保留一次成功安装、登录、聊天、设置、推送的证据截图
- [ ] 已确认本次提交版本号与上次版本号不冲突
- [ ] 已确认没有把 secrets、keystore、Firebase 私钥提交到仓库
