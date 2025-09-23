---
applyTo: "client/**"
---

# Flutter Client 開発指示

## 📋 現在の状況
- **バージョン**: v1.4.0+20
- **配布状況**: iOS App Store配布済み、Android Play Store配布準備中
- **最新機能**: AIファッションコーディネート（phase1完了）、全年齢対応診断

## 📚 仕様書参照
`specifications/` 以下に格納された設計・仕様書に従い、開発を進めます。

### 主要仕様書
- `initialize/` - 初期実装仕様
- `ai-coordinate/` - AIファッションコーディネート機能
- `ai-makeup/`, `ai-makeup2/`, `ai-makeup3/` - AIメイクアップ機能（段階的実装）
- `allages/` - 全年齢対応パーソナルカラー診断
- `android/` - Android対応
- `makeup/` - メイクアップ推奨機能

## 🔧 開発コマンド（Makefile統一）

```bash
cd client/personal_color_app

# 基本コマンド
make help                    # 利用可能なコマンド一覧表示
make ios-debug-device        # iOS実機でデバッグ実行
make android-debug-device    # Android実機でデバッグ実行
make ios-release            # iOS リリースビルド（App Store用）
make android-release        # Android App Bundle作成（Play Store用）

# 従来のFlutterコマンドも利用可能
flutter pub get             # 依存関係取得
flutter test               # テスト実行
flutter analyze            # 静的解析
```

## 🏗️ アーキテクチャ

### Clean Architecture + DDD
```
lib/
├── core/           # 共通機能・ユーティリティ
├── features/       # 機能別モジュール（Clean Architecture）
│   ├── camera/     # カメラ撮影機能
│   ├── diagnosis/  # 診断結果表示・全年齢対応
│   ├── coordinate/ # AIファッションコーディネート
│   ├── makeup/     # AIメイクアップ機能
│   └── virtual_try_on/ # バーチャルトライオン
└── shared/         # UI共通要素
```

各featureは以下の層構造：
- `presentation/` - UI層 (pages, widgets, providers)
- `domain/` - ビジネスロジック層 (entities, repositories, usecases)
- `data/` - データ層 (datasources, models, repositories)

### 主要技術スタック
- **状態管理**: Provider + BLoC
- **ルーティング**: go_router ^12.1.1
- **カメラ**: camera ^0.10.5+5
- **API通信**: http ^1.1.0, dio ^5.3.2
- **DI**: get_it ^7.6.4

## MCP活用ガイドライン（クライアント開発）

### 実装前準備
- **プロジェクト分析**: Serena MCPを使用してシンボル検索・効率的なコード編集
- **キャッシュ更新**: プロジェクト情報を最新化

### 技術調査・ドキュメント参照
- **最新技術情報**: Flutter、Dart、Firebase関連の最新ドキュメントはContext7 MCPで確認
- **UI/UXパターン**: モバイルデザインパターンや最新のUI/UXトレンドを調査

### 外部サービス連携
- **決済機能**: アプリ内課金やStripe連携時はStripe MCPを利用
- **データ連携**: Kintoneとの連携が必要な場合はKintone MCPを利用

### GitHub連携
- **Issue・PR管理**: GitHub MCPを使用してissue作成、Pull Request管理を行う

### テスト・自動化
- **UIテスト**: 複雑なE2Eテストやブラウザベースのテスト（Flutter Web）が必要な場合はPlaywright MCPを活用
- **デバイステスト**: 実機テストの補完として、ブラウザベースのモバイル表示確認を実施
- **統合テスト**: IDE MCPを活用してJupyterベースのテストコード実行

## 🎯 開発原則

### iOS優先・Android対応
- **iOS版品質維持**: 既存iOS版の品質・機能を絶対に劣化させない
- **段階的アプローチ**: 一度に大きな変更をせず、段階的に実装
- **プラットフォーム固有**: 適切なプラットフォーム分離を行う

### コード品質
- **TDD実践**: テスト駆動開発によるコード品質確保
- **Clean Architecture遵守**: 依存方向の適切な管理
- **既存影響最小化**: 新機能として独立実装

### 実装時の注意
- **各タスクはコミット単位**で完結させる
- **仕様書更新**: 実装に合わせて関連仕様書を更新
- **後方互換性**: 既存APIとの互換性を維持