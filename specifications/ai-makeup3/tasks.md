# AI生成メイク画面改善 - 実装タスクリスト

## 1. 概要

設計書に基づき、AI生成メイク画面改善の具体的な実装タスクを段階別に定義する。
各タスクには優先度、工数見積、依存関係を明記し、効率的な実装を可能にする。

## 2. Phase 1: Before/After比較 + ハイライト機能

### 2.1 データモデル拡張

#### T1-001: 新規エンティティ作成 [優先度: 高] [工数: 0.5日] 【進捗: 部分完了】
**ファイル**: `lib/features/makeup/domain/entities/highlight_area.dart`
```dart
// HighlightArea, HighlightCoordinates, 関連enumを実装
// - HighlightType (eye, cheek, lip, etc.)
// - HighlightShape (rectangle, circle, oval)
// - AnimationType (none, fade, pulse, glow)
```
**依存**: なし
**受入条件**:
- [x] HighlightAreaエンティティが作成され、Equatableを継承
- [x] 相対座標(0.0-1.0)での座標計算が正常動作
- [x] 単体テストが通る

#### T1-002: MakeupRecommendationエンティティ拡張 [優先度: 高] [工数: 0.5日] 【進捗: 部分完了】
**ファイル**: `lib/features/makeup/domain/entities/makeup_recommendation.dart`
```dart
// 新規フィールド追加:
// - estimatedAge, ageGroup, highlightAreas
// - hasHighlightData getter追加
```
**依存**: T1-001
**受入条件**:
- [x] 新規フィールドが追加され、後方互換性が保持
- [x] hasHighlightData等のヘルパーメソッドが動作
- [x] 既存テストが継続して通る

#### T1-003: データモデル拡張 [優先度: 高] [工数: 1日] 【進捗: 部分完了】
**ファイル**: `lib/features/makeup/data/models/ai_makeup_recommendation_model.dart`
```dart
// APIレスポンスモデル更新
// - highlightAreas配列のJSON parsing
// - estimatedAge, ageGroupのマッピング
```
**依存**: T1-002
**受入条件**:
- [x] JSONからDartオブジェクトへの変換が正常動作
- [x] null値の適切な処理
- [x] API互換性テストが通る

### 2.2 Before/After UI実装

#### T1-004: BeforeAfterComparisonWidget作成 [優先度: 高] [工数: 1.5日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/presentation/widgets/before_after_comparison_widget.dart`
```dart
// メイン比較ウィジェット実装
// - 横並び画像レイアウト (45%ずつ)
// - 縦長アスペクト比対応 (3:4)
// - レスポンシブデザイン
```
**依存**: なし
**受入条件**:
- [x] Before/After画像が正しく45%ずつで表示
- [x] 縦長画像のアスペクト比が維持
- [x] 様々な画面サイズで正常表示
- [x] ウィジェットテストが通る

#### T1-005: 画像処理・表示最適化 [優先度: 中] [工数: 1日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/presentation/widgets/optimized_image_widget.dart`
```dart
// 画像読み込み最適化
// - Base64デコード効率化
// - メモリ使用量最適化
// - 段階的読み込み (Before → After)
```
**依存**: T1-004
**受入条件**:
- [x] メモリ使用量が適切なレベル (< 50MB)
- [x] 画像読み込み時間が10秒以内
- [x] OOMエラーが発生しない

### 2.3 ハイライト機能実装

#### T1-006: HighlightOverlayWidget作成 [優先度: 高] [工数: 2日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/presentation/widgets/highlight_overlay_widget.dart`
```dart
// CustomPainter使用のハイライト描画
// - 相対座標から絶対座標への変換
// - 複数形状対応 (rectangle, circle, oval)
// - アニメーション対応 (fade, pulse)
```
**依存**: T1-001, T1-004
**受入条件**:
- [x] ハイライト領域が正確な座標に表示
- [x] 複数のハイライトが同時表示可能
- [x] fade/pulseアニメーションが滑らか
- [x] パフォーマンス60FPS維持

#### T1-007: ハイライト制御UI [優先度: 中] [工数: 0.5日] 【進捗: 完了（既存ウィジェットに内包）】
**ファイル**: `lib/features/makeup/presentation/widgets/highlight_controls_widget.dart`
```dart
// ハイライトON/OFF切り替え
// - トグルボタン実装
// - 状態管理連携
```
**依存**: T1-006
**受入条件**:
- [x] ハイライトの表示/非表示が瞬時切り替え
- [x] ボタン状態とハイライト状態が同期
- [x] アクセシビリティ対応

### 2.4 メインページ統合

#### T1-008: AIMakeupRecommendationPageV3作成 [優先度: 高] [工数: 1.5日] 【進捗: 部分完了】
**ファイル**: `lib/features/makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart`
```dart
// 新しいメインページ実装
// - ScrollView構成
// - 各Widgetの統合
// - Provider連携
```
**依存**: T1-004, T1-006, T1-007
**受入条件**:
- [x] 全セクションが正しい順序で表示
- [x] スクロール動作が滑らか
- [x] 読み込み状態の適切な表示
- [x] エラー状態の適切なハンドリング

#### T1-009: Provider更新 [優先度: 高] [工数: 1日] 【進捗: 部分完了】
**ファイル**: `lib/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart`
```dart
// 新機能対応のProvider拡張
// - ハイライト表示状態管理
// - エラーハンドリング強化
// - 段階的読み込み制御
```
**依存**: T1-003, T1-008
**受入条件**:
- [x] 新しいデータモデルとの連携が正常
- [x] ハイライト状態が正しく管理
- [x] エラー状態の適切な通知
- [x] 既存機能が継続動作

### 2.5 Phase 1 統合・テスト

#### T1-010: 統合テスト実装 [優先度: 中] [工数: 1日] 【進捗: 完了】
**ファイル**: `test/integration/ai_makeup_v3_integration_test.dart`
```dart
// Phase 1機能の統合テスト
// - APIからUI表示までの完全フロー
// - エラーシナリオテスト
```
**依存**: T1-009
**受入条件**:
- [x] 正常フローの統合テストが通る
- [ ] 主要エラーシナリオをカバー
- [ ] 30秒以内読み込み要件を満たす

#### T1-011: パフォーマンス調整 [優先度: 中] [工数: 1日] 【進捗: 未着手】
**対象**: 全Phase 1実装
```dart
// パフォーマンス最適化
// - メモリリークチェック
// - アニメーション最適化
// - 読み込み速度改善
```
**依存**: T1-010
**受入条件**:
- [ ] 30秒読み込み目標を達成
- [ ] メモリ使用量が適切な範囲
- [ ] 60FPS動作を維持
- [ ] デバイス発熱なし

## 3. Phase 2: メイク解説 + 年齢適応機能

### 3.1 年齢適応データモデル

#### T2-001: 年齢・経験レベル エンティティ [優先度: 高] [工数: 0.5日] 【進捗: 部分完了（診断ドメインに実装）】
**ファイル**: `lib/features/makeup/domain/entities/age_group.dart`
```dart
// AgeGroup enum, MakeupExperienceLevel enum
// - サーバー年齢分類との整合性
// - 表示名取得メソッド
```
**依存**: なし
**受入条件**:
- [ ] 5段階年齢分類が正しく定義
- [ ] サーバーとの互換性確保
- [ ] 表示名の多言語化準備

#### T2-002: MakeupStepエンティティ作成 [優先度: 高] [工数: 1日] 【進捗: 部分完了】
**ファイル**: `lib/features/makeup/domain/entities/makeup_step.dart`
```dart
// MakeupStep, DifficultyLevel
// - ステップ詳細情報
// - 年齢適応説明文
// - ハイライト連動機能
```
**依存**: T2-001, T1-001
**受入条件**:
- [ ] ステップ情報の完全なデータモデル
- [ ] ハイライト連動のID管理
- [ ] 時間・難易度情報の適切な型

#### T2-003: 拡張MakeupRecommendation更新 [優先度: 高] [工数: 0.5日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/domain/entities/makeup_recommendation.dart`
```dart
// Phase 2新規フィールド追加:
// - stepByStepInstructions, personalColorExplanation
// - makeupExperienceLevel
```
**依存**: T2-002
**受入条件**:
- [ ] 新フィールドが適切に追加
- [ ] ステップ取得ヘルパーメソッド実装
- [ ] 後方互換性維持

### 3.2 年齢適応システム実装

#### T2-004: 年齢適応UIコンフィグ [優先度: 高] [工数: 1日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/presentation/config/age_adaptive_ui_config.dart`
```dart
// 年齢グループ別UIパラメータ
// - フォントサイズ、色使い、パディング
// - 説明レベル設定
// - アクセシビリティ設定
```
**依存**: T2-001
**受入条件**:
- [ ] 5年齢グループの完全設定
- [ ] UIパラメータの適切な差別化
- [ ] 設定の動的切替が可能

#### T2-005: 年齢適応説明処理 [優先度: 高] [工数: 1.5日] 【進捗: 完了（Service実装）】
**ファイル**: `lib/features/makeup/presentation/utils/age_adaptive_explanation.dart`
```dart
// 年齢に応じた説明文生成
// - 専門用語の平易化
// - 説明詳細度の調整
// - 実用的アドバイス追加
```
**依存**: T2-004
**受入条件**:
- [ ] 年齢に適した説明文生成
- [ ] 専門用語の適切な変換
- [ ] 説明長の年齢適応

### 3.3 ステップ表示UI実装

#### T2-006: MakeupStepCardウィジェット [優先度: 高] [工数: 2日] 【進捗: 部分完了（Steps内で実装）】
**ファイル**: `lib/features/makeup/presentation/widgets/makeup_step_card.dart`
```dart
// ステップ表示カード
// - 年齢適応レイアウト
// - 展開・折りたたみ機能
// - ハイライト連動タップ
```
**依存**: T2-005, T1-006
**受入条件**:
- [ ] カード形式での美しい表示
- [ ] 年齢適応UIの適用
- [ ] タップでハイライト連動
- [ ] スムーズなアニメーション

#### T2-007: MakeupStepsWidget統合 [優先度: 高] [工数: 1日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/presentation/widgets/makeup_steps_widget.dart`
```dart
// ステップ群の統合管理
// - 複数ステップの順序表示
// - プログレス表示
// - セクション分け
```
**依存**: T2-006
**受入条件**:
- [ ] ステップの順序正しい表示
- [ ] セクション間の明確な区切り
- [ ] 動的ステップ数への対応

### 3.4 パーソナルカラー説明実装

#### T2-008: PersonalColorExplanationWidget [優先度: 中] [工数: 1.5日] 【進捗: 完了（別名Widget実装）】
**ファイル**: `lib/features/makeup/presentation/widgets/personal_color_explanation_widget.dart`
```dart
// パーソナルカラー理論説明
// - 年齢適応説明
// - 視覚的な説明補助
// - 実践的アドバイス
```
**依存**: T2-005
**受入条件**:
- [x] 理論と実践のバランス良い説明
- [x] 年齢に適した内容調整
- [x] 読みやすいレイアウト

### 3.5 データ統合・API連携

#### T2-009: APIモデル更新 [優先度: 高] [工数: 1日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/data/models/ai_makeup_recommendation_model.dart`
```dart
// Phase 2新機能のAPI連携
// - stepByStepInstructions配列パース
// - 年齢推定データの処理
// - エラーハンドリング強化
```
**依存**: T2-003
**受入条件**:
- [x] 新APIフィールドの正常パース
- [x] 不完全データの適切な処理
- [x] API仕様変更への柔軟性

#### T2-010: Provider機能拡張 [優先度: 高] [工数: 1日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart`
```dart
// Phase 2対応のProvider更新
// - 年齢推定状態管理
// - ステップ表示状態管理
// - ハイライト連動制御
```
**依存**: T2-009, T2-007
**受入条件**:
- [x] 年齢適応機能の状態管理
- [x] ステップ・ハイライト連動
- [x] エラー状態の詳細管理

### 3.6 メインページ統合更新

#### T2-011: AIMakeupRecommendationPageV3更新 [優先度: 高] [工数: 1.5日] 【進捗: 未着手】
**ファイル**: `lib/features/makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart`
```dart
// Phase 2機能統合
// - 新Widgetの配置
// - スクロール性能最適化
// - レイアウト全体調整
```
**依存**: T2-007, T2-008, T2-010
**受入条件**:
- [ ] 全Phase 2機能が統合表示
- [ ] スクロール性能の維持
- [ ] 情報密度の適切な調整

### 3.7 Phase 2 統合・最適化

#### T2-012: 統合テスト・パフォーマンス調整 [優先度: 中] [工数: 2日] 【進捗: 未着手】
**対象**: Phase 2全機能
```dart
// 統合テスト・最適化
// - 年齢適応機能の統合テスト
// - UIパフォーマンス調整
// - メモリ使用量最適化
```
**依存**: T2-011
**受入条件**:
- [ ] 年齢適応が全機能で正常動作
- [ ] 30秒読み込み要件継続達成
- [ ] UI操作レスポンス1秒以内
- [ ] メモリリークなし

## 4. Phase 3: 商品推薦機能

### 4.1 商品データモデル拡張

#### T3-001: MakeupProductエンティティ拡張 [優先度: 高] [工数: 0.5日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/domain/entities/makeup_product.dart`
```dart
// 新規フィールド追加:
// - imageUrl, amazonUrl, colors[]
// - ageGroup, difficultyLevel
```
**依存**: なし
**受入条件**:
- [x] 商品購入リンク・画像URL対応
- [x] 年齢グループ・難易度レベル管理
- [x] 後方互換性維持

#### T3-002: 商品推薦エンティティ作成 [優先度: 高] [工数: 0.5日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/domain/entities/product_recommendation.dart`
```dart
// ProductRecommendation エンティティ
// - personalColorType, ageGroup, gender
// - recommendedProducts[]
// - recommendationReason
```
**依存**: T3-001
**受入条件**:
- [x] 推薦理由の説明文管理
- [x] フィルタリング条件の明確化
- [x] 推薦商品リストの構造化

### 4.2 商品推薦API統合

#### T3-003: 商品推薦API設計 [優先度: 高] [工数: 1日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/data/datasources/product_recommendation_remote_data_source.dart`
```dart
// 商品推薦API連携
// - パーソナルカラー×年齢×性別でのフィルタリング
// - makeup_products2.json 読み込み・変換
```
**依存**: T3-002
**受入条件**:
- [x] 診断結果からの商品推薦取得
- [x] 年齢・性別適応フィルタリング
- [x] エラーハンドリング実装

#### T3-004: Repository・UseCase実装 [優先度: 高] [工数: 1日] 【進捗: 完了】
**ファイル**:
- `lib/features/makeup/domain/usecases/get_product_recommendations.dart`
- `lib/features/makeup/data/repositories/product_recommendation_repository_impl.dart`
```dart
// Clean Architecture対応
// - GetProductRecommendations UseCase
// - Repository パターン実装
```
**依存**: T3-003
**受入条件**:
- [x] Clean Architecture準拠
- [x] 商品推薦ビジネスロジック分離
- [x] テスタブルな構造

### 4.3 商品推薦UI実装

#### T3-005: ProductRecommendationPage作成 [優先度: 高] [工数: 2日] 【進捗: 部分完了】
**ファイル**: `lib/features/makeup/presentation/pages/product_recommendation_page.dart`
```dart
// メイン商品推薦画面
// - 診断結果表示セクション
// - 推薦商品一覧セクション
// - Amazon購入リンク連携
```
**依存**: T3-004
**受入条件**:
- [x] 診断結果の要約表示
- [x] 商品カード形式での一覧表示
- [x] 外部ブラウザでのAmazon遷移
- [x] 年齢適応UI適用

#### T3-006: ProductCardWidget作成 [優先度: 高] [工数: 1.5日] 【進捗: 部分完了】
**ファイル**: `lib/features/makeup/presentation/widgets/product_card_widget.dart`
```dart
// 商品カードウィジェット
// - 商品画像・価格・ブランド表示
// - Amazon購入ボタン
// - カラーバリエーション表示
```
**依存**: T3-005
**受入条件**:
- [x] 商品情報の視認性良い表示
- [x] タップでAmazon購入画面遷移
- [x] カラー情報の分かりやすい表示
- [ ] 年齢適応デザイン

#### T3-007: 診断結果画面統合 [優先度: 高] [工数: 1日] 【進捗: 部分完了】
**ファイル**: `lib/features/diagnosis/presentation/pages/diagnosis_result_page.dart`
```dart
// 既存診断結果画面に商品推薦ボタン追加
// - 「おすすめ商品を見る」ボタン
// - 商品推薦画面への遷移
```
**依存**: T3-005
**受入条件**:
- [x] 診断結果画面に自然にボタン配置
- [x] 診断データの商品推薦画面への引き継ぎ
- [x] スムーズなページ遷移

### 4.4 Provider・状態管理

#### T3-008: ProductRecommendationProvider実装 [優先度: 高] [工数: 1日] 【進捗: 完了】
**ファイル**: `lib/features/makeup/presentation/providers/product_recommendation_provider.dart`
```dart
// 商品推薦状態管理
// - 推薦データ取得・キャッシュ
// - 読み込み・エラー状態管理
// - 商品フィルタリング状態
```
**依存**: T3-004, T3-006
**受入条件**:
- [x] 非同期データ取得の適切な状態管理
- [x] エラー状態の適切な通知
- [x] 商品データのメモリ効率的管理

### 4.5 Phase 3統合・テスト

#### T3-009: 統合テスト・パフォーマンス調整 [優先度: 中] [工数: 2日] 【進捗: 未着手】
**対象**: Phase 3全機能
```dart
// 統合テスト・最適化
// - 診断→商品推薦の完全フロー
// - 商品画像読み込み最適化
// - Amazon遷移テスト
```
**依存**: T3-008
**受入条件**:
- [ ] 診断結果から商品推薦までの完全フロー
- [ ] 商品画像の効率的読み込み
- [ ] 外部リンク遷移の正常動作
- [ ] 30秒読み込み要件継続達成

## 5. サポートタスク

### 4.1 テスト実装

#### T-TEST-001: 単体テスト充実化 [優先度: 中] [工数: 1.5日] 【進捗: 未着手】
**範囲**: 全新規エンティティ・ユーティリティ
**受入条件**:
- [ ] テストカバレッジ85%以上
- [ ] エッジケース網羅
- [ ] モック活用

#### T-TEST-002: ウィジェットテスト [優先度: 中] [工数: 2日] 【進捗: 未着手】
**範囲**: 全新規ウィジェット
**受入条件**:
- [ ] 主要ウィジェットの表示テスト
- [ ] インタラクションテスト
- [ ] 年齢適応UIテスト

### 4.2 ドキュメント・設定

#### T-DOC-001: README更新 [優先度: 低] [工数: 0.5日] 【進捗: 未着手】
**ファイル**: `README.md`
**受入条件**:
- [ ] 新機能の説明追加
- [ ] 使用方法の更新

#### T-CONFIG-001: 国際化準備 [優先度: 低] [工数: 1日] 【進捗: 未着手】
**ファイル**: `lib/l10n/`
**受入条件**:
- [ ] 文字列リソースの外部化
- [ ] 多言語化基盤構築

## 5. 工数・スケジュール

### 5.1 工数サマリー
- **Phase 1**: 11日 (データモデル2日 + UI4日 + 統合5日)
- **Phase 2**: 12日 (データモデル2日 + UI6日 + 統合4日)
- **テスト**: 3.5日
- **サポート**: 1.5日
- **総計**: 28日

### 5.2 推奨実装順序
```
Week 1: T1-001~003 (データモデル) → T1-004~005 (Before/After UI)
Week 2: T1-006~007 (ハイライト) → T1-008~009 (統合)
Week 3: T1-010~011 (テスト・最適化) → T2-001~003 (Phase 2データ)
Week 4: T2-004~006 (年齢適応・ステップUI)
Week 5: T2-007~010 (統合・API) → T2-011 (ページ更新)
Week 6: T2-012 (最終統合) + テスト・ドキュメント
```

### 5.3 並行実行可能タスク
- T1-004とT1-005 (UI実装)
- T2-004とT2-005 (年齢適応システム)
- テストタスクは各Phase完了後に並行実行

## 6. リスク・対策

### 6.1 技術リスク
| リスク | 影響 | 対策 |
|--------|------|------|
| ハイライト描画性能 | 中 | CustomPainter最適化、GPU活用 |
| 年齢推定精度 | 低 | デフォルト値設定、手動調整機能 |
| メモリ使用量増加 | 高 | 段階的読み込み、効率的キャッシュ |
| API応答時間 | 中 | タイムアウト設定、プログレス表示 |

### 6.2 スケジュールリスク
| リスク | 影響 | 対策 |
|--------|------|------|
| UI調整に時間超過 | 中 | MVP機能優先、段階的改善 |
| 年齢適応調整複雑化 | 中 | シンプルな分類から開始 |
| 統合テスト時間不足 | 高 | 開発中のユニットテスト充実 |

## 7. 成功指標

### 7.1 Phase 1完了指標
- [ ] Before/After画像が30秒以内に表示完了
- [ ] ハイライト機能が正常動作（全形状・アニメーション）
- [ ] メモリ使用量50MB以下を維持
- [ ] 主要デバイスで60FPS動作

### 7.2 Phase 2完了指標
- [ ] 年齢推定→UI適応が1秒以内
- [ ] 5年齢グループの適切な差別化表示
- [ ] ステップ・ハイライト連動が正常動作
- [ ] ユーザビリティテストで4.0/5.0以上

### 7.3 最終成功指標
- [ ] アプリストア申請で問題なし
- [ ] 画面滞在時間+50%達成
- [ ] クラッシュ率0.1%以下
- [ ] ユーザー満足度調査で好評価

---

**作成日**: 2025-09-14
**バージョン**: 1.0
**作成者**: AI Assistant
**総工数見積**: 28日
**推奨チーム**: 2名（フロントエンド、バックエンド兼務）
