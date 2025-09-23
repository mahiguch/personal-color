# おすすめメイク画面改善 - 設計書

## 1. 概要

### 1.1 設計目的
要件定義書に基づき、おすすめメイク画面の具体的な技術設計、UI/UX設計、データ設計を定義する。

### 1.2 設計方針
- **段階的実装**: Phase 1 → Phase 2 → Phase 3 の順次実装
- **Clean Architecture**: 既存のDDD構造に準拠
- **レスポンシブデザイン**: 様々な画面サイズに対応
- **パフォーマンス重視**: 30秒以内の読み込み時間達成

## 2. システム アーキテクチャ設計

### 2.1 全体構成図
```
┌─────────────────────────────────────┐
│ Presentation Layer                  │
│ ┌─────────────────────────────────┐ │
│ │ AIMakeupRecommendationPageV3    │ │
│ │ - BeforeAfterWidget            │ │
│ │ - HighlightOverlayWidget       │ │
│ │ - MakeupStepsWidget            │ │
│ │ - PersonalColorExplanation     │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ Domain Layer                        │
│ ┌─────────────────────────────────┐ │
│ │ Enhanced MakeupRecommendation   │ │
│ │ - AgeEstimation                │ │
│ │ - MakeupStep[]                 │ │
│ │ - HighlightArea[]              │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ Data Layer                          │
│ ┌─────────────────────────────────┐ │
│ │ Enhanced API Response           │ │
│ │ + estimatedAge                 │ │
│ │ + stepByStepInstructions       │ │
│ │ + highlightAreas               │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 2.2 既存システムとの関係
- **既存APIエンドポイント**: 変更せず、レスポンス項目を追加
- **既存エンティティ**: `MakeupRecommendation`を拡張
- **既存Provider**: `AIMakeupRecommendationProvider`を機能拡張

## 3. データ設計

### 3.1 強化されたMakeupRecommendationエンティティ

```dart
class MakeupRecommendation extends Equatable {
  const MakeupRecommendation({
    // 既存フィールド
    required this.personalColorType,
    required this.categories,
    required this.aiExplanations,
    this.requestId,
    this.timestamp,
    this.generatedImageData,
    this.generatedImageSize,
    this.generatedImageDateTime,

    // 新規追加フィールド (Phase 1&2)
    this.estimatedAge,
    this.ageGroup,
    this.makeupExperienceLevel,
    this.stepByStepInstructions,
    this.highlightAreas,
    this.personalColorExplanation,

    // 将来拡張フィールド (Phase 3)
    this.veo3VideoUrl,
  });

  // 既存フィールド
  final PersonalColorType personalColorType;
  final Map<MakeupCategory, List<MakeupProduct>> categories;
  final Map<MakeupCategory, String> aiExplanations;
  final String? requestId;
  final DateTime? timestamp;
  final String? generatedImageData;
  final String? generatedImageSize;
  final DateTime? generatedImageDateTime;

  // 新規フィールド
  final int? estimatedAge;                              // 推定年齢
  final AgeGroup? ageGroup;                            // 年齢グループ
  final MakeupExperienceLevel? makeupExperienceLevel; // 経験レベル
  final List<MakeupStep>? stepByStepInstructions;     // ステップ手順
  final List<HighlightArea>? highlightAreas;          // ハイライト領域
  final String? personalColorExplanation;             // パーソナルカラー説明
  final String? veo3VideoUrl;                         // 動画URL (Phase 3)
}
```

### 3.2 新規データモデル

#### 3.2.1 年齢グループと経験レベル
```dart
enum AgeGroup {
  child,      // 8-12歳: 子供らしい特徴
  student,    // 13-22歳: 若々しい特徴
  adult,      // 23-39歳: 成人の特徴
  middleAge,  // 40-59歳: 中高年の特徴
  senior;     // 60歳以上: シニアの特徴
}

enum MakeupExperienceLevel {
  beginner,     // 初心者
  intermediate, // 中級者
  advanced;     // 上級者
}
```

#### 3.2.2 メイクステップ
```dart
class MakeupStep extends Equatable {
  const MakeupStep({
    required this.stepNumber,
    required this.category,
    required this.instruction,
    required this.ageAppropriateInstruction,
    this.tips,
    this.estimatedDuration,
    this.difficultyLevel,
    this.relatedHighlightAreaIds,
  });

  final int stepNumber;                          // ステップ番号 (1,2,3...)
  final MakeupCategory category;                 // カテゴリ
  final String instruction;                      // 基本説明
  final String ageAppropriateInstruction;       // 年齢適応説明
  final String? tips;                           // コツ・ポイント
  final Duration? estimatedDuration;            // 推定所要時間
  final DifficultyLevel? difficultyLevel;      // 難易度
  final List<String>? relatedHighlightAreaIds; // 関連ハイライトID

  @override
  List<Object?> get props => [
    stepNumber, category, instruction, ageAppropriateInstruction,
    tips, estimatedDuration, difficultyLevel, relatedHighlightAreaIds,
  ];
}

enum DifficultyLevel { easy, medium, hard }
```

#### 3.2.3 ハイライト領域
```dart
class HighlightArea extends Equatable {
  const HighlightArea({
    required this.id,
    required this.type,
    required this.coordinates,
    this.color,
    this.opacity,
    this.animationType,
  });

  final String id;                    // 一意識別子
  final HighlightType type;          // ハイライト種別
  final HighlightCoordinates coordinates; // 座標情報
  final Color? color;                // ハイライト色 (デフォルト: テーマ色)
  final double? opacity;             // 透明度 (0.0-1.0, デフォルト: 0.3)
  final AnimationType? animationType; // アニメーション種別

  @override
  List<Object?> get props => [id, type, coordinates, color, opacity, animationType];
}

enum HighlightType {
  eye,        // アイメイク
  eyebrow,    // 眉毛
  cheek,      // チーク
  lip,        // リップ
  nose,       // ノーズシャドウ
  contour;    // コンター
}

class HighlightCoordinates extends Equatable {
  const HighlightCoordinates({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.shape = HighlightShape.rectangle,
  });

  final double x;      // X座標 (相対座標 0.0-1.0)
  final double y;      // Y座標 (相対座標 0.0-1.0)
  final double width;  // 幅 (相対サイズ 0.0-1.0)
  final double height; // 高さ (相対サイズ 0.0-1.0)
  final HighlightShape shape; // 形状

  @override
  List<Object?> get props => [x, y, width, height, shape];
}

enum HighlightShape { rectangle, circle, oval }
enum AnimationType { none, fade, pulse, glow }
```

### 3.3 API レスポンス設計

```json
{
  // 既存フィールド
  "personalColorType": "spring",
  "categories": { /* 既存構造 */ },
  "aiExplanations": { /* 既存構造 */ },
  "generatedImageData": "base64string...",

  // 新規追加フィールド
  "estimatedAge": 25,
  "ageGroup": "adult",
  "makeupExperienceLevel": "intermediate",
  "stepByStepInstructions": [
    {
      "stepNumber": 1,
      "category": "eyeshadow",
      "instruction": "アイシャドウベースを薄く塗る",
      "ageAppropriateInstruction": "大人の方は、より自然なグラデーションを意識して...",
      "tips": "ブラシは大きめを使用すると失敗しにくいです",
      "estimatedDuration": "PT2M",
      "difficultyLevel": "easy",
      "relatedHighlightAreaIds": ["eye_base_1"]
    }
  ],
  "highlightAreas": [
    {
      "id": "eye_base_1",
      "type": "eye",
      "coordinates": {
        "x": 0.35,
        "y": 0.25,
        "width": 0.15,
        "height": 0.08,
        "shape": "oval"
      },
      "color": null,
      "opacity": 0.4,
      "animationType": "fade"
    }
  ],
  "personalColorExplanation": "あなたのSpringタイプは、暖かく明るい色が特に似合います。今回のメイクでは...",
  "veo3VideoUrl": null
}
```

## 4. UI/UX設計

### 4.1 画面レイアウト設計

#### 4.1.1 全体構成 (縦スクロール対応)
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ AppBar: AI画像生成メイク               ┃ 56dp
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Section 1: Before/After Images       ┃ 280dp
┃ ┌─────────────────┬─────────────────┐ ┃
┃ │   Before        │    After        │ ┃
┃ │   (45%)         │    (45%)        │ ┃
┃ │   📸            │    🎨           │ ┃
┃ └─────────────────┴─────────────────┘ ┃
┃ [ハイライト ON/OFF]    [🔄 比較表示]   ┃ 48dp
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Section 2: Makeup Steps              ┃ ~400dp
┃                                      ┃
┃ 🎨 メイク手順                         ┃
┃                                      ┃
┃ ┌─ Step 1: アイシャドウ ─────────────┐ ┃
┃ │ 👁️ アイシャドウベースを薄く塗る      │ ┃
┃ │ 💡 大人の方は、より自然な...        │ ┃
┃ │ ⏱️ 約2分 | 📊 初級                 │ ┃
┃ └─────────────────────────────────┘ ┃
┃                                      ┃
┃ ┌─ Step 2: チーク ─────────────────┐ ┃
┃ │ 🌸 チークを頬の高い位置に...        │ ┃
┃ └─────────────────────────────────┘ ┃
┃                                      ┃
┃ ┌─ Step 3: リップ ─────────────────┐ ┃
┃ │ 💋 リップカラーを全体に...          │ ┃
┃ └─────────────────────────────────┘ ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Section 3: Personal Color Theory     ┃ ~200dp
┃                                      ┃
┃ 💡 あなたのパーソナルカラーについて      ┃
┃                                      ┃
┃ あなたのSpringタイプは、暖かく明るい色が ┃
┃ 特に似合います。今回のメイクでは...     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

#### 4.1.2 Before/After画像セクション詳細
```
┌─────────────────────────────────────────────────┐
│                Before/After Images              │
│ ┌──────────────────┐ 5% ┌──────────────────────┐│
│ │                  │gap │                      ││
│ │     Before       │    │       After          ││ 縦長画像
│ │    (45%)        │    │       (45%)         ││ アスペクト比
│ │                  │    │                      ││ 3:4 推奨
│ │       📸         │    │        🎨            ││
│ │                  │    │                      ││
│ └──────────────────┘    └──────────────────────┘│
│                                                 │
│ ┌─ Highlight Controls ──────────────────────────┐│
│ │ [✅ ハイライト表示]  [🔄 スワイプ比較]        ││
│ └─────────────────────────────────────────────── ┘│
└─────────────────────────────────────────────────┘
```

### 4.2 ウィジェット設計

#### 4.2.1 メインウィジェット構成
```dart
AIMakeupRecommendationPageV3
├── ScrollableColumn
    ├── BeforeAfterComparisonWidget
    │   ├── BeforeImageWidget
    │   ├── AfterImageWidget
    │   └── HighlightOverlayWidget
    ├── HighlightControlsWidget
    ├── MakeupStepsWidget
    │   └── MakeupStepCard[] (動的生成)
    └── PersonalColorExplanationWidget
```

#### 4.2.2 核心ウィジェット詳細設計

**BeforeAfterComparisonWidget**
```dart
class BeforeAfterComparisonWidget extends StatefulWidget {
  final File originalImage;          // Before画像
  final String? generatedImageData;  // After画像 (Base64)
  final List<HighlightArea>? highlights; // ハイライト情報
  final bool showHighlights;         // ハイライト表示フラグ

  // 画像サイズ: 縦長 (3:4比率)
  // 各画像幅: MediaQuery.of(context).size.width * 0.45
}
```

**HighlightOverlayWidget**
```dart
class HighlightOverlayWidget extends StatelessWidget {
  final Size imageSize;              // 画像サイズ
  final List<HighlightArea> highlights; // ハイライト領域
  final bool isVisible;              // 表示状態

  // CustomPainter使用で高精度描画
  // アニメーション: fade, pulse, glow対応
}
```

**MakeupStepCard**
```dart
class MakeupStepCard extends StatelessWidget {
  final MakeupStep step;             // ステップ情報
  final AgeGroup ageGroup;           // 年齢グループ
  final VoidCallback? onHighlightTap; // ハイライト連動

  // カード形式で統一
  // 展開・折りたたみ機能付き
  // タップでハイライト連動
}
```

### 4.3 年齢適応型UI設計

#### 4.3.1 年齢グループ別UIパラメータ
```dart
class AgeAdaptiveUIConfig {
  static UIConfig getConfigForAge(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return UIConfig(
          fontSize: 16.0,           // 大きめフォント
          cardPadding: 20.0,        // ゆったりレイアウト
          primaryColor: Colors.pink[300], // やわらかい色
          explanationLevel: ExplanationLevel.simple,
          showDifficulty: false,    // 難易度非表示
        );

      case AgeGroup.student:
        return UIConfig(
          fontSize: 14.0,
          cardPadding: 16.0,
          primaryColor: Colors.purple[400],
          explanationLevel: ExplanationLevel.moderate,
          showDifficulty: true,
        );

      case AgeGroup.adult:
        return UIConfig(
          fontSize: 14.0,
          cardPadding: 16.0,
          primaryColor: Colors.deepPurple,
          explanationLevel: ExplanationLevel.detailed,
          showDifficulty: true,
        );

      default: // middleAge, senior
        return UIConfig(
          fontSize: 15.0,           // やや大きめ（視認性）
          cardPadding: 18.0,
          primaryColor: Colors.indigo,
          explanationLevel: ExplanationLevel.detailed,
          showDifficulty: true,
        );
    }
  }
}
```

#### 4.3.2 説明文の年齢適応
```dart
class AgeAdaptiveExplanation {
  static String getExplanation(MakeupStep step, AgeGroup ageGroup) {
    // サーバーから age-appropriate instruction を受信
    // クライアントでも補完的な適応処理

    switch (ageGroup) {
      case AgeGroup.child:
        return simplifyExplanation(step.instruction);
      case AgeGroup.student:
        return addTrendInfo(step.ageAppropriateInstruction);
      default:
        return step.ageAppropriateInstruction;
    }
  }

  static String simplifyExplanation(String original) {
    // 専門用語を平易な言葉に置換
    return original
        .replaceAll("グラデーション", "色のぼかし")
        .replaceAll("コンシーラー", "カバー")
        .replaceAll("ハイライト", "明るい色");
  }
}
```

## 5. アニメーション・インタラクション設計

### 5.1 画面遷移アニメーション
```dart
class AnimationConfig {
  // 画像読み込み完了時
  static const Duration imageLoadAnimation = Duration(milliseconds: 500);
  static const Curve imageLoadCurve = Curves.easeInOut;

  // ハイライト表示
  static const Duration highlightFade = Duration(milliseconds: 300);
  static const Duration highlightPulse = Duration(milliseconds: 1200);

  // ステップカード展開
  static const Duration stepExpand = Duration(milliseconds: 250);
}
```

### 5.2 インタラクティブ要素
- **ハイライトON/OFF**: トグルボタンで瞬時切替
- **ステップタップ**: 対応するハイライト領域を強調
- **スワイプ比較**: Before/After画像の重ね合わせ比較（Phase 2で実装）

## 6. パフォーマンス設計

### 6.1 読み込み最適化
```dart
class PerformanceOptimization {
  // 画像の段階的読み込み
  static Future<void> loadImagesProgressively() async {
    // 1. Before画像(ローカル) -> 即座表示
    // 2. After画像(Base64) -> デコード後表示
    // 3. ハイライト情報 -> 画像表示後に適用
  }

  // キャッシュ戦略
  static const Duration imageCacheDuration = Duration(hours: 1);
  static const int maxCacheSize = 50; // MB
}
```

### 6.2 メモリ管理
- Base64画像のメモリ効率的デコード
- 不要なハイライトレイヤーの自動破棄
- スクロール時の遅延レンダリング

## 7. エラーハンドリング設計

### 7.1 エラー状態の分類
```dart
enum MakeupDisplayError {
  imageDecodeError,     // 画像デコード失敗
  ageEstimationFailed,  // 年齢推定失敗
  highlightDataMissing, // ハイライト情報不備
  stepDataIncomplete,   // ステップ情報不完全
  networkTimeout,       // ネットワークタイムアウト
}
```

### 7.2 フォールバック戦略
- **年齢推定失敗**: デフォルト「adult」として処理
- **ハイライト欠如**: ハイライト機能を無効化
- **ステップ不完全**: 利用可能なステップのみ表示
- **画像エラー**: プレースホルダー表示

## 8. テスト設計

### 8.1 単体テスト対象
- `MakeupRecommendation`エンティティの新機能
- `HighlightArea`座標計算
- 年齢適応ロジック
- エラーハンドリング

### 8.2 ウィジェットテスト対象
- `BeforeAfterComparisonWidget`画像表示
- `HighlightOverlayWidget`描画精度
- `MakeupStepCard`年齢適応表示

### 8.3 統合テスト対象
- APIレスポンス → UI表示の完全フロー
- 年齢推定 → コンテンツ適応の動作
- エラー状況での画面表示

## 9. 実装順序

### 9.1 Phase 1: Before/After + ハイライト
1. **データモデル拡張** (2日)
   - `MakeupRecommendation`、`HighlightArea`
   - API応答モデル更新

2. **Before/After UI実装** (3日)
   - `BeforeAfterComparisonWidget`
   - 画像レイアウト・レスポンシブ対応

3. **ハイライト機能実装** (4日)
   - `HighlightOverlayWidget`
   - CustomPainter実装
   - アニメーション追加

4. **統合・テスト** (2日)

### 9.2 Phase 2: メイク解説 + 年齢適応
1. **ステップ機能実装** (3日)
   - `MakeupStep`データモデル
   - `MakeupStepCard`ウィジェット

2. **年齢適応システム実装** (4日)
   - 年齢グループ判定
   - UIコンフィグ適応
   - 説明文適応

3. **パーソナルカラー説明実装** (2日)
   - 理論説明ウィジェット
   - 年齢適応説明

4. **統合・テスト・調整** (3日)

### 9.3 Phase 3: 商品推薦機能
1. **MakeupProductエンティティ拡張** (1日)
   - 商品画像URL、購入リンク等のフィールド追加
   - 年齢グループ・難易度レベル対応

2. **商品推薦API統合** (2日)
   - 診断結果画面からの商品推薦起動
   - パーソナルカラー×年齢×性別での商品フィルタリング
   - makeup_products2.json連携

3. **商品表示UI実装** (3日)
   - ProductRecommendationPageウィジェット
   - 商品カード形式表示
   - Amazon購入リンク外部ブラウザ起動

4. **統合・テスト** (2日)

### 9.4 Phase 4: Veo3動画統合 (将来)
- 動画表示ウィジェット
- Veo3 API統合
- 動画キャッシュ機能

## 10. 非機能要件への対応

### 10.1 パフォーマンス目標達成戦略
- **30秒読み込み**: 段階的表示 + 効率的画像処理
- **1秒レスポンス**: 軽量ウィジェット + 最適化アニメーション

### 10.2 保守性・拡張性
- **Clean Architecture維持**: 各層の責任明確化
- **設定外部化**: UIパラメータのconfig化
- **国際化準備**: 文字列リソース分離

---

**作成日**: 2025-09-14
**バージョン**: 1.0
**作成者**: AI Assistant
**レビュー状況**: Draft
**見積工数**: Phase 1: 11日, Phase 2: 12日, Phase 3: TBD