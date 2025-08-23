'use client';

import { Download, Sparkles } from 'lucide-react';
import Image from 'next/image';
import { Button, Container } from '@/components/ui';
import { appFeatures } from '@/lib/features-data';

export function HeroSection() {
  const handleAppStoreClick = () => {
    // TODO: App Store リンクが利用可能になったら更新
    console.log('App Store へのリンクが実装されます');
  };

  return (
    <section className="bg-gradient-to-br from-primary-50 to-pink-50 py-12 sm:py-16 lg:py-24">
      <Container>
        <div className="grid lg:grid-cols-2 gap-8 sm:gap-12 items-center">
          {/* Main Content */}
          <div className="text-center lg:text-left">
            <div className="flex items-center justify-center lg:justify-start mb-6">
              <Sparkles className="text-orange-500 mr-2" size={32} />
              <span className="text-sm font-semibold text-orange-600 uppercase tracking-wide">
                AI パーソナルカラー診断
              </span>
            </div>

            <h1 className="text-3xl sm:text-4xl lg:text-5xl xl:text-6xl font-bold text-gray-900 mb-6 leading-tight">
              AIが教える
              <br />
              <span className="bg-gradient-to-r from-orange-500 to-pink-500 bg-clip-text text-transparent">
                あなたに似合う色
              </span>
              <br />
              を発見しよう！
            </h1>

            <p className="text-xl text-gray-600 mb-8 leading-relaxed">
              カメラで写真を撮るだけで、AI
              があなたのパーソナルカラー（イエベ・ブルベ）を診断。
              <br />
              {appFeatures.targetAge}が安心して楽しめる教育アプリです。
            </p>

            {/* Features highlight */}
            <div className="flex flex-wrap gap-4 justify-center lg:justify-start mb-8">
              <div className="flex items-center text-gray-700">
                <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                {appFeatures.price}
              </div>
              <div className="flex items-center text-gray-700">
                <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                {appFeatures.privacy}
              </div>
              <div className="flex items-center text-gray-700">
                <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                {appFeatures.safety}
              </div>
            </div>

            {/* CTA Button */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <Button
                size="lg"
                className="text-lg px-8 py-4"
                onClick={handleAppStoreClick}
                icon={<Download size={24} />}
              >
                App Store からダウンロード
              </Button>
              <Button
                variant="outline"
                size="lg"
                className="text-lg px-8 py-4"
                onClick={() => {
                  document.getElementById('features')?.scrollIntoView({
                    behavior: 'smooth',
                  });
                }}
              >
                機能を詳しく見る
              </Button>
            </div>

            <p className="text-sm text-gray-500 mt-4">
              ※ 現在 iOS 版を App Store 審査中です
            </p>
          </div>

          {/* Hero Image/Illustration */}
          <div className="relative mt-8 lg:mt-0">
            <div className="relative mx-auto w-72 h-72 sm:w-80 sm:h-80 lg:w-96 lg:h-96">
              <Image
                src="/images/hero-mockup.svg"
                alt="パーソナルカラー診断アプリのモックアップ"
                fill
                className="object-contain animate-fade-up"
                priority
                sizes="(max-width: 640px) 288px, (max-width: 1024px) 320px, 384px"
              />
            </div>
          </div>
        </div>
      </Container>
    </section>
  );
}
