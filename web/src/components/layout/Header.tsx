'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Button } from '@/components/ui/button';
import { Menu, X } from 'lucide-react';
import { APP_STORE_URLS } from '@/lib/constants';

interface HeaderProps {
  transparent?: boolean;
}

export function Header({ transparent = false }: HeaderProps) {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  return (
    <header className={`fixed top-0 w-full z-50 transition-all duration-200 ${
      transparent 
        ? 'bg-transparent' 
        : 'bg-white/90 backdrop-blur-sm border-b border-gray-100'
    }`}>
      <nav className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* ロゴ */}
          <Link href="/" className="flex items-center space-x-2">
            <Image
              src="/app_icon.svg"
              alt="パーソナルカラー診断アプリ"
              width={32}
              height={32}
              className="object-contain"
            />
            <span className="font-semibold text-lg text-gray-900 hidden sm:block">
              パーソナルカラー診断
            </span>
          </Link>

          {/* デスクトップナビゲーション */}
          <div className="hidden md:flex items-center space-x-8">
            <nav className="flex items-center space-x-6">
              <Link href="/#features" className="text-gray-700 hover:text-primary-600 transition-colors font-medium">
                アプリについて
              </Link>
              <Link href="/support" className="text-gray-700 hover:text-primary-600 transition-colors font-medium">
                サポート
              </Link>
              <Link href="/privacy" className="text-gray-700 hover:text-primary-600 transition-colors font-medium">
                プライバシー
              </Link>
            </nav>

            {/* CTAボタン */}
            <a href={APP_STORE_URLS.ios} target="_blank" rel="noopener noreferrer" className="inline-block">
              <Button 
                className="bg-gray-900 hover:bg-gray-800 text-white px-6 py-2 rounded-lg font-medium shadow-sm hover:shadow-md transition-all duration-200"
              >
                App Storeでダウンロード
              </Button>
            </a>
          </div>

          {/* モバイルメニューボタン */}
          <button
            onClick={toggleMobileMenu}
            className="md:hidden p-2 rounded-md text-gray-700 hover:text-primary-600 hover:bg-gray-100 transition-colors"
          >
            {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>

        {/* モバイルメニュー */}
        {isMobileMenuOpen && (
          <div className="md:hidden absolute top-16 left-0 right-0 bg-white border-b border-gray-100 shadow-lg">
            <div className="px-4 py-2 space-y-2">
              <Link
                href="/#features"
                className="block px-3 py-2 text-gray-700 hover:text-primary-600 hover:bg-gray-50 rounded-md transition-colors"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                アプリについて
              </Link>
              <Link
                href="/support"
                className="block px-3 py-2 text-gray-700 hover:text-primary-600 hover:bg-gray-50 rounded-md transition-colors"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                サポート
              </Link>
              <Link
                href="/privacy"
                className="block px-3 py-2 text-gray-700 hover:text-primary-600 hover:bg-gray-50 rounded-md transition-colors"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                プライバシー
              </Link>
              <div className="pt-2">
                <a href={APP_STORE_URLS.ios} target="_blank" rel="noopener noreferrer" className="block">
                  <Button 
                    className="w-full bg-gray-900 hover:bg-gray-800 text-white rounded-lg font-medium"
                  >
                    App Storeでダウンロード
                  </Button>
                </a>
              </div>
            </div>
          </div>
        )}
      </nav>
    </header>
  );
}
