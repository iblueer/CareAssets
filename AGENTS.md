# CareAssets 项目约定

## 界面预览

- 涉及 AppKit 界面、布局或交互的修改，构建后优先运行 `./script/build_and_run.sh preview`。
- 该命令打开项目内置的独立 `CareAssets Preview` NSWindow；使用它完成视觉检查和点击交互验证。
- 不要为单次需求在 `/private/tmp` 另建预览 App，也不要把状态栏 popover 作为首选预览方式。
- 预览窗口复用正式的 `AssetPanelViewController`、本机配置和真实行情数据。通过预览窗口修改设置会写入本机配置。
- 汇报完成时区分“构建通过”和“预览窗口实际验证通过”；没有看到窗口或没有完成交互检查时必须明确说明。
