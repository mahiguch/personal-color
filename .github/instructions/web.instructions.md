---
applyTo: "web/**"
---

# Web ティザーサイト開発指示

このディレクトリでは、AIスタイリストのティザーサイト開発を行います。

## 📋 仕様書の参照

以下の仕様書を必ず参照してコードの変更・追加を行ってください：

### 必須参照ドキュメント
- **要件定義**: `specifications/teaser/requirements.md`
  - 機能要件、非機能要件、技術要件を確認
  - ターゲットユーザー（保護者向け）の理解
  - 対応環境（iOS 15+, Android 8.0+）の確認

- **設計書**: `specifications/teaser/design.md` 
  - システム構成、技術スタック（Next.js 15）
  - Figmaベースのデザインシステム
  - カラーパレット、タイポグラフィ、コンポーネント設計
  - 画像最適化、レスポンシブ設計

- **タスクリスト**: `specifications/teaser/tasks.md`
  - 実装手順、工数見積もり
  - 画像アセット生成要件
  - 具体的なコマンド、設定ファイル例

## 🎯 開発方針

### 技術スタック
- **フレームワーク**: Next.js 15 (App Router)
- **スタイリング**: Tailwind CSS + shadcn/ui
- **言語**: TypeScript
- **ホスティング**: Firebase App Hosting
- **サイトタイプ**: 静的サイト（`output: 'export'`）

### デザイン原則
- **Figmaデザイン準拠**: カラーパレット、レイアウトはFigmaベース
- **レスポンシブファースト**: モバイル、タブレット、デスクトップ対応
- **パフォーマンス重視**: Lighthouse 80+、LCP 1秒以内
- **アクセシビリティ**: Figmaデザインのコントラスト比準拠

### コンテンツ要件
- **ターゲット**: 保護者（30-40代）がプライマリー
- **メッセージ**: 安全性、教育的価値、プライバシー保護を重視
- **文言**: 仕様書記載の具体的なキャッチコピー・レビュー内容を使用

## 📁 ディレクトリ構成

```
web/
├── src/
│   ├── app/
│   │   ├── page.tsx          # ランディングページ
│   │   ├── privacy/page.tsx  # プライバシーポリシー
│   │   └── support/page.tsx  # サポート（FAQ）
│   ├── components/
│   │   ├── ui/              # shadcn/ui components
│   │   ├── layout/          # Header, Footer
│   │   └── sections/        # Hero, Features, Reviews
│   ├── lib/
│   │   ├── utils.ts
│   │   └── constants.ts
│   └── types/
└── public/
    ├── app_icon.svg         # 既存ロゴ
    ├── images/              # 生成画像
    ├── icons/               # 機能アイコン（4種）
    ├── screenshots/         # アプリスクリーンショット（3枚）
    └── avatars/             # レビューアバター（3種）
```

## 🎨 画像アセット要件

### 生成が必要な画像
1. **ヒーロー背景画像** (1200x800px, WebP)
2. **機能アイコン4種** (64x64px, SVG): カメラ、AI、カラーパレット、子ども向け
3. **ユーザーアバター3種** (128x128px, PNG): 保護者男性、子ども女性、保護者女性
4. **装飾背景要素** (各種サイズ, SVG)

### 画像生成プロンプト
詳細なプロンプト例は `specifications/teaser/requirements.md` の「6.4 画像生成について」セクションを参照。

## 🔧 実装時の注意点

### 必須実装内容
- **4つのメインセクション**: Hero, Features, Reviews, Footer
- **具体的なコンテンツ**: 仕様書記載の文言・レビュー内容を使用
- **静的サイト設定**: `next.config.js` で `output: 'export'`
- **Firebase App Hosting**: 既存プロジェクト `personal-color` を使用

### MCP活用ガイドライン
- **実装前準備**: Serena MCPでキャッシュを更新し、プロジェクト情報を最新化
- **技術調査**: Next.js 15、shadcn/ui、Firebase関連の最新ドキュメントはContext7 MCPで確認
- **GitHub連携**: issue作成、Pull Request管理はGitHub MCPを利用
- **ブラウザテスト**: レスポンシブデザイン確認やE2Eテストが必要な場合はPlaywright MCPを活用

### パフォーマンス要件
- Next.js 15 Image コンポーネント使用（unoptimized: false）
- WebP形式画像の優先使用
- 遅延読み込み適用
- CSS最適化（experimental.optimizeCss: true）

### コーディング規約
- TypeScript厳密モード
- Tailwind CSS クラス使用
- shadcn/ui コンポーネント活用
- アクセシビリティ属性（alt, aria-label等）必須

## 📝 実装前の確認事項

1. **仕様書の最新版確認**: 3つのMDファイルすべてを確認
2. **Figmaデザインとの整合性**: カラー、レイアウト、コンポーネントデザイン
3. **画像アセット準備**: 生成またはコピーが必要な画像の確認
4. **技術要件確認**: Next.js 15、iOS 15+対応、静的サイト設定

## 🚀 開発の進め方

1. **Phase 1**: プロジェクト初期設定（Next.js 15, shadcn/ui, Firebase）
2. **Phase 2**: 画像アセット準備・生成
3. **Phase 3**: デザインシステム・UI基盤
4. **Phase 4**: レイアウト・共通コンポーネント
5. **Phase 5**: ランディングページ実装
6. **Phase 6**: サポートページ実装
7. **Phase 7**: テスト・品質保証
8. **Phase 8**: デプロイ・運用設定

詳細な手順は `specifications/teaser/tasks.md` を参照してください。

---

**重要**: コード変更前に必ず仕様書3点を確認し、要件に沿った実装を行ってください。疑問がある場合は仕様書の該当箇所を再確認してください。
