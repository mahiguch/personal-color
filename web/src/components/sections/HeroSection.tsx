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
    <section className="bg-white py-16 sm:py-20 lg:py-32">
      <Container>
        <div className="max-w-4xl mx-auto text-center">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary-50 rounded-full mb-8">
            <Sparkles className="text-primary-400" size={20} />
            <span className="text-sm font-medium text-primary-600 tracking-tight">
              AI パーソナルカラー診断
            </span>
          </div>

          <h1 className="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-bold text-gray-900 mb-8 leading-tight tracking-tighter">
            AIが教える
            <br />
            <span className="text-primary-400">あなたに似合う色</span>
            <br />
            を発見しよう
          </h1>

          <p className="text-lg sm:text-xl text-gray-500 mb-12 max-w-3xl mx-auto leading-relaxed tracking-tight">
            カメラで写真を撮るだけで、AIがあなたのパーソナルカラー（イエベ・ブルベ）を診断。
            {appFeatures.targetAge}が安心して楽しめる教育アプリです。
          </p>

          {/* Features highlight */}
          <div className="flex flex-wrap gap-6 justify-center mb-12">
            <div className="flex items-center gap-2 text-gray-600">
              <span className="w-1.5 h-1.5 bg-primary-400 rounded-full"></span>
              <span className="text-sm tracking-tight">
                {appFeatures.price}
              </span>
            </div>
            <div className="flex items-center gap-2 text-gray-600">
              <span className="w-1.5 h-1.5 bg-primary-400 rounded-full"></span>
              <span className="text-sm tracking-tight">
                {appFeatures.privacy}
              </span>
            </div>
            <div className="flex items-center gap-2 text-gray-600">
              <span className="w-1.5 h-1.5 bg-primary-400 rounded-full"></span>
              <span className="text-sm tracking-tight">
                {appFeatures.safety}
              </span>
            </div>
          </div>

          {/* CTA Button */}
          <div className="flex flex-col sm:flex-row gap-3 justify-center items-center mb-8">
            <Button
              size="lg"
              className="px-8 py-4 rounded-full"
              onClick={handleAppStoreClick}
              icon={<Download size={20} />}
            >
              App Store からダウンロード
            </Button>
            <Button
              variant="ghost"
              size="lg"
              className="px-8 py-4 rounded-full"
              onClick={() => {
                document.getElementById('features')?.scrollIntoView({
                  behavior: 'smooth',
                });
              }}
            >
              機能を詳しく見る
            </Button>
          </div>

          <p className="text-sm text-gray-400 tracking-tight">
            ※ 現在 iOS 版を App Store 審査中です
          </p>

          {/* Hero Image/Illustration - Minimalist */}
          <div className="relative mt-16 sm:mt-20">
            <div className="relative mx-auto w-64 h-64 sm:w-80 sm:h-80 opacity-90">
              <Image
                src="/images/hero-mockup.svg"
                alt="パーソナルカラー診断アプリのモックアップ"
                fill
                className="object-contain"
                priority
                sizes="(max-width: 640px) 256px, 320px"
              />
            </div>
          </div>
        </div>
      </Container>
    </section>
  );
}
