# Flutter Test Suite Overview / 测试总览

## 1) Scope Matrix / 功能-文件矩阵

| File | Main Coverage (EN) | 主要覆盖（中文） |
|---|---|---|
| `app/test/core/need_system_test.dart` | Need evolution over time, interaction effects, threshold helpers | 需求值随时间变化、交互影响、阈值判断 |
| `app/test/core/emotion_system_test.dart` | Emotion drift, event reaction, label mapping, token tuning | 情绪漂移、事件响应、标签映射、回复长度策略 |
| `app/test/core/life_engine_test.dart` | Offline simulation, reunion mood, diary generation, cap logic | 离线模拟、重逢情绪、日记生成、上限保护 |
| `app/test/core/crisis_detector_test.dart` | Risk level detection (L0-L3), EN/CN keywords, resource templates | 风险分级检测（L0-L3）、中英关键词、资源文案 |
| `app/test/features/crisis_card_test.dart` | Crisis card rendering by risk level and emergency affordance | 不同风险等级危机卡片渲染与紧急动作 |
| `app/test/features/onboarding_test.dart` | Disclosure gate, birth selection gating, naming validation | 披露页门禁、性格选择门禁、命名输入校验 |
| `app/test/features/phase_g_i18n_zh_test.dart` | Phase G Chinese locale wiring across key screens | Phase G 关键页面中文本地化接线 |
| `app/test/features/settings_screen_test.dart` | Settings compliance sections and crisis resource visibility | 设置页合规模块与危机资源可见性 |
| `app/test/integration/app_flow_test.dart` | End-to-end flow: onboarding → home → chat → settings | 端到端流程：引导 → 首页 → 聊天 → 设置 |
| `app/test/widget_test.dart` | App boot smoke and initial visible phase | 应用启动冒烟与初始可见阶段 |

## 2) Rationality Check / 合理性检查

### Reasonable / 合理
- Layering is clear: core logic, feature widgets, and integration flow are separated.
- 分层清晰：核心逻辑、页面组件、端到端流程分离。
- High-risk safety paths are covered (crisis detection + crisis card).
- 高风险安全路径有覆盖（风险检测 + 危机卡片）。
- i18n regression checks exist for zh locale on key screens.
- 关键页面已有中文本地化回归检查。

### Previously Unreasonable and Fixed / 已修复的不合理点
- Weak smoke test in `widget_test.dart` only checked root type.
- `widget_test.dart` 过去只检查根组件类型，验证力度不足，已加强为首屏可见阶段检查。
- Scroll-dependent assertions were brittle in onboarding/integration/settings tests.
- onboarding/integration/settings 中依赖滚动的断言脆弱，已改为先滚动到目标元素再断言/点击。
- Animation-related timer instability under widget test binding.
- Widget 测试环境下动画计时器导致不稳定，已通过测试环境禁用动画路径规避。

## 3) Current Status / 当前状态

- `flutter test`: passing (full suite).
- `flutter test`：全量通过。
- `flutter analyze`: no blocking error; warnings/info remain for cleanup.
- `flutter analyze`：无阻塞错误；仍有 warning/info 可继续清理。
