# TestFlight 配信手順書

## 🎯 TestFlight配信のステップ

### Step 1: Xcodeでのアーカイブ作成

1. **Xcodeでプロジェクト開く**
   - `open ios/Runner.xcworkspace` でXcodeを起動
   - ✅ 完了済み

2. **ビルド設定確認**
   - Scheme: Runner (Release)
   - Destination: Any iOS Device (arm64)
   - Code Signing: Distribution証明書を選択

3. **アーカイブ実行**
   - Product → Archive を選択
   - ビルド・アーカイブ完了まで待機

### Step 2: App Store Connectアップロード

1. **アーカイブからアップロード**
   - Window → Organizer → Archives
   - 作成されたアーカイブを選択
   - "Distribute App" をクリック

2. **配信方法選択**
   - "App Store Connect" を選択
   - "Upload" を選択

3. **アップロード設定**
   - Include bitcode: OFF (推奨)
   - Upload your app's symbols: ON
   - Manage Version and Build Number: ON

### Step 3: TestFlight設定

1. **App Store Connectでの設定**
   - https://appstoreconnect.apple.com にアクセス
   - "Personal Color App" を選択
   - "TestFlight" タブに移動

2. **ベータテスター招待**
   - "Internal Testing" でチーム内テスト
   - "External Testing" で一般ベータテスター（最大10,000人）

3. **テスト情報設定**
   - ベータアプリの説明
   - テストの詳細情報
   - フィードバック項目

### Step 4: ベータテスト実行

1. **テスター招待**
   - メールアドレスでテスター招待
   - TestFlightアプリでのインストール確認

2. **テスト実行項目**
   - ✅ アプリ起動・基本動作確認
   - ✅ カメラ撮影機能
   - ✅ 本番API接続・診断機能
   - ✅ エラーハンドリング
   - ✅ パフォーマンス・メモリ使用量

3. **フィードバック収集**
   - TestFlightアプリ内フィードバック
   - クラッシュレポート分析
   - パフォーマンス指標確認

## 📋 現在の準備状況

### ✅ 完了項目
1. **コードの最終品質確認**: 全テスト成功
2. **バージョン更新**: 1.0.0+2 (TestFlight用)
3. **本番API接続**: 最新URLに更新済み
4. **Xcodeプロジェクト**: 起動準備完了

### 🔄 実行中項目
1. **Xcodeアーカイブ作成**: 手動で実行中
2. **App Store Connect準備**: アップロード待機中

### ⏳ 待機中項目
1. **TestFlightアップロード**: アーカイブ完了後
2. **ベータテスト実行**: アップロード完了後
3. **フィードバック収集**: テスト実行後

## 🚨 注意事項

### コード署名
- Distribution証明書が必要
- Provisioning Profileの確認
- Bundle IDの一致確認

### App Store Connect設定
- アプリメタデータの事前準備
- プライバシー情報の設定
- 年齢制限設定（4+）

### テスト項目
- 実機での動作確認（複数機種推奨）
- ネットワーク環境テスト
- 小学5年生による操作テスト

## 📞 次のアクション

1. **Xcodeでアーカイブ完了まで待機**
2. **App Store Connectへアップロード**
3. **TestFlight配信開始**
4. **ベータテスト実行・フィードバック収集**
5. **修正完了後にApp Store申請へ進行**

---
**実行者**: Claude Code  
**作成日時**: 2025年8月21日  
**更新予定**: アーカイブ完了後