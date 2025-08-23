# App Store申請用メタデータ - 完了チェックリスト

## 📋 作成完了ファイル一覧

### ✅ メインメタデータ
- [x] `APP_STORE_METADATA.md` - App Store Connect設定用の詳細メタデータ
- [x] `APP_STORE_METADATA.json` - 設定項目をJSON形式で整理
- [x] `PRIVACY_POLICY.md` - プライバシーポリシー（Markdown版）
- [x] `TERMS_OF_SERVICE.md` - 利用規約（Markdown版）

### ✅ サポートサイト用HTML
- [x] `support-site/index.html` - メインサポートページ
- [x] `support-site/privacy-policy.html` - プライバシーポリシー（HTML版）
- [x] `support-site/terms-of-service.html` - 利用規約（HTML版）

### ✅ ガイド・参考資料
- [x] `SCREENSHOT_GUIDE.md` - スクリーンショット撮影ガイド
- [x] `iOS_APP_STORE_SUBMISSION_GUIDE.md` - 申請手順の完全ガイド

---

## 🚀 次のアクションアイテム

### 1. サポートサイトのデプロイ 🌐
```bash
# Firebase Hostingまたは類似サービスにデプロイ
# URLが以下のようになることを想定:
# https://personal-color-app-support.web.app/
# https://personal-color-app-support.web.app/privacy-policy.html
# https://personal-color-app-support.web.app/terms-of-service.html
```

### 2. App Store Connect アプリ作成 📱

**基本情報:**
- **アプリ名**: パーソナルカラー診断アプリ
- **バンドルID**: com.personal-color.diagnosis-app
- **SKU**: personal-color-diagnosis-001
- **プライマリ言語**: 日本語

**設定項目（APP_STORE_METADATA.jsonを参照）:**
- カテゴリ: エンターテイメント（プライマリ）/ 教育（セカンダリ）
- 年齢制限: 4+
- 価格: 無料

### 3. スクリーンショット撮影 📸

**必要サイズ:**
- iPhone 6.7" (1290×2796 px) - 必須
- iPhone 6.5" (1284×2778 px) - 必須

**撮影画面（5画面）:**
1. ホーム画面（ウェルカム画面）
2. カメラ撮影画面
3. 診断中画面（ローディング）
4. 診断結果画面
5. カラーパレット画面

**詳細**: `SCREENSHOT_GUIDE.md` を参照

### 4. アプリアイコン準備 🎨

**要求仕様:**
- **1024×1024 px** (App Store用)
- 透明部分なし、角丸なし
- パーソナルカラーをテーマにした親しみやすいデザイン

### 5. App Store Connect 設定入力 ⚙️

**メタデータ入力項目:**
```
✅ アプリ情報
  - アプリ名、サブタイトル
  - 説明文、キーワード
  - カテゴリ、年齢制限

✅ プライバシー情報
  - プライバシーポリシーURL
  - データ収集設定

✅ 審査情報
  - 連絡先情報
  - 審査用メモ

✅ 価格・配信設定
  - 無料設定
  - 日本のみ配信
```

### 6. Release Build 作成・アップロード 🔨

```bash
# Release buildの作成
cd /Users/mahiguch/dev/personal-color/client/personal_color_app
flutter build ios --release

# Xcodeでアーカイブ・アップロード
open ios/Runner.xcworkspace
# Product → Archive → Distribute App → App Store Connect
```

---

## ⚡ 優先度の高いタスク

### 🔥 即座に実行
1. **サポートサイトのデプロイ** - プライバシーポリシーURLが必要
2. **App Store Connect アプリ作成** - 基本設定を先に完了

### 📅 今週中に完了
3. **スクリーンショット撮影** - 全5画面を高品質で撮影
4. **アプリアイコン作成** - プロフェッショナルなデザイン

### 🎯 来週
5. **メタデータ全設定** - App Store Connect の全項目完了
6. **Release Build & 申請** - 最終ビルドをアップロードして申請

---

## 📞 連絡先・サポート情報

**設定済み連絡先:**
- Email: support@personal-color-app.com
- サポートURL: https://personal-color-app-support.web.app/support
- プライバシーポリシーURL: https://personal-color-app-support.web.app/privacy-policy

**⚠️ 注意**: 上記URLは実際にデプロイ後に有効になります。デプロイ前に App Store Connect で設定しないでください。

---

## 🎯 成功指標

### 申請準備完了の基準
- [ ] サポートサイトが正常にアクセス可能
- [ ] App Store Connect でアプリが作成済み
- [ ] 5種類のスクリーンショットが高品質で撮影済み
- [ ] 1024×1024px のアプリアイコンが準備済み
- [ ] Release Build が正常にアップロード済み
- [ ] 全メタデータ項目が入力済み
- [ ] プライバシー設定が完了済み

### 審査通過のポイント
- 子ども向け安全設計（4+レーティング）
- プライバシー保護の徹底説明
- 明確な利用目的（娯楽・教育）
- 技術的な安定性
- 法的要件の遵守

---

## 📚 参考資料

- **iOS App Store申請ガイド**: `iOS_APP_STORE_SUBMISSION_GUIDE.md`
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/

---

**🚀 TestFlightでの動作検証が完了したので、次はサポートサイトのデプロイとApp Store Connectでのアプリ作成から始めましょう！**

**現在の進捗: メタデータ作成 ✅ 完了 → 次: サポートサイトデプロイ + アプリ作成**
