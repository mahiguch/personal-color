'use client';

import { Button } from '@/components/ui/button';

export function LaunchSection() {
  return (
    <section id="launch" className="py-20 bg-gray-50">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto">
          {/* Figmaベースのセクション見出し */}
          <div className="text-center space-y-6 mb-16">
            <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 leading-tight">
              近日公開予定
            </h2>
          </div>

          {/* 2ボタンレイアウト（Figmaデザインに基づく） */}
          <div className="flex flex-col sm:flex-row gap-6 justify-center mb-16">
            <Button 
              size="lg" 
              className="bg-gray-900 text-white hover:bg-gray-800 font-medium px-8 py-4 rounded-lg shadow-sm transition-all duration-200"
              disabled
            >
              App Storeからアプリ取得
            </Button>
            <Button 
              size="lg" 
              variant="outline"
              className="border-gray-300 text-gray-900 hover:bg-gray-50 font-medium px-8 py-4 rounded-lg transition-all duration-200"
              disabled
            >
              Google Playからアプリ取得
            </Button>
          </div>

          {/* 詳細情報セクション */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-left">
            <div className="space-y-2">
              <h3 className="text-xl font-medium text-gray-900">
                iOS版
              </h3>
              <p className="text-gray-600 leading-relaxed">
                App Storeでの配信を2025年春頃に予定しています。リリース後にダウンロード可能です。
              </p>
            </div>
            
            <div className="space-y-2">
              <h3 className="text-xl font-medium text-gray-900">
                Android版
              </h3>
              <p className="text-gray-600 leading-relaxed">
                Google Playでの配信を2025年夏頃に予定しています。リリース後にダウンロード可能です。
              </p>
            </div>
            
            <div className="space-y-2">
              <h3 className="text-xl font-medium text-gray-900">
                完全無料
              </h3>
              <p className="text-gray-600 leading-relaxed">
                基本機能は完全無料でご利用いただけます。広告表示もございません。
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
