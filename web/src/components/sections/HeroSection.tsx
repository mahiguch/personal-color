'use client';

import { Card } from '@/components/ui/card';
import { MESSAGES } from '@/lib/constants';

export function HeroSection() {
  return (
    <section className="relative min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 via-warm-50 to-cool-50 overflow-hidden pt-16">
      {/* 装飾的背景要素 */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-20 left-20 w-32 h-32 bg-primary-500 rounded-full blur-3xl"></div>
        <div className="absolute bottom-20 right-20 w-40 h-40 bg-cool-500 rounded-full blur-3xl"></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-60 h-60 bg-warm-400 rounded-full blur-3xl opacity-50"></div>
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* 左側：テキストコンテンツ */}
          <div className="text-center lg:text-left space-y-8">
            <div className="space-y-6">
              <h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold text-gray-900 leading-[1.1]">
                AIが教える、あなたに似合う色を発見しよう！
              </h1>
              <p className="text-xl sm:text-2xl text-gray-600 max-w-3xl mx-auto lg:mx-0 leading-relaxed">
                {MESSAGES.hero.subtitle}
              </p>
            </div>

            {/* 信頼性アピール */}
            <div className="flex flex-wrap gap-4 justify-center lg:justify-start text-sm text-gray-600">
              <div className="flex items-center space-x-2">
                <span className="w-2 h-2 bg-accent-success rounded-full"></span>
                <span>画像は自動削除</span>
              </div>
              <div className="flex items-center space-x-2">
                <span className="w-2 h-2 bg-accent-info rounded-full"></span>
                <span>完全無料</span>
              </div>
              <div className="flex items-center space-x-2">
                <span className="w-2 h-2 bg-accent-warning rounded-full"></span>
                <span>App Store配信中</span>
              </div>
            </div>
          </div>

          {/* 右側：アプリモックアップ */}
          <div className="relative">
            <Card className="bg-white/90 backdrop-blur-sm rounded-3xl p-8 shadow-2xl border border-white/20">
              <div className="text-center space-y-6">
                <div className="relative mx-auto w-48 h-96 bg-gray-100 rounded-3xl overflow-hidden shadow-xl">
                  {/* スクリーンショットプレビュー */}
                  <div className="absolute inset-2 bg-gradient-to-b from-primary-100 to-cool-100 rounded-2xl flex items-center justify-center">
                    <div className="text-center space-y-4">
                      <div className="w-16 h-16 bg-gradient-to-r from-primary-500 to-cool-500 rounded-full mx-auto flex items-center justify-center">
                        <span className="text-2xl">🎨</span>
                      </div>
                      <div className="space-y-2">
                        <div className="text-sm font-medium text-gray-700">パーソナルカラー診断</div>
                        <div className="text-xs text-gray-500">カメラで撮影するだけ</div>
                      </div>
                      <div className="space-y-2">
                        <div className="h-2 bg-gradient-to-r from-warm-400 to-warm-600 rounded-full mx-auto w-20"></div>
                        <div className="h-2 bg-gradient-to-r from-cool-400 to-cool-600 rounded-full mx-auto w-16"></div>
                      </div>
                    </div>
                  </div>
                  
                  {/* スマートフォンのノッチ */}
                  <div className="absolute top-0 left-1/2 transform -translate-x-1/2 w-20 h-6 bg-gray-900 rounded-b-xl"></div>
                </div>
                
                <div className="text-center space-y-2">
                  <p className="text-sm font-medium text-gray-700">
                    数秒で診断完了
                  </p>
                  <p className="text-xs text-gray-500">
                    安全・簡単・楽しい
                  </p>
                </div>
              </div>
            </Card>

            {/* 浮遊する装飾要素 */}
            <div className="absolute -top-4 -right-4 w-8 h-8 bg-warm-400 rounded-full animate-bounce"></div>
            <div className="absolute -bottom-4 -left-4 w-6 h-6 bg-cool-400 rounded-full animate-bounce" style={{ animationDelay: '0.5s' }}></div>
          </div>
        </div>
      </div>

    </section>
  );
}
