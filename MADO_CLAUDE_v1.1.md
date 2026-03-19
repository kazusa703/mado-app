# CLAUDE.md — MADO（マド）v1.1

## アプリ概要

画面中央のターゲット識別と周辺視野の位置特定を同時に行う、処理速度・注意力トレーニングアプリ。
「窓（MADO）を広げる」メタファーで、視野の広さ＝注意の広さを直感的に表現。
1セッション約8〜10分、週3〜5回の使用を想定。

## 絶対ルール（全Phaseに適用）

### 表現に関する禁止事項
- ユーザー向けテキストに科学的効果の断言を含めない
- 「研究で○○%改善」「認知症リスクが下がる」「事故が減る」等の示唆を禁止
- 論文名・研究者名・大学名・ACTIVE試験等をアプリ内に表示しない
- 「科学の裏側」ページを作らない
- あくまで「注意力を使うゲーム」「視野を広げるゲーム」として表現する

### UI/UXルール（今井式共通ルール準拠）
- chevron手動追加しない / push=階層閲覧・sheet=自己完結タスク
- Cancel時は確認ダイアログ必須
- スワイプバックをカスタムジェスチャーで殺さない
- タブ3〜5個 / 全タップ要素60×60pt推奨
- 破壊的アクション → .confirmationDialog + Button(role: .destructive)
- Dynamic Type対応・サイズ直指定禁止（本文≧16pt、見出し≧20pt）
- SF Symbolsアイコン統一 / 日英レイアウトテスト
- テキスト色.primary/.secondary / Color.black/white禁止
- セマンティックカラー背景 / 色だけで情報伝えない
- タップフィードバック scaleEffect(0.95) + haptic ≤ 0.2s
- ReduceMotion時アニメ → フェード置換
- IAP「購入復元」必須 / ペイウォールに価格・規約明記
- レビューリクエストはセッション完了後のみ
- 権限リクエストは必要な瞬間のみ

### コントラスト・アクセシビリティ
- 両テーマでWCAG AAA 7:1目標
- タップターゲット間16px最小スペース

## テーマシステム

### 基本方針
- **デフォルト: ライトテーマ（白ベース）**
- 設定画面から「ダークテーマ」に切り替え可能
- @AppStorage("appTheme") で永続化（"system" / "light" / "dark"）
- **セッション画面は常にダーク**（テーマ設定に関わらず。刺激提示の精度とコントラストのため）

### カラートークン定義

```swift
struct ThemeColors {
    // ────────────────────────────────────────
    // LIGHT THEME（デフォルト）
    // ────────────────────────────────────────
    struct Light {
        static let bg            = Color(hex: "FFFFFF")
        static let bgCard        = Color(hex: "FFFFFF")
        static let bgSurface     = Color(hex: "F5F5F7")
        static let bgGrouped     = Color(hex: "F2F2F7")

        static let accent        = Color(hex: "4A90B8")  // 落ち着いたブルー
        static let accentSoft    = Color(hex: "E4F0F8")
        static let accentDark    = Color(hex: "2E6B8E")

        static let teal          = Color(hex: "34C759")
        static let tealSoft      = Color(hex: "E4F5EB")
        static let gold          = Color(hex: "D4A853")
        static let goldSoft      = Color(hex: "FFF8E8")

        static let text          = Color(hex: "1C1C1E")
        static let textSub       = Color(hex: "6E6E73")
        static let textMuted     = Color(hex: "AEAEB2")

        static let border        = Color(hex: "E5E5EA")
        static let cardShadow    = Color.black.opacity(0.06)

        static let tabBarBg      = Color(hex: "FFFFFF").opacity(0.92)

        // 窓メタファー（ライト版）
        static let windowInner   = Color(hex: "4A90B8")
        static let windowFrame   = Color(hex: "D1D5DB")
        static let windowFrost   = Color(hex: "E0E7EF").opacity(0.7)
    }

    // ────────────────────────────────────────
    // DARK THEME（設定で切替）
    // ────────────────────────────────────────
    struct Dark {
        static let bg            = Color(hex: "0B0E18")
        static let bgCard        = Color(hex: "131829")
        static let bgSurface     = Color(hex: "1A2035")
        static let bgGrouped     = Color(hex: "101420")

        static let accent        = Color(hex: "4CA6E8")
        static let accentSoft    = Color(hex: "4CA6E8").opacity(0.12)
        static let accentDark    = Color(hex: "6CBAF0")

        static let teal          = Color(hex: "34D4B0")
        static let tealSoft      = Color(hex: "34D4B0").opacity(0.12)
        static let gold          = Color(hex: "E8C84C")
        static let goldSoft      = Color(hex: "E8C84C").opacity(0.12)

        static let text          = Color(hex: "E8ECF4")
        static let textSub       = Color(hex: "8892A8")
        static let textMuted     = Color(hex: "4A5268")

        static let border        = Color(hex: "1E2640")
        static let cardShadow    = Color.clear

        static let tabBarBg      = Color(hex: "0B0E18").opacity(0.94)

        // 窓メタファー（ダーク版: グロー表現）
        static let windowInner   = Color(hex: "4CA6E8")
        static let windowFrame   = Color(hex: "1E2640")
        static let windowFrost   = Color(hex: "0B0E18").opacity(0.9)
    }

    // ────────────────────────────────────────
    // SESSION（常にダーク・テーマ設定に依存しない）
    // ────────────────────────────────────────
    struct Session {
        static let bg            = Color(hex: "06080E")
        static let surface       = Color(hex: "0D1020")
        static let border        = Color(hex: "1A1E2E")
        static let text          = Color.white.opacity(0.85)
        static let textMuted     = Color.white.opacity(0.35)
        static let fixation      = Color(hex: "4CA6E8").opacity(0.6)
        static let maskBlock     = Color.white.opacity(0.15)
    }
}
```

### UIデザイン詳細

**ライトテーマ（デフォルト）:**
- 白背景、カードは白+薄いシャドウ
- 窓メタファー: ライトブルーのフロスト+ソフトなボーダーフレーム
- しきい値バーチャート: accentSoft背景 + accent色で最新
- タスクリスト: 番号バッジ + 閾値表示

**ダークテーマ:**
- ディープネイビー背景
- 窓メタファー: SVG radialGradient + glow filter で光る表現
- バーチャート: 低opacity背景 + accent色で最新バーがグロー
- セクションヘッダー: uppercase + letter-spacing

**セッション画面（常にダーク）:**
- 背景 #06080E（テーマ設定に関わらず固定）
- 注視点、刺激、マスク、応答UIすべてSession色で統一
- 理由: 刺激提示のコントラスト精度、残像軽減、没入感

## 技術スタック

| レイヤー | 技術 | 用途 |
|---|---|---|
| メインUI | SwiftUI | ホーム・設定・ダッシュボード |
| 刺激提示 | Metal（MTKView + CADisplayLink） | フレーム精度の短時間刺激表示 |
| ノイズマスク | Metal Compute Shader | GPU高速ランダムドットノイズ生成 |
| タイミング | CACurrentMediaTime() | 反応時間（ms精度） |
| 適応的難易度 | 階段法（2-down/1-up） | 表示時間の自動調整 |
| データ | GRDB（WALモード） | 試行ログ・しきい値推移 |
| グラフ | Swift Charts | しきい値推移・反応時間分布 |
| ヘルス | HealthKit（mindfulSession） | セッション記録 |
| ソーシャル | GameKit | リーダーボード |
| 課金 | StoreKit 2（¥480） | Pro |
| 広告 | AdMob（インタースティシャル） | セッション完了後のみ |
| プロジェクト | XcodeGen | — |
| ローカライズ | 日本語・英語 | 初期から |

## 収益モデル

| 層 | 内容 | 価格 |
|---|---|---|
| 無料 | Task 1のみ・1日1セッション | ¥0 |
| Pro | 全3タスク・無制限・詳細分析・HealthKit・Game Center | ¥480（買い切り） |
| 広告 | セッション完了後（無料のみ、1日最大2回） | — |

## 画面構成

```
Tab 1: ホーム
├── 日付 + "MADO" タイトル + ストリークピル
├── 窓ビジュアルカード（視野スコア + 改善率）
├── 「▶ Start Training」ボタン（accent色）
├── 統計3カラム（継続日数 / 今日のセッション / ベスト記録）
├── 3タスクリスト（番号バッジ + 名前 + 閾値ms）
└── しきい値推移ミニチャート

Tab 2: セッション画面（★常にダーク・フルスクリーン）
├── タスク名 + 試行カウンター + 進捗バー
├── メイン表示エリア（Metal MTKView）
│   ├── 注視点 "+"
│   ├── 刺激（中央 + 周辺）
│   ├── ノイズマスク
│   └── 応答UI（中央2択 + 8方向ウェッジ）
├── フィードバック（✓/✗ + RT）
└── 一時停止ボタン

Tab 3: 分析ダッシュボード
├── 窓サイズ推移（AreaMark）
├── 3タスク別しきい値推移（LineMark）
├── 反応時間分布（PointMark）
└── Game Centerリンク

設定
├── テーマ切り替え（システム / ライト / ダーク）← ★ここ
├── Pro購入 / 復元
├── セッションリマインダー
├── HealthKit連携 ON/OFF
├── 画面輝度固定オプション
├── プライバシーポリシー / 利用規約
└── データリセット
```

## ゲームメカニクス（前版と同一。省略なし）

### UFOVパラダイム3タスク構成
- Task 1: 中央識別（Processing Speed）— 車/トラック2択
- Task 2: 中央+周辺（Divided Attention）— 8方向位置特定追加
- Task 3: 中央+周辺+ディストラクタ（Selective Attention）

### 適応的難易度（2-down/1-up階段法）
- 開始: Task1=333ms / Task2,3=前タスクしきい値+84ms
- 初期ステップ50ms → 最初のリバーサル後17msに縮小
- 最短: 17ms(60Hz) / 8ms(120Hz) / 最長: 500ms
- 収束: 9リバーサル → 最後6点平均 = しきい値
- 全タイミングはフレーム数で管理

### Metal/SpriteKit刺激提示
- Info.plist: CADisableMinimumFrameDurationOnPhone = true
- CADisplayLink.preferredFrameRateRange(min:80, max:120, preferred:120)
- タイミング参照: targetTimestamp（timestampではない）
- ノイズマスク: 4×4ブロック、動的、Metal Compute Shader
- 反応時間: CACurrentMediaTime()差分

## Phase分割

### Phase 1（MVP）— 4〜5週間
- ホーム + セッション（Task 1のみ）+ 基本分析
- **ライトテーマのみ（デフォルト白）**
- Metal MTKView + CADisplayLink + ノイズマスク
- 2-down/1-up階段法
- GRDB + StoreKit 2 + AdMob
- iOS標準ダークモード連動

### Phase 2 — 3〜4週間
- **ダークテーマ（v2デザイン）追加 + 設定テーマ切替UI**
- Task 2, 3 実装
- 分析ダッシュボード（Swift Charts）
- 窓メタファービジュアル
- HealthKit連携
- ProMotion 120Hz完全対応

### Phase 3 — 2〜3週間
- Game Center
- 刺激バリエーション追加
- ウィジェット / シェア機能
- State of Mind API連携

## App Store説明文（案）

### タイトル
MADO - 視野トレーニング

### サブタイトル
注意力を広げるゲーム

### 説明文
画面の真ん中と端っこ、同時に見分けられますか？

MADOは、注意を向けられる範囲＝「視野の窓」を広げるトレーニングゲームです。

■ 特徴
・ 1回約10分、気軽にプレイ
・ あなたのレベルに合わせて自動で難しさが変わる
・ 成績の推移がグラフでわかる
・ ライトテーマ / ダークテーマを選べます

※ 本アプリは医療機器ではありません。認知症の診断・治療・予防を目的としたものではありません。
