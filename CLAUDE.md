# MADO — 視野トレーニングアプリ

## プロジェクト概要
UFOVパラダイムに基づく処理速度・注意力トレーニングアプリ。
Phase 1: Task 1（中央識別）のみのMVP。

## 技術スタック
- SwiftUI + Metal (MTKView + CADisplayLink)
- GRDB (WALモード) — ローカルDB
- StoreKit 2 — ¥480買い切りPro
- AdMob — インタースティシャル（テストIDで実装中）
- XcodeGen — プロジェクト生成

## ビルド方法
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && xcodegen generate
xcodebuild -scheme MADO -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0' build
```

## Bundle ID
com.imaiissatsu.mado

## 重要な設計判断
- セッション画面は常にダーク（ThemeColors.Session）
- テーマ切替: @AppStorage("appTheme") → ThemeManager.shared
- 階段法: 2-down/1-up、9リバーサルで収束
- Metal: StimulusRenderer → MTKView、NoiseShader.metal（4×4ブロック）
- AdMob: #if DEBUG でテストID/本番IDを自動切替

## ディレクトリ構造
```
MADO/
├── App/         — MADOApp, ContentView (TabView)
├── Models/      — SessionRecord, TrialRecord (GRDB), UserSettings
├── ViewModels/  — Home/Session/Analytics ViewModel (@Observable)
├── Views/       — Home, Session, Analytics, Settings
├── Services/    — Database, Staircase, StoreKit, AdMob, ATT
├── Metal/       — StimulusRenderer, NoiseShader, StimulusShader
├── Theme/       — ThemeColors, ThemeManager
├── Resources/   — Info.plist, Assets, Localizable.xcstrings
└── Extensions/  — Color+Hex
```
