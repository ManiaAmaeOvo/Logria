# 贡献指南

[English](CONTRIBUTING.md) · [中文首页](README.zh-CN.md)

欢迎 Issues 和 Pull Requests。请说明界面、语言、Android 版本、复现步骤及预期／实际行为，截图和示例使用虚构日志。

新功能默认保持离线；数据库变更必须保留已有记录，饮食文本可独立保存，未知测量不能当作零。
UI 改动同时更新两份 ARB 并重新生成本地化文件。用户文档和更新日志也应同步中英文。
应用直接打包两份用户手册和两份 Changelog，不要维护与仓库脱节的文案副本。

提交前运行：

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

不要提交个人数据库、导出的健康日志、签名密钥、机器路径或凭据。
为轮次推进、营养汇总、日期选择、迁移、复制和本地文档语言适配增加针对性测试。
贡献代码按 MIT 许可授权。
