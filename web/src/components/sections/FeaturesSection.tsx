'use client';

import Image from 'next/image';

export function FeaturesSection() {
  return (
    <section id="features" className="py-20 bg-white">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        {/* セクションヘッダー */}
        <div className="text-center space-y-6 mb-16">
          <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 leading-tight">
            アプリの特徴
          </h2>
        </div>

        {/* Figmaベースの3カラムレイアウト */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* カード1 */}
          <div className="space-y-6">
            <div className="aspect-square bg-gradient-to-br from-primary-100 to-primary-200 rounded-lg overflow-hidden relative">
              <Image
                src="/images/feature-camera-diagnosis.png"
                alt="簡単撮影診断のイメージ"
                fill
                className="object-cover"
                onError={() => {
                  // フォールバック処理は親要素のグラデーション背景で対応
                }}
              />
            </div>
            <div className="space-y-2">
              <h3 className="text-xl font-medium text-gray-900">
                簡単撮影診断
              </h3>
              <p className="text-gray-600 leading-relaxed">
                簡単に使える直感的な操作で、楽しくパーソナルカラー診断ができます。
              </p>
            </div>
          </div>
          
          {/* カード2 */}
          <div className="space-y-6">
            <div className="aspect-square bg-gradient-to-br from-warm-100 to-warm-200 rounded-lg overflow-hidden relative">
              <Image
                src="/images/feature-ai-analysis.png"
                alt="AI色彩分析のイメージ"
                fill
                className="object-cover"
                onError={() => {
                  // フォールバック処理は親要素のグラデーション背景で対応
                }}
              />
            </div>
            <div className="space-y-2">
              <h3 className="text-xl font-medium text-gray-900">
                AI色彩分析
              </h3>
              <p className="text-gray-600 leading-relaxed">
                最新のAI技術で肌色を分析し、最も似合う色を科学的に診断します。
              </p>
            </div>
          </div>
          
          {/* カード3 */}
          <div className="space-y-6">
            <div className="aspect-square bg-gradient-to-br from-cool-100 to-cool-200 rounded-lg overflow-hidden relative">
              <Image
                src="/images/feature-safe-design.png"
                alt="安全設計のイメージ"
                fill
                className="object-cover"
                onError={() => {
                  // フォールバック処理は親要素のグラデーション背景で対応
                }}
              />
            </div>
            <div className="space-y-2">
              <h3 className="text-xl font-medium text-gray-900">
                安全設計
              </h3>
              <p className="text-gray-600 leading-relaxed">
                撮影画像は診断後即座に削除され、プライバシーを完全に保護します。
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
