# Google Play Store リリースガイド

## 事前準備

### 1. 署名キーの生成
```bash
# Android Studio または以下のコマンドでキーストアを生成
keytool -genkey -v -keystore personal-color-app-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias personal-color-app

# 生成されたキーストアをandroid/ディレクトリに配置
mv personal-color-app-keystore.jks android/
```

### 2. 署名設定の確認
```bash
# android/key.propertiesファイルの設定確認
cat android/key.properties
```

## ビルド手順

### 1. 依存関係の更新
```bash
# Flutter依存関係の取得
flutter pub get

# Android Gradle依存関係の更新
cd android && ./gradlew clean && cd ..
```

### 2. App Bundleのビルド
```bash
# リリース用App Bundleの生成
flutter build appbundle --release

# 生成されたファイルの確認
ls -la build/app/outputs/bundle/release/
```

### 3. ビルド成果物の確認
```bash
# App Bundle情報の表示
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=build/app/outputs/bundle/release/app.apks

# サイズの確認
du -h build/app/outputs/bundle/release/app-release.aab
```

## Google Play Console設定

### 1. アプリの基本情報
- **パッケージ名**: `com.personalcolor.personal_color_app`
- **アプリ名**: パーソナルカラー診断アプリ
- **カテゴリ**: ライフスタイル > 美容

### 2. コンテンツ レーティング
- **対象年齢**: 全年齢
- **暴力的コンテンツ**: なし
- **成人向けコンテンツ**: なし
- **ギャンブル**: なし

### 3. データセーフティ
設定項目：
- **データ収集**: 写真（一時的、端末内処理のみ）
- **データ共有**: なし
- **セキュリティ対策**: 暗号化、即座削除
- **子ども向け**: 適合

### 4. プライバシーポリシー
```
https://personalcolorapp.com/privacy-policy.html
```

## アップロード手順

### 1. Google Play Console にログイン
```
https://play.google.com/console/
```

### 2. アプリの作成
1. 「アプリを作成」をクリック
2. アプリ名とパッケージ名を入力
3. アプリの種類：アプリ
4. 無料/有料：無料

### 3. App Bundle のアップロード
1. リリース > 制作版リリース
2. 「新しいリリースを作成」
3. App Bundle をアップロード：
   ```
   build/app/outputs/bundle/release/app-release.aab
   ```

### 4. リリースノートの設定
```
パーソナルカラー診断アプリ v1.0.0

【新機能】
・カメラを使った簡単パーソナルカラー診断
・AI分析による正確な色彩判定
・小学5年生でも使いやすい直感的なUI
・Material Design 3準拠の美しいデザイン

初回リリース版です。ぜひお試しください！
```

### 5. アプリの詳細設定

#### ストア掲載情報
- **アプリ名**: パーソナルカラー診断アプリ
- **簡潔な説明**: カメラでかんたんパーソナルカラー診断！あなたに似合う色を見つけよう
- **詳しい説明**: `android/app/src/main/play/listings/ja-JP/full-description.txt` の内容を使用

#### グラフィック アセット
必要なアセット：
- アプリ アイコン（512x512px）
- フィーチャー グラフィック（1024x500px）
- スクリーンショット（電話: 最低2枚、最大8枚）

### 6. 価格と配布
- **価格**: 無料
- **国・地域**: 日本
- **デバイス カテゴリ**: 携帯電話とタブレット

## 審査前チェックリスト

### 技術要件
- [ ] minSdkVersion 33 (Android 13) 設定済み
- [ ] targetSdkVersion 36 (Android 14) 設定済み  
- [ ] 64ビット対応（ARM64、x86_64）
- [ ] App Bundle形式でビルド
- [ ] ProGuard設定済み
- [ ] 署名済み

### コンテンツ要件
- [ ] プライバシーポリシー設定済み
- [ ] データセーフティ申告完了
- [ ] コンテンツ レーティング取得
- [ ] 必要な権限の説明記載
- [ ] スクリーンショット準備済み

### ポリシー準拠
- [ ] Google Playポリシー準拠
- [ ] ファミリー向けポリシー準拠
- [ ] データ保護規制準拠（GDPR対応）
- [ ] 子ども向けアプリ要件準拠

## リリース後の対応

### 1. リリース状況の確認
```bash
# Google Play Console でリリース状況を確認
# 審査は通常1-3日程度
```

### 2. ユーザーフィードバック対応
- レビューの監視
- クラッシュレポートの確認
- パフォーマンス指標の監視

### 3. アップデート準備
```bash
# バージョンコード・バージョン名の更新
# android/app/build.gradle.kts
versionCode = 2
versionName = "1.0.1"

# pubspec.yaml
version: 1.0.1+2
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. 署名エラー
```bash
# キーストアの確認
keytool -list -v -keystore android/personal-color-app-keystore.jks

# 署名設定の再確認
cat android/key.properties
```

#### 2. ビルドエラー
```bash
# キャッシュクリア
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
```

#### 3. Google Playアップロードエラー
- App Bundle サイズ制限確認（150MB以下）
- パッケージ名重複確認
- 署名証明書の一致確認

## セキュリティ注意事項

### 重要ファイルの管理
```bash
# 以下のファイルは絶対にGitにコミットしない
android/key.properties
android/personal-color-app-keystore.jks
android/app/google-services.json (Firebase使用時)
```

### 推奨設定
```bash
# .gitignoreに追加
echo "android/key.properties" >> .gitignore
echo "android/*.jks" >> .gitignore
```

## 参考リンク

- [Google Play Console](https://play.google.com/console/)
- [Android App Bundle ガイド](https://developer.android.com/guide/app-bundle)
- [Google Play ポリシー](https://play.google.com/about/developer-policy/)
- [ファミリー ポリシー](https://support.google.com/googleplay/android-developer/answer/9893335)
- [データセーフティ](https://support.google.com/googleplay/android-developer/answer/10787469)

---

**重要**: このドキュメントの手順に従って慎重にリリース作業を行ってください。不明な点がある場合は、必ずGoogle Play Console のヘルプドキュメントを確認してください。