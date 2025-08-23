# ディザーサイト テスト設計書

## 1. テスト戦略

### 1.1 テスト目的
- App Store Connect申請に必要な品質基準の確保
- ユーザー体験の品質保証
- セキュリティとプライバシーの確保
- パフォーマンス要件の達成

### 1.2 テストレベル
1. **ユニットテスト**: コンポーネント・関数レベル
2. **統合テスト**: ページ・フォーム機能レベル
3. **E2Eテスト**: ユーザーシナリオレベル
4. **手動テスト**: UI/UX・アクセシビリティ

### 1.3 テスト環境
- **開発環境**: localhost:3000
- **ステージング環境**: Vercel Preview
- **本番環境**: 独自ドメイン

## 2. 機能テスト設計

### 2.1 ページ表示テスト

#### 2.1.1 トップページ (/)
**テストケース: TOP-001**
```
目的: トップページの正常表示確認
前提条件: ブラウザでサイトにアクセス
テスト手順:
1. ルートURL（/）にアクセス
2. ページの読み込み完了を確認
3. 各セクションの表示を確認

期待結果:
- ページが3秒以内に読み込まれる
- Hero Section、Features、Screenshots、Footer が表示される
- App Storeボタンが表示される
- レスポンシブレイアウトが正しく動作する
```

**テストケース: TOP-002**
```
目的: App Storeボタンの動作確認
前提条件: トップページが表示されている
テスト手順:
1. App Storeボタンをクリック
2. リンク先の確認

期待結果:
- App Storeの該当ページに遷移する
- 新しいタブで開く
```

#### 2.1.2 プライバシーポリシーページ (/privacy-policy)
**テストケース: PP-001**
```
目的: プライバシーポリシーページの表示確認
前提条件: ブラウザでサイトにアクセス可能
テスト手順:
1. /privacy-policy にアクセス
2. ページコンテンツの確認
3. 目次リンクの動作確認

期待結果:
- プライバシーポリシーの全文が表示される
- 目次から各セクションにジャンプできる
- パンくずリストが正しく表示される
- 最終更新日が表示される
```

#### 2.1.3 サポートページ (/support)
**テストケース: SUP-001**
```
目的: サポートページの表示確認
前提条件: ブラウザでサイトにアクセス可能
テスト手順:
1. /support にアクセス
2. FAQ表示の確認
3. お問い合わせフォーム表示の確認

期待結果:
- FAQ一覧が表示される
- 各FAQ項目をクリックで展開/折りたたみできる
- お問い合わせフォームが表示される
```

### 2.2 フォーム機能テスト

#### 2.2.1 お問い合わせフォーム基本機能
**テストケース: FORM-001**
```
目的: 正常なフォーム送信の確認
前提条件: サポートページのフォームが表示されている
テストデータ:
- 名前: テスト太郎
- メール: test@example.com
- 件名: アプリの使用方法について
- 内容: テストメッセージです（20文字以上）

テスト手順:
1. 各項目に上記データを入力
2. 送信ボタンをクリック
3. 送信完了の確認

期待結果:
- フォーム送信が正常に完了する
- 成功メッセージが表示される
- 指定メールアドレスに問い合わせが届く
```

**テストケース: FORM-002**
```
目的: バリデーションエラーの確認
前提条件: サポートページのフォームが表示されている
テストデータ（不正データ）:
- 名前: （空文字）
- メール: invalid-email
- 件名: （選択なし）
- 内容: 短い

テスト手順:
1. 上記不正データを入力
2. 送信ボタンをクリック
3. エラーメッセージの確認

期待結果:
- 送信が阻止される
- 各項目に適切なエラーメッセージが表示される
- フォーカスが最初のエラー項目に移動する
```

#### 2.2.2 フォームセキュリティテスト
**テストケース: FORM-SEC-001**
```
目的: XSS攻撃対策の確認
前提条件: フォームが表示されている
テストデータ:
- 内容: <script>alert('xss')</script>

テスト手順:
1. 上記スクリプトタグを内容欄に入力
2. 送信ボタンをクリック

期待結果:
- スクリプトが実行されない
- 適切にエスケープ処理される
```

## 3. UI/UXテスト設計

### 3.1 レスポンシブデザインテスト

#### 3.1.1 デバイス別表示テスト
**テストケース: RWD-001**
```
目的: モバイルデバイスでの表示確認
テスト環境:
- iPhone SE (375px幅)
- iPhone 14 Pro (393px幅)
- Android (360px幅)

テスト手順:
1. 各デバイスサイズでサイト表示
2. 全ページのレイアウト確認
3. タッチ操作の確認

期待結果:
- レイアウトが崩れない
- 文字サイズが適切
- ボタンのタッチ領域が44px以上
- 横スクロールが発生しない
```

**テストケース: RWD-002**
```
目的: タブレットでの表示確認
テスト環境: iPad (768px幅)

期待結果:
- 2カラムレイアウトが適用される
- 画像とテキストのバランスが良い
- ナビゲーションが適切に動作する
```

**テストケース: RWD-003**
```
目的: デスクトップでの表示確認
テスト環境: 1024px以上の幅

期待結果:
- 最大幅制限が適用される
- 横並びレイアウトが活用される
- 余白が適切に配置される
```

### 3.2 アクセシビリティテスト

#### 3.2.1 キーボードナビゲーション
**テストケース: A11Y-001**
```
目的: キーボード操作での利用確認
テスト手順:
1. Tabキーでの要素間移動
2. Enterキーでのリンク・ボタン操作
3. フォーム要素での操作

期待結果:
- 論理的な順序で要素間移動できる
- フォーカス表示が明確
- すべての操作がキーボードで可能
```

#### 3.2.2 スクリーンリーダー対応
**テストケース: A11Y-002**
```
目的: スクリーンリーダーでの読み上げ確認
ツール: VoiceOver (macOS) / NVDA (Windows)

テスト項目:
- 見出し構造の確認 (h1, h2, h3)
- 画像のalt属性
- フォームラベルの関連付け
- ARIA属性の適切な使用

期待結果:
- 内容が論理的な順序で読み上げられる
- 画像に適切な代替テキストがある
- フォーム項目の目的が明確
```

### 3.3 ユーザビリティテスト

#### 3.3.1 ナビゲーションテスト
**テストケース: UX-001**
```
目的: サイト内移動の使いやすさ確認
テストシナリオ:
1. トップページからプライバシーポリシーへ移動
2. サポートページからトップページへ戻る
3. App Storeリンクの見つけやすさ

期待結果:
- 3クリック以内で目的ページに到達
- パンくずリストで現在位置が分かる
- メインCTAが明確に識別できる
```

#### 3.3.2 情報の見つけやすさテスト
**テストケース: UX-002**
```
目的: 重要情報へのアクセスしやすさ
テストタスク:
- プライバシーポリシーの特定項目を見つける
- よくある質問の答えを見つける
- お問い合わせ方法を見つける

期待結果:
- 目次やFAQで素早く情報に到達できる
- 検索性の高いレイアウト
- 重要情報が適切にハイライトされている
```

## 4. パフォーマンステスト設計

### 4.1 ページ読み込み速度テスト

#### 4.1.1 Core Web Vitals
**テストケース: PERF-001**
```
測定ツール: Lighthouse, WebPageTest
測定項目:
- Largest Contentful Paint (LCP): 2.5秒以下
- First Input Delay (FID): 100ms以下
- Cumulative Layout Shift (CLS): 0.1以下

テスト条件:
- 3G回線シミュレーション
- モバイルデバイス
- デスクトップ

期待結果:
- 全項目でGood評価を達成
- Lighthouse Performance Score 90以上
```

#### 4.1.2 画像最適化テスト
**テストケース: PERF-002**
```
目的: 画像読み込みの最適化確認
確認項目:
- WebP形式での配信
- 適切なサイズでの読み込み
- 遅延読み込みの動作

期待結果:
- 次世代フォーマットで画像が配信される
- 画面サイズに応じた最適サイズ
- スクロール時に画像が読み込まれる
```

### 4.2 ネットワーク負荷テスト

**テストケース: PERF-003**
```
目的: 低速ネットワークでの動作確認
テスト条件:
- Slow 3G (400kbps)
- Fast 3G (1.6Mbps)

期待結果:
- 低速環境でも10秒以内に読み込み完了
- プログレッシブ読み込みが機能
- 重要コンテンツが優先的に表示
```

## 5. セキュリティテスト設計

### 5.1 入力値検証テスト

**テストケース: SEC-001**
```
目的: 各種インジェクション攻撃への対策確認
テスト項目:
- SQLインジェクション（該当する場合）
- XSSインジェクション
- コマンドインジェクション

テストデータ例:
- <script>alert('XSS')</script>
- '; DROP TABLE users; --
- ../../../etc/passwd

期待結果:
- 悪意のあるスクリプトが実行されない
- 適切にサニタイズされる
- エラーが適切にハンドリングされる
```

### 5.2 プライバシー保護テスト

**テストケース: SEC-002**
```
目的: 個人情報の適切な取り扱い確認
確認項目:
- フォーム送信時の暗号化
- 不要なデータの収集がないこと
- クッキーの適切な設定

期待結果:
- HTTPS通信が強制される
- 最小限の情報のみ収集
- セキュアなクッキー設定
```

## 6. ブラウザ互換性テスト

### 6.1 対応ブラウザテスト

**テストケース: BROWSER-001**
```
目的: 主要ブラウザでの動作確認
テスト対象:
- Safari (iOS) - 最新版および1つ前のバージョン
- Chrome (Android/PC) - 最新版
- Firefox (PC) - 最新版
- Edge (PC) - 最新版

テスト項目:
- 基本機能の動作
- レイアウトの表示
- フォーム送信機能
- JavaScript機能

期待結果:
- 全ブラウザで基本機能が正常動作
- レイアウト崩れがない
- パフォーマンスに大きな差がない
```

## 7. SEOテスト設計

### 7.1 検索エンジン最適化テスト

**テストケース: SEO-001**
```
目的: 検索エンジンでの認識確認
確認項目:
- titleタグの適切性
- meta descriptionの設定
- 見出しタグの階層構造 (h1, h2, h3)
- 構造化データの実装
- sitemap.xmlの生成

期待結果:
- Google Search Consoleでのクロール成功
- 主要キーワードでの検索性
- ソーシャルシェア時の適切な表示
```

## 8. テスト自動化設計

### 8.1 ユニットテスト (Jest + React Testing Library)

```typescript
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '@/components/ui/Button';

describe('Button', () => {
  test('renders button with correct text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  test('handles click events', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

### 8.2 E2Eテスト (Playwright)

```typescript
// e2e/contact-form.spec.ts
import { test, expect } from '@playwright/test';

test('contact form submission', async ({ page }) => {
  await page.goto('/support');
  
  // フォーム入力
  await page.fill('[name="name"]', 'テスト太郎');
  await page.fill('[name="email"]', 'test@example.com');
  await page.selectOption('[name="subject"]', 'usage');
  await page.fill('[name="message"]', 'テストメッセージです');
  
  // 送信
  await page.click('[type="submit"]');
  
  // 成功メッセージの確認
  await expect(page.locator('.success-message')).toBeVisible();
});
```

### 8.3 Visual Regression Testing

```typescript
// e2e/visual.spec.ts
import { test, expect } from '@playwright/test';

test('visual regression - homepage', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png');
});

test('visual regression - mobile', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage-mobile.png');
});
```

## 9. テスト実行計画

### 9.1 テストフェーズ

1. **開発中テスト**: ユニットテスト、コンポーネントテスト
2. **統合テスト**: ページ間連携、フォーム機能
3. **システムテスト**: E2Eテスト、パフォーマンステスト
4. **受け入れテスト**: 手動テスト、ユーザビリティテスト

### 9.2 テスト環境と実行スケジュール

```
Development → Staging → Production
     ↓           ↓         ↓
  Unit Tests  Integration  Manual
  Component   E2E Tests    Acceptance
  Tests       Performance  Testing
              Security
```

### 9.3 品質ゲート

**デプロイ前の必須条件:**
- [ ] 全ユニットテストが通過
- [ ] E2Eテストが通過
- [ ] Lighthouse Performance Score 90以上
- [ ] アクセシビリティスコア 90以上
- [ ] 手動テスト項目のクリア
- [ ] セキュリティチェックのクリア

## 10. 不具合管理

### 10.1 重要度分類
- **Critical**: サイトが表示されない、フォーム送信ができない
- **High**: レイアウト崩れ、主要機能の不具合
- **Medium**: マイナーなUI問題、パフォーマンス問題
- **Low**: テキストの誤字、非主要ブラウザでの軽微な問題

### 10.2 テスト報告書テンプレート

```markdown
## テスト実行報告書

**実行日**: YYYY-MM-DD
**環境**: Development/Staging/Production
**担当者**: [名前]

### 実行結果
- 実行テストケース数: XX件
- 成功: XX件
- 失敗: XX件
- スキップ: XX件

### 発見された不具合
| ID | 重要度 | 概要 | 状況 |
|----|--------|------|------|
| BUG-001 | High | フォーム送信エラー | 修正中 |

### 推奨事項
- [改善提案]
```

---

## 付録

### A. テストツール
- **ユニット**: Jest, React Testing Library
- **E2E**: Playwright
- **パフォーマンス**: Lighthouse, WebPageTest
- **アクセシビリティ**: axe-core, Pa11y
- **Visual**: Playwright Screenshots

### B. テストデータ
- 有効なテストメールアドレス
- 各種ブラウザの最新版情報
- パフォーマンス基準値

### C. 参考資料
- WCAG 2.1 Guidelines
- Core Web Vitals documentation
- Next.js testing best practices