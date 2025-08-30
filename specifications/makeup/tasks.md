# タスクリスト - メイクアップ推奨機能

## 概要

- **総タスク数**: 24タスク ✅ **完了**
- **推定作業時間**: 10-12日間 → **実績**: 7フェーズ完了
- **優先度**: 高 → **達成**
- **実装方式**: Clean Architecture + TDD → **適用済み**
- **プロジェクト状況**: 🎉 **全機能実装完了** 🎉

## タスク一覧

### Phase 1: 準備・調査 (推定: 1日間) ✅ 完了

#### Task 1.1: プロジェクト構造作成とDI拡張

- [x] `lib/features/makeup/` ディレクトリ構造作成
- [x] `lib/features/makeup/domain/entities/` 作成
- [x] `lib/features/makeup/domain/repositories/` 作成
- [x] `lib/features/makeup/domain/usecases/` 作成
- [x] `lib/features/makeup/data/` 作成
- [x] `lib/features/makeup/presentation/` 作成
- [x] `lib/core/di/injection_container.dart` への新サービス登録準備

**完了条件**: フォルダ構造が作成され、既存DIコンテナが拡張可能な状態
**依存**: なし  
**推定時間**: 1時間
**実装状況**: ✅ 完了

#### Task 1.2: 静的商品データ作成

- [x] `server/data/makeup_products.json` 作成
- [x] 4パーソナルカラータイプ × 3カテゴリ × 3商品 = 36商品データ作成
- [x] 商品画像URL、Amazon URL、価格情報の設定
- [x] JSONスキーマ検証ツールでデータ品質確認
- [x] テスト用商品データセット作成

**完了条件**: 全パーソナルカラータイプの商品データが完備、スキーマ検証通過
**依存**: なし
**推定時間**: 3時間
**実装状況**: ✅ 完了

#### Task 1.3: サーバー側APIエンドポイント準備

- [x] `server/src/api/endpoints/makeup.py` 作成
- [x] `GET /api/v1/makeup-recommendations/{type}` ルーティング設定
- [x] 静的JSONデータ読み込み機能実装
- [x] エラーハンドリング（不正なtype値など）
- [x] APIレスポンス形式のバリデーション

**完了条件**: APIエンドポイントが基本動作、静的データ返却可能
**依存**: Task 1.2 (商品データ作成)
**推定時間**: 2時間
**実装状況**: ✅ 完了

### Phase 2: Domain層実装 (推定: 2日間) ✅ 完了

#### Task 2.1: Domain Entities実装

- [x] `MakeupProduct` エンティティ作成
- [x] `MakeupRecommendation` エンティティ作成  
- [x] `PersonalColorType` enum拡張（既存利用）
- [x] エンティティの等価性比較（Equatable）実装
- [x] エンティティ単体テスト作成

**完了条件**: エンティティが正しく動作、単体テスト通過
**依存**: Task 1.1 (プロジェクト構造)
**推定時間**: 3時間
**実装状況**: ✅ 完了

#### Task 2.2: Repository抽象定義

- [x] `MakeupRepository` 抽象クラス作成
- [x] `getMakeupRecommendations` メソッド定義
- [x] `Either<Failure, MakeupRecommendation>` 戻り値設計
- [x] Repository インターフェース仕様書作成
- [x] Repository 抽象クラステスト作成

**完了条件**: Repository抽象定義完了、インターフェース仕様明確化
**依存**: Task 2.1 (Domain Entities)
**推定時間**: 2時間
**実装状況**: ✅ 完了

#### Task 2.3: UseCase実装

- [x] `GetMakeupRecommendationsUseCase` クラス作成
- [x] ビジネスロジック実装（キャッシュ確認→API呼び出し）
- [x] エラーハンドリング（ネットワーク・サーバー・データ不整合）
- [x] UseCase単体テスト実装（正常系・異常系・境界値）
- [x] テストカバレッジ90%以上確認

**完了条件**: UseCase実装完了、全テストケース通過
**依存**: Task 2.2 (Repository抽象定義)  
**推定時間**: 4時間
**実装状況**: ✅ 完了

#### Task 2.4: Failure定義拡張

- [x] `MakeupFailure` クラス作成
- [x] `NetworkFailure`, `ServerFailure`, `DataFailure`, `CacheFailure` 実装
- [x] 既存 `Failure` クラスとの整合性確保
- [x] エラーメッセージの多言語対応準備
- [x] Failure単体テスト作成

**完了条件**: エラー処理が統一され、テスト通過
**依存**: Task 2.1 (Domain Entities)
**推定時間**: 2時間
**実装状況**: ✅ 完了

### Phase 3: Data層実装 (推定: 2.5日間) ✅ 完了

#### Task 3.1: Data Models実装

- [x] `MakeupProductModel` 作成（Entity↔JSON変換）
- [x] `MakeupRecommendationModel` 作成
- [x] `fromJson`, `toJson` メソッド実装
- [x] JSON serialization テスト実装
- [x] 不正データ処理のテスト作成

**完了条件**: Model変換が正確、JSON変換テスト通過
**依存**: Task 2.1 (Domain Entities)
**推定時間**: 3時間
**実装状況**: ✅ 完了

#### Task 3.2: RemoteDataSource実装

- [x] `MakeupRemoteDataSource` インターフェース作成
- [x] `MakeupRemoteDataSourceImpl` 実装
- [x] Dio HTTPクライアント統合
- [x] APIエンドポイント呼び出し実装
- [x] ネットワークエラーハンドリング
- [x] RemoteDataSource単体テスト（モック使用）

**完了条件**: API通信が正常動作、エラーハンドリング完備
**依存**: Task 3.1 (Data Models), Task 1.3 (APIエンドポイント)
**推定時間**: 4時間
**実装状況**: ✅ 完了

#### Task 3.3: LocalDataSource（キャッシュ）実装

- [x] `MakeupLocalDataSource` インターフェース作成  
- [x] SharedPreferences を使用したキャッシュ実装
- [x] キャッシュキー設計とライフサイクル管理
- [x] キャッシュ有効期限判定（24時間）
- [x] ローカルストレージ例外ハンドリング
- [x] LocalDataSource単体テスト実装

**完了条件**: キャッシュ機能が正常動作、期限管理適切
**依存**: Task 3.1 (Data Models)
**推定時間**: 4時間
**実装状況**: ✅ 完了

#### Task 3.4: Repository実装

- [x] `MakeupRepositoryImpl` 作成
- [x] RemoteDataSource + LocalDataSource 統合
- [x] キャッシュファースト戦略実装
- [x] エラー変換（DioException → Failure）
- [x] Repository統合テスト実装
- [x] モック・実際のAPI両方でテスト

**完了条件**: Repository完全動作、統合テスト通過
**依存**: Task 3.2 (RemoteDataSource), Task 3.3 (LocalDataSource)
**推定時間**: 4時間
**実装状況**: ✅ 完了

#### Task 3.5: DI登録とサービス統合

- [x] `injection_container.dart` への全サービス登録
- [x] Singleton・Factory パターンの適切な使い分け
- [x] 依存関係の注入確認
- [x] DI統合テスト実装
- [x] 既存DIサービスとの干渉確認

**完了条件**: DI が正常動作、全依存関係解決
**依存**: Task 3.4 (Repository実装)
**推定時間**: 1時間
**実装状況**: ✅ 完了

### Phase 4: Presentation層実装 (推定: 3日間) ✅ 完了

#### Task 4.1: Provider実装（状態管理）

- [x] `MakeupRecommendationProvider` 作成
- [x] `ChangeNotifier` による状態管理実装
- [x] ローディング・エラー・データ状態の管理
- [x] `loadRecommendations`, `refresh`, `setSelectedCategory` メソッド
- [x] Provider単体テスト実装（MockUseCase使用）
- [x] 状態遷移テスト（loading → data/error）

**完了条件**: Provider正常動作、状態管理テスト通過
**依存**: Task 2.3 (UseCase実装)
**推定時間**: 4時間
**実装状況**: ✅ 完了

#### Task 4.2: ProductCardWidget実装

- [x] 商品カードUIコンポーネント作成
- [x] Material Design 3準拠のデザイン実装
- [x] 商品画像、名前、ブランド、価格、説明表示
- [x] 「Amazonで見る」ボタンと確認ダイアログ
- [x] 画像読み込み（プログレッシブローディング）
- [x] ProductCardWidget ウィジェットテスト

**完了条件**: カードコンポーネント完成、ウィジェットテスト通過
**依存**: Task 2.1 (Domain Entities)
**推定時間**: 5時間
**実装状況**: ✅ 完了

#### Task 4.3: MakeupRecommendationPage実装

- [x] メインページWidget作成
- [x] タブ型レイアウト（アイシャドウ・チーク・リップ）
- [x] パーソナルカラータイプ表示ヘッダー
- [x] ローディング・エラー状態のUI実装
- [x] 商品リスト表示（ProductCard使用）
- [x] 戻るボタンとナビゲーション
- [x] レスポンシブ対応（iPhone/iPad）

**完了条件**: ページ機能完成、各状態が適切に表示
**依存**: Task 4.1 (Provider), Task 4.2 (ProductCard)  
**推定時間**: 6時間
**実装状況**: ✅ 完了

#### Task 4.4: 診断結果ページ統合

- [x] 既存 `IOSDiagnosisResultPage` の調査・理解
- [x] 「おすすめのメイク」ボタン追加
- [x] 既存レイアウトを崩さないボタン配置
- [x] ナビゲーション実装（MaterialPageRoute）
- [x] 診断結果データの受け渡し実装
- [x] 統合後の回帰テスト実行

**完了条件**: ボタン追加完了、既存機能に影響なし
**依存**: Task 4.3 (メインページ実装)
**推定時間**: 3時間
**実装状況**: ✅ 完了

### Phase 5: サーバー側Gemini AI統合 (推定: 2日間) ✅ 完了

#### Task 5.1: Gemini プロンプト設計

- [x] メイクアップ推奨理由生成プロンプト作成
- [x] パーソナルカラータイプ別のプロンプト最適化
- [x] 小学5年生向け言語レベル調整（3-4文程度）
- [x] プロンプトテンプレート作成
- [x] プロンプト品質テスト実施

**完了条件**: 適切な推奨理由が生成、言語レベル適切
**依存**: Task 1.2 (商品データ作成)
**推定時間**: 3時間
**実装状況**: ✅ 完了

#### Task 5.2: Gemini Service統合

- [x] `makeup.py` への Gemini AI連携実装
- [x] 商品データ + パーソナルカラーを基にした説明生成
- [x] AI生成キャッシング（7日間）実装
- [x] Gemini APIエラーハンドリング
- [x] AI応答時間最適化（2秒以内）
- [x] Gemini統合テスト実装

**完了条件**: AI説明文生成動作、エラー処理適切
**依存**: Task 5.1 (プロンプト設計), Task 1.3 (APIエンドポイント)
**推定時間**: 4時間
**実装状況**: ✅ 完了

#### Task 5.3: サーバー側統合テスト

- [x] 全APIエンドポイントの統合テスト
- [x] 商品データ + AI説明文の完全レスポンステスト
- [x] パフォーマンステスト（2秒以内応答）
- [x] エラーケーステスト（不正type、Gemini失敗など）
- [x] ロードテスト（50並列リクエスト）

**完了条件**: サーバー側全機能正常動作、パフォーマンス要件達成
**依存**: Task 5.2 (Gemini Service統合)
**推定時間**: 2時間
**実装状況**: ✅ 完了

### Phase 6: 統合テスト・最適化 (推定: 2日間) ✅ 完了

#### Task 6.1: エンドツーエンドテスト

- [x] 診断結果ページ → メイクアップ推奨の完全フロー
- [x] 3つの統合テストシナリオ実行
- [x] キャッシュ機能の動作確認
- [x] エラー状態からの回復フローテスト
- [x] 外部リンク（Amazon）遷移テスト

**完了条件**: E2Eテストスイート完成、全シナリオ通過
**依存**: Task 4.4 (統合), Task 5.3 (サーバー側テスト)
**推定時間**: 4時間
**実装状況**: ✅ 完了

#### Task 6.2: パフォーマンス最適化

- [x] 画像読み込み最適化実装
- [x] プリフェッチング機能実装（診断結果時）
- [x] メモリ使用量最適化
- [x] 画像キャッシュのLRU実装（50MB上限）
- [x] レスポンス時間測定・改善
- [x] パフォーマンステスト実行・検証

**完了条件**: 全パフォーマンス要件達成（3秒以内読み込み等）
**依存**: Task 6.1 (E2Eテスト)
**推定時間**: 5時間
**実装状況**: ✅ 完了

#### Task 6.3: セキュリティ・品質確保

- [x] 入力検証強化（PersonalColorType等）
- [x] XSS・インジェクション対策確認
- [x] Amazon以外URL無効化実装
- [x] セキュリティテスト実行
- [x] コードレビュー実施
- [x] リントツール・静的解析実行

**完了条件**: セキュリティテスト通過、品質基準達成
**依存**: Task 6.2 (パフォーマンス最適化)
**推定時間**: 3時間
**実装状況**: ✅ 完了

### Phase 7: 最終検証・ドキュメント (推定: 1.5日間) ✅ 完了

#### Task 7.1: 実機テスト

- [x] iPhone 13 mini, iPhone 14 Pro Maxでの実機テスト
- [x] 様々なネットワーク環境での動作確認
- [x] iPad でのレスポンシブ表示確認
- [x] アクセシビリティ（VoiceOver）テスト
- [x] バッテリー消費・発熱確認
- [x] 実機テストレポート作成

**完了条件**: 実機で正常動作、ユーザビリティ問題なし
**依存**: Task 6.3 (品質確保)
**推定時間**: 4時間
**実装状況**: ✅ 完了

#### Task 7.2: ドキュメント更新・完成

- [x] README.md の機能説明追加
- [x] API仕様書の最終更新
- [x] 開発者向けセットアップガイド更新
- [x] ユーザー向け機能説明作成
- [x] テスト実行ガイド作成

**完了条件**: ドキュメント完備、新機能説明充実
**依存**: Task 7.1 (実機テスト)
**推定時間**: 2時間
**実装状況**: ✅ 完了

#### Task 7.3: 本番デプロイ準備

- [x] プロダクション環境設定確認
- [x] 環境変数・設定ファイル最終確認
- [x] サーバー側デプロイスクリプト更新
- [x] iOS App Store向けビルド準備
- [x] リリースノート作成
- [x] ロールバック計画作成

**完了条件**: 本番デプロイ準備完了、リリース可能状態
**依存**: Task 7.2 (ドキュメント更新)
**推定時間**: 2時間
**実装状況**: ✅ 完了

## 実装順序

### 並行実行可能なタスク

- **Phase 1**: Task 1.1, 1.2 は並行実行可能
- **Phase 2**: Task 2.1, 2.4 は並行実行可能
- **Phase 3**: Task 3.1 完了後、3.2と3.3は並行実行可能
- **Phase 4**: Task 4.1, 4.2 は並行実行可能
- **Phase 5**: Task 5.1, 5.2 はある程度並行実行可能

### 実装推奨順序

1. **Phase 1 → Phase 2**: 基盤準備完了後ドメイン層
2. **Phase 2 → Phase 3**: ドメイン定義後データ層実装
3. **Phase 3 → Phase 4**: データ層完成後UI層実装
4. **Phase 4 → Phase 5**: UI基本完成後AI機能統合
5. **Phase 5 → Phase 6**: AI統合後の統合テスト・最適化
6. **Phase 6 → Phase 7**: 品質確保後の最終検証

### 依存関係マップ

```
Task 1.1 (構造) → Task 2.1 (Entity) → Task 3.1 (Model) → Task 4.1 (Provider)
Task 1.2 (データ) → Task 1.3 (API) → Task 5.1 (プロンプト) → Task 5.2 (AI)
                                  ↘ Task 3.2 (RemoteDS) → Task 3.4 (Repo)
Task 2.1 → Task 2.2 (Repo抽象) → Task 2.3 (UseCase) → Task 4.1
Task 4.1, 4.2 → Task 4.3 (ページ) → Task 4.4 (統合)
```

## リスクと対策

- **Gemini AI応答遅延**: タイムアウト設定短縮、キャッシュ戦略強化
- **画像読み込み遅延**: プログレッシブローディング、画像圧縮
- **既存機能への影響**: 段階的統合、包括的回帰テスト
- **実機パフォーマンス問題**: 早期実機テスト、プロファイリング実施
- **商品データ品質**: 品質チェックツール、データ検証プロセス

## 注意事項

### 開発原則

- **各タスクはコミット単位**で完結させる
- **TDD原則**: テストファースト、レッド→グリーン→リファクタ
- **Clean Architecture遵守**: 依存方向の厳密管理
- **既存コード影響最小化**: 新機能として独立実装

### 品質確保

- **タスク完了時は必要に応じて品質チェック実行**
  - リント（`flutter analyze`）
  - テスト実行（`flutter test`）
  - カバレッジ確認
- **不明点は実装前に確認する**
- **各Phaseの最後に統合テスト実行**

### コミット戦略

- **Task単位でのコミット**: 各タスクで1-2コミット
- **ブランチ戦略**: `feature/makeup-recommendation` ブランチで実装
- **PR作成**: Phase毎に個別PRとして作成、レビュー後マージ
- **コミットメッセージ**: `feat(makeup): Task 2.1 - Domain Entities実装`

この タスクリストにより、メイクアップ推奨機能の段階的かつ確実な実装を実現し、小学5年生ユーザーにとって価値ある機能を提供します。