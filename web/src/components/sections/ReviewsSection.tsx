'use client';

import Image from 'next/image';

export function ReviewsSection() {
  return (
    <section id="reviews" className="py-20 bg-white">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        {/* セクションヘッダー */}
        <div className="text-center space-y-6 mb-20">
          <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 leading-tight">
            利用者の声
          </h2>
        </div>

        {/* Figmaベースのレビューカード - 3カラムレイアウト */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* レビュー1 */}
          <div className="bg-white border border-gray-200 rounded-xl p-8 space-y-6">
            <p className="text-lg text-gray-900 leading-relaxed">
              「自分に似合う色がわかって、おしゃれが楽しくなりました！」
            </p>
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-gradient-to-br from-primary-400 to-primary-500 rounded-full overflow-hidden relative">
                <Image
                  src="/images/avatar-sakura.png"
                  alt="さくらちゃんのアバター"
                  fill
                  className="object-cover"
                  onError={() => {
                    // フォールバック処理は親要素のグラデーション背景で対応
                  }}
                />
              </div>
              <div>
                <p className="font-medium text-gray-900">さくらちゃん</p>
                <p className="text-sm text-gray-500">小学5年生・保護者同意</p>
              </div>
            </div>
          </div>

          {/* レビュー2 */}
          <div className="bg-white border border-gray-200 rounded-xl p-8 space-y-6">
            <p className="text-lg text-gray-900 leading-relaxed">
              「色について詳しく学べて、アートの授業でも活かせています。」
            </p>
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-gradient-to-br from-warm-400 to-warm-500 rounded-full overflow-hidden relative">
                <Image
                  src="/images/avatar-yuto.png"
                  alt="ゆうとくんのアバター"
                  fill
                  className="object-cover"
                  onError={() => {
                    // フォールバック処理は親要素のグラデーション背景で対応
                  }}
                />
              </div>
              <div>
                <p className="font-medium text-gray-900">ゆうとくん</p>
                <p className="text-sm text-gray-500">小学6年生・保護者同意</p>
              </div>
            </div>
          </div>

          {/* レビュー3 */}
          <div className="bg-white border border-gray-200 rounded-xl p-8 space-y-6">
            <p className="text-lg text-gray-900 leading-relaxed">
              「安全で子どもにも使いやすく、教育的価値も高いと感じます。」
            </p>
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-gradient-to-br from-cool-400 to-cool-500 rounded-full overflow-hidden relative">
                <Image
                  src="/images/avatar-parent.png"
                  alt="保護者の方のアバター"
                  fill
                  className="object-cover"
                  onError={() => {
                    // フォールバック処理は親要素のグラデーション背景で対応
                  }}
                />
              </div>
              <div>
                <p className="font-medium text-gray-900">保護者の方</p>
                <p className="text-sm text-gray-500">お子様: 小学5年生</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
